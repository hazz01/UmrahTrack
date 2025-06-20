import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:umrahtrack/data/services/session_manager.dart';
import '../../widgets/bottom_navbar_admin.dart';
import '../../widgets/travel_verification_guard.dart';

// UserData model class to match Firestore schema
class UserData {
  final String uid;
  final String name;
  final String email;
  final String userType;
  final String? travelId;
  final String? gender;
  final DateTime? createdAt;

  UserData({
    required this.uid,
    required this.name,
    required this.email,
    required this.userType,
    this.travelId,
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
  
  // Filter values
  String _filterGender = '';
  
  // Edit mode
  String? _editingUserId;
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
      }

      // Refresh session when page loads
      await SessionManager.refreshSession();

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

  Future<void> _handleLogout() async {
    try {
      // Show confirmation dialog
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Konfirmasi Logout'),
            content: const Text('Apakah Anda yakin ingin keluar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Logout'),
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
            child: CircularProgressIndicator(),
          ),
        );

        // Logout using session manager
        await SessionManager.logout();
        
        // Navigate to login page
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog if open
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: $e')),
      );
    }
  }

  Stream<QuerySnapshot> _getUsersStream() {
    if (_currentTravelId == null) {
      // Return empty stream if current travel ID is not loaded yet
      return Stream.empty();
    }
    
    Query query = _firestore.collection('users')
        .where('userType', isEqualTo: 'jamaah')
        .where('travelId', isEqualTo: _currentTravelId);
    
    return query.snapshots();
  }

  List<UserData> _filterUsers(List<UserData> users) {
    return users.where((user) {
      // Search filter
      bool matchesSearch = _searchQuery.isEmpty ||
          user.name.toLowerCase().contains(_searchQuery) ||
          user.email.toLowerCase().contains(_searchQuery);
      
      // Gender filter
      bool matchesGender = _filterGender.isEmpty ||
          (user.gender != null && user.gender!.toLowerCase() == _filterGender.toLowerCase());
      
      return matchesSearch && matchesGender;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _filterGender = '';
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
      await userCredential.user!.updateDisplayName(_nameController.text.trim());

      // Create user document in Firestore - automatically assign travel ID from current travel user
      final userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'userType': 'jamaah',
        'travelId': _currentTravelId, // Automatically assign current travel ID
        'createdAt': FieldValue.serverTimestamp(),
        'uid': userCredential.user!.uid,
      };

      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);

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
    }

    try {
      final userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'userType': 'jamaah',
        'travelId': _currentTravelId, // Keep same travel ID
      };

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
    _editingUserId = null;
  }

  void _startEdit(UserData user) {
    _editingUserId = user.uid;
    _nameController.text = user.name;
    _emailController.text = user.email;
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
  }

  @override
  Widget build(BuildContext context) {
    return TravelVerificationGuard(
      child: Scaffold(
        backgroundColor: Color(0xFFF8F8F8),
        appBar: AppBar(
          title: Text('Kelola Jamaah ${_currentTravelId != null ? '- Travel $_currentTravelId' : ''}'),
          backgroundColor: Color(0xFF1658B3),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _handleLogout,
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 20),
                _buildSearchBar(),
                SizedBox(height: 18),
                _buildFilterChips(),
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _hasError
                          ? Center(
                              child: Text(
                                _errorMessage,
                                style: TextStyle(color: Colors.red),
                              ),
                            )
                          : StreamBuilder<QuerySnapshot>(
                              stream: _getUsersStream(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Center(child: CircularProgressIndicator());
                                }
                                
                                if (snapshot.hasError) {
                                  return Center(child: Text('Error: ${snapshot.error}'));
                                }
                                
                                if (_currentTravelId == null) {
                                  return Center(child: CircularProgressIndicator());
                                }
                                
                                final userDocs = snapshot.data?.docs ?? [];
                                final allUsers = userDocs
                                    .map((doc) => UserData.fromFirestore(doc))
                                    .toList();
                                
                                final filteredUsers = _filterUsers(allUsers);
                                
                                if (filteredUsers.isEmpty) {
                                  return Center(
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
                padding: EdgeInsets.all(16),
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
                    SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _toggleSelectMode,
                      child: Text('Batal'),
                    ),
                  ],
                ),
              ),
            _buildBottomActionBar(),
            BottomNavbarAdmin(
              currentIndex: 0,
              onTap: (index) {
                switch (index) {
                  case 0:
                    Navigator.pushNamed(context, '/admin/home');
                    break;
                  case 1:
                    Navigator.pushNamed(context, '/admin/lokasi');
                    break;
                  case 2:
                    Navigator.pushNamed(context, '/admin/cctv');
                    break;
                  case 3:
                    Navigator.pushNamed(context, '/admin/surat');
                    break;
                  case 4:
                    Navigator.pushNamed(context, '/admin/laporan');
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
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
            hintText: 'Cari Data Jamaah',
            prefixIcon: const Icon(
              Icons.search,
              size: 21,
            ),
            suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(84),
              borderSide: const BorderSide(
                color: Color(0xFFB9B9B9),
                width: 1,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            hintStyle: const TextStyle(
                color: Color(0x80000000),
                fontSize: 14,
                fontWeight: FontWeight.w400),
            prefixIconColor: Color(0xFF1658B3)),
      ),
    );
  }

  Widget _buildFilterChips() {
    List<Widget> activeFilters = [];
    
    if (_filterGender.isNotEmpty) {
      activeFilters.add(_buildFilterChip('Gender: $_filterGender', () {
        setState(() {
          _filterGender = '';
        });
      }));
    }
    
    if (_searchQuery.isNotEmpty) {
      activeFilters.add(_buildFilterChip('Pencarian: $_searchQuery', () {
        _searchController.clear();
      }));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 60,
            decoration: BoxDecoration(
              color: Color(0xFF1658B3),
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
                    padding: EdgeInsets.only(right: 8),
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
                        child: Text(
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF636363),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildUserTypeChip(user.userType),
                const SizedBox(width: 8),
                if (user.travelId != null)
                  _buildTravelIdChip(user.travelId!),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide.none,
                      backgroundColor: Color(0x261658B3),
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
                    color: _isSelectMode ? Colors.white : Color(0xFFDDE8F8)),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                minimumSize: const Size(0, 55),
                backgroundColor: _isSelectMode ? Colors.green : Color(0xFF1658B3),
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
                backgroundColor: Color(0xFFDCE6F4),
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
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                String localGender = _filterGender;

                return DraggableScrollableSheet(
                  initialChildSize: 0.4,
                  maxChildSize: 0.7,
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
                              color: Color(0xFFE1E1E1),
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
                          Container(
                            padding: EdgeInsets.symmetric(
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
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Gender',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Radio<String>(
                                      value: '',
                                      groupValue: localGender,
                                      onChanged: (value) {
                                        setModalState(() {
                                          localGender = value!;
                                        });
                                      },
                                      activeColor: Color(0xFF1658B3),
                                    ),
                                    const Text('Semua'),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Radio<String>(
                                      value: 'Laki-laki',
                                      groupValue: localGender,
                                      onChanged: (value) {
                                        setModalState(() {
                                          localGender = value!;
                                        });
                                      },
                                      activeColor: Color(0xFF1658B3),
                                    ),
                                    const Text('Laki-laki'),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Radio<String>(
                                      value: 'Perempuan',
                                      groupValue: localGender,
                                      onChanged: (value) {
                                        setModalState(() {
                                          localGender = value!;
                                        });
                                      },
                                      activeColor: Color(0xFF1658B3),
                                    ),
                                    const Text('Perempuan'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  child: const Text(
                                    'Terapkan Filter',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    minimumSize: const Size(0, 55),
                                    backgroundColor: Color(0xFF1658B3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(84),
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _filterGender = localGender;
                                    });
                                    _toggleFilterPopup();
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  child: const Text(
                                    'Reset',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1658B3),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    minimumSize: const Size(0, 55),
                                    backgroundColor: Color(0xFFDCE6F4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(84),
                                    ),
                                  ),
                                  onPressed: () {
                                    setModalState(() {
                                      localGender = '';
                                    });
                                    setState(() {
                                      _filterGender = '';
                                    });
                                  },
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
                              color: Color(0xFFE1E1E1),
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
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Travel ID',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8.0),
                                Text(
                                  _currentTravelId ?? 'Loading...',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                SizedBox(height: 4.0),
                                Text(
                                  'Otomatis diisi sesuai Travel ID Anda',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 36),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  child: Text(
                                    _editingUserId != null ? 'Update Jamaah' : 'Tambah Jamaah',
                                    style: TextStyle(
                                        color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    minimumSize: const Size(0, 55),
                                    backgroundColor: Color(0xFF1658B3),
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
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  child: const Text(
                                    'Batal',
                                    style: TextStyle(
                                      color: Color(0xFF1658B3),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    minimumSize: const Size(0, 55),
                                    backgroundColor: Color(0xFFDCE6F4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(84),
                                    ),
                                  ),
                                  onPressed: _toggleAddDataPopup,
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
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8.0),
          TextField(
            controller: controller,
            obscureText: label.toLowerCase().contains('password'),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey,
                fontSize: 16.0,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: TextStyle(
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
      Radius.circular(16),
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
