import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:umrahtrack/data/services/session_manager.dart';
import '../../widgets/bottom_navbar_admin.dart';
import '../../widgets/travel_verification_guard.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _adminName;
  String? _travelId;
  Map<String, dynamic>? _travelData;
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Get admin data
        final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          _adminName = userData['name'] ?? currentUser.displayName ?? 'Admin';
          _travelId = userData['travelId'];
          
          if (_travelId != null) {
            // Get travel data
            final travelDoc = await _firestore.collection('travels').doc(_travelId).get();
            if (travelDoc.exists) {
              _travelData = travelDoc.data() as Map<String, dynamic>;
            }
            
            // Get statistics
            await _loadStats();
          }
        }
      }
    } catch (e) {
      print('Error loading admin data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      // Count jamaah
      final jamaahQuery = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'jamaah')
          .where('travelId', isEqualTo: _travelId)
          .get();
      
      // Count active locations (last 24 hours)
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      
      // This is a simplified count - in real implementation you'd query Firebase Realtime Database
      final activeLocations = jamaahQuery.docs.length; // Simplified for demo
      
      setState(() {
        _stats = {
          'totalJamaah': jamaahQuery.docs.length,
          'activeLocations': activeLocations,
          'totalFinances': 0, // Will be implemented when finance feature is added
          'totalReports': 0, // Will be implemented when reports feature is added
        };
      });
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _handleLogout() async {
    try {
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.logout, color: Color(0xFF1658B3)),
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
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Color(0xFF1658B3)),
          ),
        );

        await SessionManager.logout();
        
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during logout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TravelVerificationGuard(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1658B3)),
              )
            : CustomScrollView(
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeCard(),
                          const SizedBox(height: 20),
                          _buildStatsSection(),
                          const SizedBox(height: 20),
                          _buildQuickActionsSection(),
                          const SizedBox(height: 20),
                          _buildTravelInfoSection(),
                          const SizedBox(height: 100), // Space for bottom nav
                        ],
                      ),
                    ),
                  ),
                ],
              ),        bottomNavigationBar: BottomNavbarAdmin(
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
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Row(
                        children: [
                          Icon(Icons.group_rounded, color: Color(0xFF1658B3)),
                          SizedBox(width: 8),
                          Text('Fitur Rombongan'),
                        ],
                      ),
                      content: const Text('Fitur manajemen rombongan akan segera hadir!'),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1658B3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'OK',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    );
                  },
                );
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF1658B3),
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Dashboard Admin',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1658B3), Color(0xFF42A5F5)],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            setState(() {
              _isLoading = true;
            });
            _loadAdminData();
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          onPressed: _handleLogout,
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1658B3), Color(0xFF42A5F5)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1658B3).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selamat Datang',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _adminName ?? 'Admin',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Travel ${_travelId ?? 'ID'} - ${_travelData?['travelName'] ?? 'UmrahTrack Admin'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Hari Ini',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.people_rounded,
                title: 'Total Jamaah',
                value: '${_stats['totalJamaah'] ?? 0}',
                color: const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.location_on_rounded,
                title: 'Lokasi Aktif',
                value: '${_stats['activeLocations'] ?? 0}',
                color: const Color(0xFF2196F3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Keuangan',
                value: '${_stats['totalFinances'] ?? 0}',
                color: const Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.description_rounded,
                title: 'Laporan',
                value: '${_stats['totalReports'] ?? 0}',
                color: const Color(0xFF9C27B0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6C7B8A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aksi Cepat',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildQuickActionCard(
              icon: Icons.people_rounded,
              title: 'Kelola Jamaah',
              subtitle: 'Manajemen data jamaah',
              color: const Color(0xFF4CAF50),
              onTap: () => Navigator.pushNamed(context, '/kelola_jamaah'),
            ),
            _buildQuickActionCard(
              icon: Icons.location_on_rounded,
              title: 'Pantau Lokasi',
              subtitle: 'Real-time tracking',
              color: const Color(0xFF2196F3),
              onTap: () => Navigator.pushNamed(context, '/admin/lokasi'),
            ),
            _buildQuickActionCard(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Keuangan',
              subtitle: 'Manajemen finansial',
              color: const Color(0xFFFF9800),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur akan segera hadir!')),
              ),
            ),
            _buildQuickActionCard(
              icon: Icons.description_rounded,
              title: 'Laporan',
              subtitle: 'Generate laporan',
              color: const Color(0xFF9C27B0),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur akan segera hadir!')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6C7B8A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTravelInfoSection() {
    if (_travelData == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informasi Travel',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                icon: Icons.business_rounded,
                label: 'Nama Travel',
                value: _travelData!['travelName'] ?? '-',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.phone_rounded,
                label: 'Kontak',
                value: _travelData!['travelPhone'] ?? '-',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.location_city_rounded,
                label: 'Alamat',
                value: _travelData!['travelAddress'] ?? '-',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.event_rounded,
                label: 'Tanggal Berangkat',
                value: _travelData!['departureDate'] ?? '-',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1658B3).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF1658B3),
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6C7B8A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
