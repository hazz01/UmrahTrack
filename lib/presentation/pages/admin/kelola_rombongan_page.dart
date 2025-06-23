import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../data/models/rombongan_model.dart';
import '../../../data/services/rombongan_service.dart';
import '../../../data/services/session_manager.dart';
import '../../widgets/bottom_navbar_admin.dart';
import '../../widgets/travel_verification_guard.dart';

class KelolaRombonganPage extends StatefulWidget {
  const KelolaRombonganPage({super.key});

  @override
  State<KelolaRombonganPage> createState() => _KelolaRombonganPageState();
}

class _KelolaRombonganPageState extends State<KelolaRombonganPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  
  // Form controllers
  final TextEditingController _namaRombonganController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _kapasitasController = TextEditingController();
  final TextEditingController _guideController = TextEditingController();
  final TextEditingController _kontakController = TextEditingController();
  
  String? _currentTravelId;
  String _searchQuery = '';
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isAddFormOpen = false;
  String? _editingRombonganId;
  
  DateTime _selectedTanggalBerangkat = DateTime.now().add(const Duration(days: 30));
  DateTime? _selectedTanggalKembali;
  String _selectedStatus = 'active';
  
  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _namaRombonganController.dispose();
    _deskripsiController.dispose();
    _kapasitasController.dispose();
    _guideController.dispose();
    _kontakController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Get travel ID
      final travelId = await SessionManager.getCurrentTravelId();
      if (travelId == null) {
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            if (userData['userType'] != 'travel') {
              setState(() {
                _hasError = true;
                _errorMessage = 'Access denied. Only travel users can access this page.';
              });
              return;
            }
            _currentTravelId = userData['travelId'];
          }
        }
      } else {
        _currentTravelId = travelId;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error initializing data: $e';
      });
    }
  }

  void _clearForm() {
    _namaRombonganController.clear();
    _deskripsiController.clear();
    _kapasitasController.clear();
    _guideController.clear();
    _kontakController.clear();
    _selectedTanggalBerangkat = DateTime.now().add(const Duration(days: 30));
    _selectedTanggalKembali = null;
    _selectedStatus = 'active';
    _editingRombonganId = null;
  }

  void _toggleAddForm() {
    setState(() {
      _isAddFormOpen = !_isAddFormOpen;
      if (!_isAddFormOpen) {
        _clearForm();
      }
    });
  }

  Future<void> _createRombongan() async {
    final namaRombongan = _namaRombonganController.text.trim();
    final deskripsi = _deskripsiController.text.trim();
    final kapasitas = int.tryParse(_kapasitasController.text.trim()) ?? 0;
    final guide = _guideController.text.trim();
    final kontak = _kontakController.text.trim();

    // Validate
    final validationError = RombonganService.validateRombonganData(
      namaRombongan: namaRombongan,
      travelId: _currentTravelId!,
      kapasitas: kapasitas,
      tanggalBerangkat: _selectedTanggalBerangkat,
    );

    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    try {
      final rombongan = Rombongan(
        id: '',
        namaRombongan: namaRombongan,
        deskripsi: deskripsi,
        travelId: _currentTravelId!,
        kapasitas: kapasitas,
        tanggalBerangkat: _selectedTanggalBerangkat,
        tanggalKembali: _selectedTanggalKembali,
        guide: guide.isEmpty ? null : guide,
        kontak: kontak.isEmpty ? null : kontak,
        status: _selectedStatus,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await RombonganService.createRombongan(rombongan);
      
      _clearForm();
      _toggleAddForm();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rombongan berhasil ditambahkan')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error menambahkan rombongan: $e')),
      );
    }
  }

  Future<void> _updateRombongan() async {
    if (_editingRombonganId == null) return;

    final namaRombongan = _namaRombonganController.text.trim();
    final deskripsi = _deskripsiController.text.trim();
    final kapasitas = int.tryParse(_kapasitasController.text.trim()) ?? 0;
    final guide = _guideController.text.trim();
    final kontak = _kontakController.text.trim();

    // Validate
    final validationError = RombonganService.validateRombonganData(
      namaRombongan: namaRombongan,
      travelId: _currentTravelId!,
      kapasitas: kapasitas,
      tanggalBerangkat: _selectedTanggalBerangkat,
    );

    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    try {
      final updates = {
        'namaRombongan': namaRombongan,
        'deskripsi': deskripsi,
        'kapasitas': kapasitas,
        'tanggalBerangkat': Timestamp.fromDate(_selectedTanggalBerangkat),
        'tanggalKembali': _selectedTanggalKembali != null 
            ? Timestamp.fromDate(_selectedTanggalKembali!)
            : null,
        'guide': guide.isEmpty ? null : guide,
        'kontak': kontak.isEmpty ? null : kontak,
        'status': _selectedStatus,
      };

      await RombonganService.updateRombongan(_editingRombonganId!, updates);
      
      _clearForm();
      _toggleAddForm();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rombongan berhasil diupdate')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengupdate rombongan: $e')),
      );
    }
  }

  Future<void> _deleteRombongan(String rombonganId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus rombongan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await RombonganService.deleteRombongan(rombonganId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rombongan berhasil dihapus')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error menghapus rombongan: $e')),
        );
      }
    }
  }

  void _editRombongan(Rombongan rombongan) {
    _editingRombonganId = rombongan.id;
    _namaRombonganController.text = rombongan.namaRombongan;
    _deskripsiController.text = rombongan.deskripsi;
    _kapasitasController.text = rombongan.kapasitas.toString();
    _guideController.text = rombongan.guide ?? '';
    _kontakController.text = rombongan.kontak ?? '';
    _selectedTanggalBerangkat = rombongan.tanggalBerangkat;
    _selectedTanggalKembali = rombongan.tanggalKembali;
    _selectedStatus = rombongan.status;
    _toggleAddForm();
  }

  Future<void> _selectDate(bool isBerangkat) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isBerangkat 
          ? _selectedTanggalBerangkat 
          : (_selectedTanggalKembali ?? _selectedTanggalBerangkat.add(const Duration(days: 14))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isBerangkat) {
          _selectedTanggalBerangkat = picked;
          // Reset tanggal kembali if it's before tanggal berangkat
          if (_selectedTanggalKembali != null && _selectedTanggalKembali!.isBefore(picked)) {
            _selectedTanggalKembali = null;
          }
        } else {
          _selectedTanggalKembali = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TravelVerificationGuard(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text(
            'Kelola Rombongan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF1658B3),
          elevation: 0,
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1658B3), Color(0xFF42A5F5)],
              ),
            ),
          ),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: _toggleAddForm,
              tooltip: 'Tambah Rombongan',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasError
                ? Center(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : Column(
                    children: [
                      // Search Bar
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Cari rombongan...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),                      // Add/Edit Form - wrap in Flexible to prevent overflow
                      if (_isAddFormOpen) 
                        Flexible(
                          child: _buildAddEditForm(),
                        ),

                      // Rombongan List
                      Expanded(
                        child: _currentTravelId == null
                            ? const Center(child: CircularProgressIndicator())
                            : StreamBuilder<List<Rombongan>>(
                                stream: RombonganService.getRombonganByTravelId(_currentTravelId!),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  
                                  if (snapshot.hasError) {
                                    return Center(child: Text('Error: ${snapshot.error}'));
                                  }
                                  
                                  final allRombongan = snapshot.data ?? [];
                                  final filteredRombongan = allRombongan.where((rombongan) {
                                    return _searchQuery.isEmpty ||
                                        rombongan.namaRombongan.toLowerCase().contains(_searchQuery) ||
                                        rombongan.deskripsi.toLowerCase().contains(_searchQuery) ||
                                        (rombongan.guide?.toLowerCase().contains(_searchQuery) ?? false);
                                  }).toList();
                                  
                                  if (filteredRombongan.isEmpty) {
                                    return const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.group_off,
                                            size: 64,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Belum ada rombongan',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            'Tambah rombongan pertama Anda',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  
                                  return ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: filteredRombongan.length,
                                    itemBuilder: (context, index) {
                                      final rombongan = filteredRombongan[index];
                                      return _buildRombonganCard(rombongan);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
        bottomNavigationBar: BottomNavbarAdmin(
          currentIndex: 2, // Index untuk rombongan
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushNamed(context, '/admin/home');
                break;
              case 1:
                Navigator.pushNamed(context, '/kelola_jamaah');
                break;
              case 2:
                // Already on rombongan page
                break;
              case 3:
                Navigator.pushNamed(context, '/admin/lokasi');
                break;
              case 4:
                Navigator.pushNamed(context, '/admin/laporan');
                break;
            }
          },
        ),    ),
    );
  }
  
    Widget _buildAddEditForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _editingRombonganId == null ? 'Tambah Rombongan' : 'Edit Rombongan',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _toggleAddForm,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Nama Rombongan
            TextField(
              controller: _namaRombonganController,
              decoration: const InputDecoration(
                labelText: 'Nama Rombongan *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            // Deskripsi
            TextField(
              controller: _deskripsiController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            // Kapasitas dan Status
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _kapasitasController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Kapasitas *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Aktif')),
                      DropdownMenuItem(value: 'inactive', child: Text('Tidak Aktif')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Tanggal Berangkat dan Kembali
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Tanggal Berangkat *'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedTanggalBerangkat)),
                    leading: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(true),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ListTile(
                    title: const Text('Tanggal Kembali'),
                    subtitle: Text(_selectedTanggalKembali != null 
                        ? DateFormat('dd/MM/yyyy').format(_selectedTanggalKembali!)
                        : 'Belum ditentukan'),
                    leading: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(false),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Guide dan Kontak
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _guideController,
                    decoration: const InputDecoration(
                      labelText: 'Guide/Pembimbing',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _kontakController,
                    decoration: const InputDecoration(
                      labelText: 'Kontak',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _toggleAddForm,
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _editingRombonganId == null ? _createRombongan : _updateRombongan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1658B3),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_editingRombonganId == null ? 'Tambah' : 'Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRombonganCard(Rombongan rombongan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to rombongan detail page
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      rombongan.namaRombongan,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editRombongan(rombongan),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteRombongan(rombongan.id),
                        tooltip: 'Hapus',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              if (rombongan.deskripsi.isNotEmpty)
                Text(
                  rombongan.deskripsi,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // Status and capacity
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: rombongan.status == 'active' 
                          ? Colors.green.withOpacity(0.1)
                          : rombongan.status == 'full'
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      rombongan.statusText,
                      style: TextStyle(
                        color: rombongan.status == 'active' 
                            ? Colors.green
                            : rombongan.status == 'full'
                                ? Colors.orange
                                : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Jamaah: ${rombongan.jumlahJamaah}/${rombongan.kapasitas}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Dates
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Berangkat: ${DateFormat('dd/MM/yyyy').format(rombongan.tanggalBerangkat)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              
              if (rombongan.tanggalKembali != null)
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Kembali: ${DateFormat('dd/MM/yyyy').format(rombongan.tanggalKembali!)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              
              if (rombongan.guide != null)
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Guide: ${rombongan.guide}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
