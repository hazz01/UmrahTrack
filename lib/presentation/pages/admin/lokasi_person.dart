import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:umrahtrack/data/services/session_manager.dart';
import 'package:umrahtrack/data/models/rombongan_model.dart';
import '../../widgets/bottom_navbar_admin.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override 
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  // Controller untuk map
  final MapController _mapController = MapController();
  
  // Firebase references - Use explicit Asia Southeast database URL
  final DatabaseReference _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://umrahtrack-hazz-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Koordinat lokasi diri sendiri (admin)
  final LatLng _selfLocation = const LatLng(21.417729508894676, 39.82747184158817); // Lokasi diri sendiri di Mekkah
  
  // Koordinat lokasi jamaah (bisa diganti)
  LatLng _currentLocation = const LatLng(21.416729508894676, 39.82647184158817); // Lokasi di Mekkah
  
  // List jamaah dan lokasi mereka (untuk data real-time)
  List<JamaahLocation> _jamaahList = [];
  
  // Jamaah yang dipilih untuk ditampilkan detailnya
  JamaahLocation? _selectedJamaah;

  // Flag untuk menampilkan ringkasan lokasi
  bool _showLocationSummary = false;
    // Travel ID untuk filter jamaah
  String? _currentTravelId;
  bool _isLoading = true;
  
  // Rombongan filtering
  String _filterRombongan = '';
  List<Rombongan> _availableRombongan = [];
  
  // Stream subscriptions
  Map<String, StreamSubscription> _locationSubscriptions = {};
  
  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  @override
  void dispose() {
    // Cancel all location subscriptions
    for (var subscription in _locationSubscriptions.values) {
      subscription.cancel();
    }
    super.dispose();
  }
    Future<void> _initializeData() async {
    try {
      // Get current travel ID
      final travelId = await SessionManager.getCurrentTravelId();
      if (travelId == null) {
        // Fallback to get from Firebase
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            _currentTravelId = userData['travelId'];
          }
        }
      } else {
        _currentTravelId = travelId;
      }
      
      if (_currentTravelId != null) {
        await _loadRombonganData();
        _loadJamaahData();
      }
    } catch (e) {
      print('Error initializing data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRombonganData() async {
    if (_currentTravelId != null) {
      try {
        final rombonganSnapshot = await _firestore
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
    void _loadJamaahData() {
    // Listen to jamaah users for this travel ID
    _firestore
        .collection('users')
        .where('userType', isEqualTo: 'jamaah')
        .where('travelId', isEqualTo: _currentTravelId)
        .snapshots()
        .listen((snapshot) {
      
      for (var doc in snapshot.docs) {
        final userData = doc.data();
        final userId = doc.id;
        
        // Listen to location updates for each jamaah
        _subscribeToUserLocation(userId, userData);
      }
      
      setState(() {
        _isLoading = false;
      });
    });
  }
  
  void _subscribeToUserLocation(String userId, Map<String, dynamic> userData) {
    // Cancel existing subscription if any
    _locationSubscriptions[userId]?.cancel();
    
    // Subscribe to location updates
    _locationSubscriptions[userId] = _database
        .child('locations')
        .child(userId)
        .onValue
        .listen((event) {
      
      if (event.snapshot.exists) {
        final locationData = Map<String, dynamic>.from(event.snapshot.value as Map);
        final latitude = locationData['latitude']?.toDouble();
        final longitude = locationData['longitude']?.toDouble();
        
        if (latitude != null && longitude != null) {
          final timestamp = locationData['timestamp'] ?? 0;
          final lastUpdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final timeDiff = DateTime.now().difference(lastUpdate);
          
          String lastSeen;
          if (timeDiff.inMinutes < 1) {
            lastSeen = 'Baru saja';
          } else if (timeDiff.inMinutes < 60) {
            lastSeen = '${timeDiff.inMinutes} menit yang lalu';
          } else if (timeDiff.inHours < 24) {
            lastSeen = '${timeDiff.inHours} jam yang lalu';
          } else {
            lastSeen = '${timeDiff.inDays} hari yang lalu';
          }
            // Get rombongan information if exists
          final rombonganId = userData['rombonganId'] as String?;
          String rombonganName = 'Tanpa Rombongan';
          if (rombonganId != null && rombonganId.isNotEmpty) {
            final rombongan = _availableRombongan.firstWhere(
              (r) => r.id == rombonganId,
              orElse: () => Rombongan(
                id: '',
                namaRombongan: 'Unknown Rombongan',
                deskripsi: '',
                travelId: '',
                kapasitas: 0,
                tanggalBerangkat: DateTime.now(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
            rombonganName = rombongan.namaRombongan;
          }

          final jamaahLocation = JamaahLocation(
            userId: userId,
            name: userData['name'] ?? 'Unknown',
            phone: userData['phone'] ?? 'N/A',
            email: userData['email'] ?? 'N/A',
            address: _getAddressFromCoordinates(latitude, longitude),
            lastSeen: lastSeen,
            groupName: 'Travel ${_currentTravelId}',
            rombonganId: rombonganId,
            rombonganName: rombonganName,
            location: LatLng(latitude, longitude),
            avatarUrl: userData['profilePicture'] ?? 'https://ui-avatars.com/api/?name=${userData['name'] ?? 'U'}&background=1658B3&color=fff',
            accuracy: locationData['accuracy']?.toDouble() ?? 0.0,
            speed: locationData['speed']?.toDouble() ?? 0.0,
            isTracking: locationData['isTracking'] == true,
            isOnline: timeDiff.inMinutes < 5, // online jika update < 5 menit
          );
          
          setState(() {
            // Update or add jamaah location
            final existingIndex = _jamaahList.indexWhere((j) => j.userId == userId);
            if (existingIndex != -1) {
              _jamaahList[existingIndex] = jamaahLocation;
            } else {
              _jamaahList.add(jamaahLocation);
            }
            
            // Set first jamaah as selected if none selected
            if (_selectedJamaah == null && _jamaahList.isNotEmpty) {
              _selectedJamaah = _jamaahList[0];
              _currentLocation = _selectedJamaah!.location;
            }
            
            // Update selected jamaah if it's the same user
            if (_selectedJamaah?.userId == userId) {
              _selectedJamaah = jamaahLocation;
            }
          });
        }
      } else {
        // Remove jamaah if no location data
        setState(() {
          _jamaahList.removeWhere((j) => j.userId == userId);
          if (_selectedJamaah?.userId == userId) {
            _selectedJamaah = _jamaahList.isNotEmpty ? _jamaahList[0] : null;
          }
        });
      }
    });
  }
  
  String _getAddressFromCoordinates(double latitude, double longitude) {
    // Simple address approximation for Mecca area
    if (latitude >= 21.420 && latitude <= 21.425 && longitude >= 39.825 && longitude <= 39.830) {
      return 'Dekat Masjidil Haram';
    } else if (latitude >= 21.420 && latitude <= 21.425 && longitude >= 39.820 && longitude <= 39.825) {
      return 'Area Abraj Al Bait';
    } else if (latitude >= 21.415 && latitude <= 21.420) {
      return 'Sekitar Makkah Royal Clock';
    } else {
      return 'Makkah Al-Mukarramah';
    }
  }
    void _loadData() {
    // This method will be called by the refresh button
    // Real data loading is handled by _loadJamaahData()
    _loadJamaahData();
  }
  
  // Fungsi untuk mengubah jamaah yang dipilih tanpa menggerakkan peta
  void _selectJamaah(JamaahLocation jamaah) {
    setState(() {
      _selectedJamaah = jamaah;
      // Tidak lagi memindahkan map ke lokasi jamaah yang dipilih
      // _currentLocation = jamaah.location;
      // _mapController.move(_currentLocation, 15);
      
      // Reset status tampilan ringkasan lokasi saat pilihan jamaah berubah
      _showLocationSummary = false;
    });
  }
  
  // Toggle visibility ringkasan lokasi
  void _toggleLocationSummary() {
    setState(() {
      _showLocationSummary = !_showLocationSummary;
    });
  }
  
  // Fungsi untuk reset orientasi peta ke utara
  void _resetMapOrientation() {
    _mapController.rotate(0); // Reset rotasi ke 0 derajat (utara di atas)
  }
  
  // Fungsi untuk fokus ke lokasi diri sendiri
  void _focusOnSelf() {
    _mapController.move(_selfLocation, 15);
  }
    // Fungsi untuk menampilkan semua orang dalam tampilan peta
  void _showAllPeople() {
    // Filter jamaah berdasarkan rombongan
    final filteredJamaah = _getFilteredJamaah();
    List<LatLng> allPoints = [...filteredJamaah.map((j) => j.location), _selfLocation];
    
    // Hitung bounding box untuk semua titik
    if (allPoints.isNotEmpty) {
      double minLat = allPoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
      double maxLat = allPoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
      double minLng = allPoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
      double maxLng = allPoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
      
      // Tambahkan sedikit padding
      double latPadding = (maxLat - minLat) * 0.2;
      double lngPadding = (maxLng - minLng) * 0.2;
      
      // Buat bounds untuk cakupan semua titik dengan padding
      LatLngBounds bounds = LatLngBounds(
        LatLng(minLat - latPadding, minLng - lngPadding),
        LatLng(maxLat + latPadding, maxLng + lngPadding),
      );
      
      // Terapkan bounds dengan animasi
      // Calculate the center of the bounds
      LatLng center = LatLng(
        (bounds.northEast.latitude + bounds.southWest.latitude) / 2,
        (bounds.northEast.longitude + bounds.southWest.longitude) / 2,
      );

      // Move the map to the center of the bounds with an appropriate zoom level
      _mapController.move(center, 13); // Adjust zoom level as needed
    }
  }

  // Filter jamaah berdasarkan rombongan
  List<JamaahLocation> _getFilteredJamaah() {
    if (_filterRombongan.isEmpty) {
      return _jamaahList;
    } else if (_filterRombongan == 'no_rombongan') {
      return _jamaahList.where((jamaah) => jamaah.rombonganId == null || jamaah.rombonganId!.isEmpty).toList();
    } else {
      return _jamaahList.where((jamaah) => jamaah.rombonganId == _filterRombongan).toList();
    }
  }

  // Toggle filter popup
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String localRombongan = _filterRombongan;
        
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Filter Berdasarkan Rombongan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Semua'),
                    value: '',
                    groupValue: localRombongan,
                    onChanged: (value) {
                      setModalState(() {
                        localRombongan = value!;
                      });
                    },
                    activeColor: const Color(0xFF1658B3),
                  ),
                  RadioListTile<String>(
                    title: const Text('Tanpa Rombongan'),
                    value: 'no_rombongan',
                    groupValue: localRombongan,
                    onChanged: (value) {
                      setModalState(() {
                        localRombongan = value!;
                      });
                    },
                    activeColor: const Color(0xFF1658B3),
                  ),
                  ..._availableRombongan.map((rombongan) => RadioListTile<String>(
                    title: Text(rombongan.namaRombongan),
                    value: rombongan.id,
                    groupValue: localRombongan,
                    onChanged: (value) {
                      setModalState(() {
                        localRombongan = value!;
                      });
                    },
                    activeColor: const Color(0xFF1658B3),
                  )),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filterRombongan = localRombongan;
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1658B3),
                  ),
                  child: const Text('Terapkan', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),      appBar: AppBar(
        backgroundColor: const Color(0xFF1658B3),
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lokasi Jamaah Real-Time',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            Text(
              'Pantau lokasi jamaah secara real-time',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ],
        ),        actions: [
          // Filter button
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                Icons.filter_list,
                color: _filterRombongan.isNotEmpty ? Colors.yellow : Colors.white,
              ),
              onPressed: _showFilterDialog,
              tooltip: 'Filter Rombongan',
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
              ),
              onPressed: () {
                // Refresh lokasi
                _loadData();
              },
              tooltip: 'Refresh Data',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF1658B3),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Memuat data lokasi jamaah...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6C7B8A),
                    ),
                  ),
                ],
              ),
            )
          : _jamaahList.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64,
                        color: Color(0xFF6C7B8A),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Tidak ada data lokasi jamaah',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6C7B8A),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Pastikan jamaah telah mengaktifkan lokasi',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
        children: [
          // Map dengan marker
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15,
              maxZoom: 18,
              minZoom: 3,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
                // Marker Layer untuk lokasi jamaah
              MarkerLayer(
                markers: _getFilteredJamaah().map((jamaah) {
                  return Marker(
                    width: 40,
                    height: 40,
                    point: jamaah.location,
                    child: GestureDetector(
                      onTap: () => _selectJamaah(jamaah),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedJamaah == jamaah
                                    ? const Color(0xFF1658B3)
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(jamaah.avatarUrl),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: jamaah.isOnline ? (jamaah.isTracking ? Colors.green : Colors.orange) : Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                              child: Icon(
                                jamaah.isTracking ? Icons.gps_fixed : Icons.gps_off,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              // Marker untuk lokasi diri sendiri (admin)
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40,
                    height: 40,
                    point: _selfLocation,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.3),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Color(0xFF1658B3),
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
            // Floating action buttons with better styling
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    heroTag: "compass",
                    mini: true,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    onPressed: _resetMapOrientation,
                    child: const Icon(
                      Icons.compass_calibration_rounded,
                      color: Color(0xFF1658B3),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    heroTag: "focus",
                    mini: true,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    onPressed: _focusOnSelf,
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: Color(0xFF1658B3),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    heroTag: "showAll",
                    mini: true,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    onPressed: _showAllPeople,
                    child: const Icon(
                      Icons.people_rounded,
                      color: Color(0xFF1658B3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Detail jamaah di bagian bawah
          if (_selectedJamaah != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Container detail jamaah
                  _buildJamaahDetailCard(),
                  
                  // Container ringkasan lokasi (hanya muncul saat tombol detail ditekan)
                  if (_showLocationSummary) _buildLocationSummary(),
                ],
              ),
            ),
        ],
      ),      bottomNavigationBar: BottomNavbarAdmin(
        currentIndex: 1, // Lokasi is at index 1
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/admin/home');
              break;
            case 1:
              // Already on location page
              break;
            case 2:
              Navigator.pushNamed(context, '/admin/cctv');
              break;
          }
        },
      ),
    );
  }
  
  Widget _buildJamaahDetailCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(_selectedJamaah!.avatarUrl),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedJamaah!.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),                      Text(
                        _selectedJamaah!.email,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF636363),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Color(0xFF1658B3),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Terlihat: ${_selectedJamaah!.lastSeen}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF636363),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.phone,
                    color: Color(0xFF1658B3),
                    size: 24,
                  ),
                  onPressed: () {
                    // Implementasi telepon
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Tambah tombol Detail untuk menampilkan ringkasan lokasi
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(
                      _showLocationSummary ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    label: Text(
                      _showLocationSummary ? 'Sembunyikan Detail' : 'Lihat Detail',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1658B3),
                      side: const BorderSide(color: Color(0x261658B3)),
                      backgroundColor: const Color(0x261658B3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(68),
                      ),
                    ),
                    onPressed: _toggleLocationSummary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      Icons.directions,
                      size: 20,
                    ),
                    label: const Text(
                      'Rute',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1658B3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(68),
                      ),
                    ),
                    onPressed: () {
                      // Implementasi navigasi rute
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLocationSummary() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Lokasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 20,
                color: Color(0xFF1658B3),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedJamaah!.address,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF636363),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),          Row(
            children: [
              const Icon(
                Icons.group,
                size: 20,
                color: Color(0xFF1658B3),
              ),
              const SizedBox(width: 8),
              Text(
                _selectedJamaah!.rombonganName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF636363),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.my_location,
                size: 20,
                color: Color(0xFF1658B3),
              ),
              const SizedBox(width: 8),
              Text(
                '${_selectedJamaah!.location.latitude.toStringAsFixed(6)}, ${_selectedJamaah!.location.longitude.toStringAsFixed(6)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF636363),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.gps_fixed,
                size: 20,
                color: Color(0xFF1658B3),
              ),
              const SizedBox(width: 8),
              Text(
                'Akurasi: ±${_selectedJamaah!.accuracy.toStringAsFixed(1)} meter',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF636363),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.speed,
                size: 20,
                color: Color(0xFF1658B3),
              ),
              const SizedBox(width: 8),
              Text(
                'Kecepatan: ${(_selectedJamaah!.speed * 3.6).toStringAsFixed(1)} km/h',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF636363),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _selectedJamaah!.isTracking ? Icons.gps_fixed : Icons.gps_off,
                size: 20,
                color: _selectedJamaah!.isTracking ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                _selectedJamaah!.isTracking ? 'Tracking Aktif' : 'Tracking Tidak Aktif',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _selectedJamaah!.isTracking ? Colors.green : Colors.orange,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _selectedJamaah!.isOnline ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedJamaah!.isOnline ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _selectedJamaah!.isOnline ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _selectedJamaah!.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _selectedJamaah!.isOnline ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Model untuk data lokasi jamaah
class JamaahLocation {
  final String userId;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String lastSeen;
  final String groupName;
  final String? rombonganId;
  final String rombonganName;
  final LatLng location;
  final String avatarUrl;
  final double accuracy;
  final double speed;
  final bool isTracking;
  final bool isOnline;

  JamaahLocation({
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.lastSeen,
    required this.groupName,
    this.rombonganId,
    required this.rombonganName,
    required this.location,
    required this.avatarUrl,
    required this.accuracy,
    required this.speed,
    required this.isTracking,
    required this.isOnline,
  });
}