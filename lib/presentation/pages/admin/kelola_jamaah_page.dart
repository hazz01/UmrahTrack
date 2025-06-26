import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:umrahtrack/data/services/session_manager.dart';
import 'package:umrahtrack/data/models/rombongan_model.dart';
import 'package:umrahtrack/data/services/rombongan_service.dart';
import '../../widgets/bottom_navbar_admin.dart';
import '../../widgets/travel_verification_guard.dart';

// UserData model class to match Firestore schema
class UserData {
  final String uid;
  final String name;
  final String email;
  final String userType;
  final String? travelId;
  final String? rombonganId;
  final String? gender;
  final DateTime? createdAt;

  UserData({
    required this.uid,
    required this.name,
    required this.email,
    required this.userType,
    this.travelId,
    this.rombonganId,
    this.gender,
    this.createdAt,
  });

  factory UserData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserData(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      userType: data['userType'] ?? '',
      travelId: data['travelId'],
      rombonganId: data['rombonganId'],
      gender: data['gender'],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
    );
  }
}

class KelolaWargaPage extends StatefulWidget {
  const KelolaWargaPage({super.key});

  @override
  State<KelolaWargaPage> createState() => _KelolaWargaPageState();
}

class _KelolaWargaPageState extends State<KelolaWargaPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
    // Form controllers for adding/editing users
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String _searchQuery = '';
  bool _isSelectMode = false;
  List<UserData> _selectedUsers = [];
    // Filter values - remove gender filter
  String _filterRombongan = '';
  
  // Edit mode
  String? _editingUserId;
  
  // Rombongan
  String? _selectedRombonganId;
  List<Rombongan> _availableRombongan = [];
    // Current travel user's data
  String? _currentTravelId;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Check session validity first
      final isSessionValid = await SessionManager.isSessionValid();
      if (!isSessionValid) {
        _redirectToLogin();
        return;
      }

      // Try to get travel ID from session manager
      final travelId = await SessionManager.getCurrentTravelId();
      if (travelId == null) {
        // If still no travel ID, check Firebase directly
        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          _redirectToLogin();
          return;
        }

        final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (!userDoc.exists) {
          _redirectToLogin();
          return;
        }

        final userData = userDoc.data() as Map<String, dynamic>;
        final userType = userData['userType'];
        if (userType != 'travel') {
          setState(() {
            _hasError = true;
            _errorMessage = 'Access denied. Only travel users can access this page.';
          });
          return;
        }        setState(() {
          _currentTravelId = userData['travelId'];
        });      } else {
        setState(() {
          _currentTravelId = travelId;
        });
      }      // Refresh session when page loads
      await SessionManager.refreshSession();

      // Load rombongan data
      await _loadRombonganData();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing data: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load user data. Please try again.';
      });
    }
  }
  void _redirectToLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _loadRombonganData() async {
    if (_currentTravelId != null) {
      try {
        final rombonganSnapshot = await FirebaseFirestore.instance
            .collection('rombongan')
            .where('travelId', isEqualTo: _currentTravelId)
            .where('status', isEqualTo: 'active')
            .get();
        
        setState(() {
          _availableRombongan = rombonganSnapshot.docs
              .map((doc) => Rombongan.fromFirestore(doc))
              .toList();
        });
      } catch (e) {
        print('Error loading rombongan: $e');
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      // Show confirmation dialog
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.logout_rounded, color: Color(0xFF1658B3)),
                SizedBox(width: 8),
                Text('Konfirmasi Logout'),
              ],
            ),
            content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Color(0xFF6C7B8A)),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1658B3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );

      if (shouldLogout == true) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Color(0xFF1658B3)),
          ),
        );

        // Logout using session manager
        await SessionManager.logout();
        
        // Navigate to login page
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      }
    } catch (e) {
      // Close loading dialog if open
      if (context.mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Stream<QuerySnapshot> _getUsersStream() {
    if (_currentTravelId == null) {
      // Return empty stream if current travel ID is not loaded yet
      return const Stream.empty();
    }
    
    Query query = _firestore.collection('users')
        .where('userType', isEqualTo: 'jamaah')
        .where('travelId', isEqualTo: _currentTravelId);
    
    return query.snapshots();
  }  List<UserData> _filterUsers(List<UserData> users) {
    return users.where((user) {
      // Search filter
      bool matchesSearch = _searchQuery.isEmpty ||
          user.name.toLowerCase().contains(_searchQuery) ||
          user.email.toLowerCase().contains(_searchQuery);
      
      // Remove gender filter - only keep rombongan filter
      
      // Rombongan filter
      bool matchesRombongan = _filterRombongan.isEmpty ||
          (_filterRombongan == 'no_rombongan' && (user.rombonganId == null || user.rombonganId!.isEmpty)) ||
          (_filterRombongan != 'no_rombongan' && user.rombonganId == _filterRombongan);
      
      return matchesSearch && matchesRombongan;
    }).toList();
  }  void _clearFilters() {
    setState(() {
      _filterRombongan = '';
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      if (!_isSelectMode) {
        _selectedUsers.clear();
      }
    });
  }

  void _toggleUserSelection(UserData user) {
    setState(() {
      if (_selectedUsers.any((u) => u.uid == user.uid)) {
        _selectedUsers.removeWhere((u) => u.uid == user.uid);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  void _selectAll(List<UserData> allUsers) {
    setState(() {
      if (_selectedUsers.length == allUsers.length) {
        _selectedUsers.clear();
      } else {
        _selectedUsers = List.from(allUsers);
      }
    });
  }

  Future<void> _deleteSelectedUsers() async {
    try {
      for (UserData user in _selectedUsers) {
        await _firestore.collection('users').doc(user.uid).delete();
      }
      
      setState(() {
        _selectedUsers.clear();
        _isSelectMode = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jamaah berhasil dihapus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error menghapus jamaah: $e')),
      );
    }
  }

  Future<void> _deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jamaah berhasil dihapus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error menghapus jamaah: $e')),
      );
    }
  }

  Future<void> _createUser() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _currentTravelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua field yang diperlukan')),
      );
      return;
    }

    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.isNotEmpty ? _passwordController.text : '123456',
      );

      // Update display name
      await userCredential.user!.updateDisplayName(_nameController.text.trim());      // Create user document in Firestore - automatically assign travel ID from current travel user
      final userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'userType': 'jamaah',
        'travelId': _currentTravelId, // Automatically assign current travel ID
        'createdAt': FieldValue.serverTimestamp(),
        'uid': userCredential.user!.uid,
      };

      // Add rombongan if selected
      if (_selectedRombonganId != null && _selectedRombonganId!.isNotEmpty) {
        userData['rombonganId'] = _selectedRombonganId;
      }

      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);

      // Update rombongan jamaah count if assigned
      if (_selectedRombonganId != null && _selectedRombonganId!.isNotEmpty) {
        await RombonganService.assignJamaahToRombongan(userCredential.user!.uid, _selectedRombonganId!);
      }

      _clearForm();
      _toggleAddDataPopup();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jamaah berhasil ditambahkan')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error menambahkan jamaah: $e')),
      );
    }
  }

  Future<void> _updateUser() async {
    if (_editingUserId == null || _nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua field yang diperlukan')),
      );
      return;
    }    try {
      // Get current user data to check rombongan changes
      final currentUserDoc = await _firestore.collection('users').doc(_editingUserId).get();
      final currentUserData = currentUserDoc.data() as Map<String, dynamic>;
      final currentRombonganId = currentUserData['rombonganId'] as String?;

      final userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'userType': 'jamaah',
        'travelId': _currentTravelId, // Keep same travel ID
      };      // Handle rombongan changes
      if (_selectedRombonganId != currentRombonganId) {
        // Remove from old rombongan if exists
        if (currentRombonganId != null && currentRombonganId.isNotEmpty) {
          await RombonganService.removeJamaahFromRombongan(_editingUserId!, currentRombonganId);
        }

        // Add to new rombongan if selected
        if (_selectedRombonganId != null && _selectedRombonganId!.isNotEmpty) {
          userData['rombonganId'] = _selectedRombonganId;
          await RombonganService.assignJamaahToRombongan(_editingUserId!, _selectedRombonganId!);
        }
      } else if (_selectedRombonganId != null && _selectedRombonganId!.isNotEmpty) {
        userData['rombonganId'] = _selectedRombonganId;
      }

      await _firestore.collection('users').doc(_editingUserId).update(userData);

      _clearForm();
      _toggleAddDataPopup();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data jamaah berhasil diupdate')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengupdate jamaah: $e')),
      );
    }
  }
  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _selectedRombonganId = null;
    _editingUserId = null;
  }

  void _startEdit(UserData user) {
    _editingUserId = user.uid;
    _nameController.text = user.name;
    _emailController.text = user.email;
    _selectedRombonganId = user.rombonganId;
    _toggleAddDataPopup();
  }

  bool _isFilterOpen = false;
  bool _isAddDataOpen = false;
  bool _isUploadCSVOpen = false;

  void _toggleFilterPopup() {
    setState(() {
      _isFilterOpen = !_isFilterOpen;
    });
  }

  void _toggleAddDataPopup() {
    setState(() {
      _isAddDataOpen = !_isAddDataOpen;
    });
  }

  void _toggleUploadCSVPopup() {
    setState(() {
      _isUploadCSVOpen = !_isUploadCSVOpen;
    });
  }  @override
  Widget build(BuildContext context) {
    return TravelVerificationGuard(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        appBar: AppBar(
          automaticallyImplyLeading: false, // Remove back button
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kelola Jamaah',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              if (_currentTravelId != null)
                Text(
                  'Travel $_currentTravelId',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          backgroundColor: const Color(0xFF1658B3),
          foregroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1658B3), Color(0xFF42A5F5)],
              ),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: _handleLogout,
                tooltip: 'Logout',
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 20),
                _buildSearchBar(),
                const SizedBox(height: 18),
                _buildFilterChips(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _hasError
                          ? Center(
                              child: Text(
                                _errorMessage,
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                          : StreamBuilder<QuerySnapshot>(
                              stream: _getUsersStream(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                
                                if (snapshot.hasError) {
                                  return Center(child: Text('Error: ${snapshot.error}'));
                                }
                                
                                if (_currentTravelId == null) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                
                                final userDocs = snapshot.data?.docs ?? [];
                                final allUsers = userDocs
                                    .map((doc) => UserData.fromFirestore(doc))
                                    .toList();
                                
                                final filteredUsers = _filterUsers(allUsers);
                                
                                if (filteredUsers.isEmpty) {
                                  return const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                                        SizedBox(height: 16),
                                        Text(
                                          'Tidak ada jamaah ditemukan',
                                          style: TextStyle(fontSize: 16, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                
                                return _isSelectMode
                                    ? _buildSelectModeList(filteredUsers)
                                    : _buildUserList(filteredUsers);
                              },
                            ),
                ),
              ],
            ),
            if (_isFilterOpen) _buildFilterPopup(),
            if (_isAddDataOpen) _buildAddDataPopup(),
            if (_isUploadCSVOpen) _buildUploadCSVPopup(),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isSelectMode)
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _deleteSelectedUsers,
                        child: Text('Hapus ${_selectedUsers.length} Jamaah'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _toggleSelectMode,
                      child: const Text('Batal'),
                    ),
                  ],
                ),
              ),
            _buildBottomActionBar(),            BottomNavbarAdmin(
              currentIndex: 0,
              onTap: (index) {
                switch (index) {
                  case 0:
                    // Already on Jamaah page - do nothing
                    break;
                  case 1:
                    Navigator.pushNamedAndRemoveUntil(
                      context, 
                      '/admin/lokasi',
                      (route) => false,
                    );
                    break;
                  case 2:
                    Navigator.pushNamedAndRemoveUntil(
                      context, 
                      '/admin/rombongan',
                      (route) => false,
                    );
                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Cari jamaah berdasarkan nama atau email...',
            hintStyle: const TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 14,
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.search_rounded,
                color: Color(0xFF1658B3),
                size: 20,
              ),
            ),
            suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: const Icon(
                      Icons.clear_rounded,
                      color: Color(0xFF6C7B8A),
                    ),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }
  Widget _buildFilterChips() {    List<Widget> activeFilters = [];
    
    // Remove gender filter - only keep rombongan filter
    if (_filterRombongan.isNotEmpty) {
      String rombonganName = 'Unknown';
      if (_filterRombongan == 'no_rombongan') {
        rombonganName = 'Tanpa Rombongan';
      } else {
        final rombongan = _availableRombongan.firstWhere(
          (r) => r.id == _filterRombongan, 
          orElse: () => Rombongan(
            id: '',
            namaRombongan: 'Unknown',
            deskripsi: '',
            travelId: '',
            kapasitas: 0,
            tanggalBerangkat: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )
        );
        rombonganName = rombongan.namaRombongan;
      }
      activeFilters.add(_buildFilterChip('Rombongan: $rombonganName', () {
        setState(() {
          _filterRombongan = '';
        });
      }));
    }
    
    if (_searchQuery.isNotEmpty) {
      activeFilters.add(_buildFilterChip('Pencarian: $_searchQuery', () {
        _searchController.clear();
      }));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), // Add more bottom padding for spacing
      child: Row(
        children: [
          Container(
            height: 40,
            width: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF1658B3),
              borderRadius: BorderRadius.circular(84),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.filter_list,
                color: Colors.white,
                size: 24,
              ),
              onPressed: _toggleFilterPopup,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...activeFilters.map((filter) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: filter,
                  )),
                  if (activeFilters.isNotEmpty)
                    GestureDetector(
                      onTap: _clearFilters,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(84),
                        ),
                        child: const Text(
                          'Bersihkan Filter',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE8F8),
        borderRadius: BorderRadius.circular(84),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 16, color: Color(0xA61658B3)),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
                color: Color(0xFF1658B3),
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<UserData> users) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildSelectModeList(List<UserData> allUsers) {
    return ListView.builder(
      itemCount: allUsers.length,
      itemBuilder: (context, index) {
        final user = allUsers[index];
        return _buildSelectableUserCard(user);
      },
    );
  }

  Widget _buildUserCard(UserData user) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.15),
      color: Colors.white,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.black),
                ),
                if (user.userType == 'travel')
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1F5FE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Travel ${user.travelId}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Color(0xFF01579B)),
                    ),
                  ),
              ],
            ),
            Text(
              user.email,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF636363),
              ),
            ),            const SizedBox(height: 8),            
            // Only show rombongan chip
            if (user.rombonganId != null)
              _buildRombonganChip(user.rombonganId!)
            else
              _buildNoRombonganChip(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide.none,
                      backgroundColor: const Color(0x261658B3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(68),
                      ),
                    ),
                    onPressed: () {
                      _startEdit(user);
                    },
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                          color: Color(0xFF1658B3),
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide.none,
                      backgroundColor: const Color(0xFFFF4041),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(68),
                      ),
                    ),
                    onPressed: () {
                      _deleteUser(user.uid);
                    },
                    child: const Text(
                      'Hapus',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectableUserCard(UserData user) {
    final isSelected = _selectedUsers.any((u) => u.uid == user.uid);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleUserSelection(user),
              activeColor: Colors.blue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(user.email),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: () {
                            _startEdit(user);
                          },
                          child: const Text('Edit',
                              style: TextStyle(color: Colors.black)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: () {
                            _deleteUser(user.uid);
                          },
                          child: const Text('Hapus'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeChip(String userType) {
    Color chipColor;
    String label;

    switch (userType) {
      case 'admin':
        chipColor = Colors.green;
        label = 'Admin';
        break;
      case 'travel':
        chipColor = Colors.blue;
        label = 'Travel';
        break;
      case 'jamaah':
        chipColor = Colors.orange;
        label = 'Jamaah';
        break;
      default:
        chipColor = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }
  Widget _buildTravelIdChip(String travelId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F5FE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Travel $travelId',
        style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFF01579B)),
      ),
    );
  }

  Widget _buildRombonganChip(String rombonganId) {
    final rombongan = _availableRombongan.firstWhere(
      (r) => r.id == rombonganId,
      orElse: () => Rombongan(
        id: '',
        namaRombongan: 'Unknown',
        deskripsi: '',
        travelId: '',
        kapasitas: 0,
        tanggalBerangkat: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        rombongan.namaRombongan,
        style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFF2E7D32)),
      ),
    );
  }

  Widget _buildNoRombonganChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Tanpa Rombongan',
        style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFFE65100)),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(
                _isSelectMode ? Icons.check_box : Icons.checklist,
                size: 28,
              ),
              label: Text(
                _isSelectMode ? 'Mode Pilih' : 'Pilih Multiple',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _isSelectMode ? Colors.white : const Color(0xFFDDE8F8)),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                minimumSize: const Size(0, 55),
                backgroundColor: _isSelectMode ? Colors.green : const Color(0xFF1658B3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(84),
                  side: const BorderSide(
                    color: Color(0xFFB0CAEF),
                    width: 1,
                  ),
                ),
              ),
              onPressed: _toggleSelectMode,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(
                Icons.person_add,
                size: 28,
                color: Color(0xFF1658B3),
              ),
              label: const Text(
                'Tambah Jamaah',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1658B3),
                ),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                minimumSize: const Size(0, 55),
                backgroundColor: const Color(0xFFDCE6F4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(84),
                  side: BorderSide.none,
                ),
              ),
              onPressed: () {
                _clearForm();
                _toggleAddDataPopup();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPopup() {
    return GestureDetector(
      onTap: _toggleFilterPopup,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          color: Colors.black.withOpacity(0.2),
          child: GestureDetector(
            onTap: () {}, // Prevent tap from closing modal
            child: StatefulBuilder(              builder: (BuildContext context, StateSetter setModalState) {
                String localRombongan = _filterRombongan;

                return DraggableScrollableSheet(
                  initialChildSize: 0.5, // Reduced since removing gender filter
                  maxChildSize: 0.8,
                  minChildSize: 0.3,
                  builder: (context, scrollController) {
                    return Container(
                      padding: const EdgeInsets.all(30),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: ListView(
                        controller: scrollController,
                        children: [
                          Center(
                            child: Container(
                              width: 85,
                              height: 6,
                              color: const Color(0xFFE1E1E1),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(child: Text("")),
                              const Expanded(
                                flex: 12,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Filter Jamaah',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: 24,
                                    color: Colors.black.withOpacity(0.65),
                                  ),
                                  onPressed: _toggleFilterPopup,
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 23),
                          
                          // Rombongan Filter only
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Rombongan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Radio<String>(
                                      value: '',
                                      groupValue: localRombongan,
                                      onChanged: (value) {
                                        setModalState(() {
                                          localRombongan = value!;
                                        });
                                      },
                                      activeColor: const Color(0xFF1658B3),
                                    ),
                                    const Text('Semua'),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Radio<String>(
                                      value: 'no_rombongan',
                                      groupValue: localRombongan,
                                      onChanged: (value) {
                                        setModalState(() {
                                          localRombongan = value!;
                                        });
                                      },
                                      activeColor: const Color(0xFF1658B3),
                                    ),
                                    const Text('Tanpa Rombongan'),
                                  ],
                                ),
                                ..._availableRombongan.map((rombongan) => Row(
                                  children: [
                                    Radio<String>(
                                      value: rombongan.id,
                                      groupValue: localRombongan,
                                      onChanged: (value) {
                                        setModalState(() {
                                          localRombongan = value!;
                                        });
                                      },
                                      activeColor: const Color(0xFF1658B3),
                                    ),
                                    Expanded(
                                      child: Text(
                                        rombongan.namaRombongan,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    minimumSize: const Size(0, 55),
                                    backgroundColor: const Color(0xFF1658B3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(84),
                                    ),
                                  ),                                  onPressed: () {
                                    setState(() {
                                      _filterRombongan = localRombongan;
                                    });
                                    _toggleFilterPopup();
                                  },
                                  child: const Text(
                                    'Terapkan Filter',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    minimumSize: const Size(0, 55),
                                    backgroundColor: const Color(0xFFDCE6F4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(84),
                                    ),
                                  ),                                  onPressed: () {
                                    setModalState(() {
                                      localRombongan = '';
                                    });
                                    setState(() {
                                      _filterRombongan = '';
                                    });
                                    _toggleFilterPopup();
                                  },
                                  child: const Text(
                                    'Reset',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1658B3),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddDataPopup() {
    return GestureDetector(
      onTap: _toggleAddDataPopup,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          color: Colors.black.withOpacity(0.2),
          child: GestureDetector(
            onTap: () {}, // Prevent tap from closing modal
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return DraggableScrollableSheet(
                  initialChildSize: 0.6,
                  maxChildSize: 0.9,
                  minChildSize: 0.4,
                  builder: (context, scrollController) {
                    return Container(
                      padding: const EdgeInsets.all(30),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: ListView(
                        controller: scrollController,
                        children: [
                          Center(
                            child: Container(
                              width: 85,
                              height: 6,
                              color: const Color(0xFFE1E1E1),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(child: Text("")),
                              Expanded(
                                flex: 12,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    _editingUserId != null ? 'Edit Jamaah' : 'Tambah Jamaah',
                                    style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: 24,
                                    color: Colors.black.withOpacity(0.65),
                                  ),
                                  onPressed: _toggleAddDataPopup,
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 23),
                          _buildFormField('Nama', 'Masukkan Nama Lengkap', _nameController),
                          const SizedBox(height: 8),
                          _buildFormField('Email', 'Masukkan Alamat Email', _emailController),
                          const SizedBox(height: 8),
                          if (_editingUserId == null) ...[
                            _buildFormField('Password', 'Masukkan Password (kosong = 123456)', _passwordController),
                            const SizedBox(height: 8),
                          ],
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Travel ID',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  _currentTravelId ?? 'Loading...',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  'Otomatis diisi sesuai Travel ID Anda',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.grey.shade500,
                                  ),
                                ),                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Rombongan Dropdown
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Rombongan',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                DropdownButtonFormField<String>(
                                  value: _selectedRombonganId,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Pilih rombongan (opsional)',
                                  ),
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('Tidak ada rombongan'),
                                    ),
                                    ..._availableRombongan.map((rombongan) => DropdownMenuItem<String>(
                                      value: rombongan.id,
                                      child: Text(
                                        '${rombongan.namaRombongan} (${rombongan.jumlahJamaah}/${rombongan.kapasitas})',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )),
                                  ],
                                  onChanged: (value) {
                                    setModalState(() {
                                      _selectedRombonganId = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 36),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    minimumSize: const Size(0, 55),
                                    backgroundColor: const Color(0xFF1658B3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(84),
                                    ),
                                  ),
                                  onPressed: () {
                                    if (_editingUserId != null) {
                                      _updateUser();
                                    } else {
                                      _createUser();
                                    }
                                  },
                                  child: Text(
                                    _editingUserId != null ? 'Update Jamaah' : 'Tambah Jamaah',
                                    style: TextStyle(
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    minimumSize: const Size(0, 55),
                                    backgroundColor: const Color(0xFFDCE6F4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(84),
                                    ),
                                  ),
                                  onPressed: _toggleAddDataPopup,
                                  child: const Text(
                                    'Batal',
                                    style: TextStyle(
                                      color: Color(0xFF1658B3),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCSVPopup() {
    return Container(); // Empty container - not needed for this use case
  }

  Widget _buildFormField(String label, String hint, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8.0),
          TextField(
            controller: controller,
            obscureText: label.toLowerCase().contains('password'),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Colors.grey,
                fontSize: 16.0,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(
              fontSize: 16.0,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 50;
    double dashSpace = 4;
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );
    final path = Path()..addRRect(rect);

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final extractPath = metric.extractPath(
          distance,
          distance + dashWidth,
        );
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
