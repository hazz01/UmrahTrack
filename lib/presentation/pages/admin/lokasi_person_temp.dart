import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:umrahtrack/config/mapbox_config.dart';
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
  
  // Status dan data
  List<JamaahLocation> _jamaahList = [];
  JamaahLocation? _selectedJamaah;
  LatLng _currentLocation = const LatLng(MapboxConfig.meccaLatitude, MapboxConfig.meccaLongitude);
  LatLng? _selfLocation;
  bool _isLoading = true;
  String? _error;
  bool _showLocationSummary = false;
  
  // Filter dan pencarian
  List<Map<String, dynamic>> _rombonganList = [];
  String? _selectedRombonganFilter;
  String _searchQuery = '';
  
  // Stream subscriptions
  StreamSubscription<DatabaseEvent>? _locationsSubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadRombonganList();
    _startListeningToLocations();
    
    // Refresh data setiap 30 detik
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _locationsSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      // Gunakan lokasi default Mecca untuk sekarang
      setState(() {
        _selfLocation = _currentLocation;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRombonganList() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final travelIdQuery = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
          
      if (!travelIdQuery.exists) return;
      
      final travelId = travelIdQuery.data()?['travelId'];
      if (travelId == null) return;

      final rombonganQuery = await _firestore
          .collection('rombongan')
          .where('travelId', isEqualTo: travelId)
          .get();

      setState(() {
        _rombonganList = rombonganQuery.docs
            .map((doc) => {
              'id': doc.id,
              'name': doc.data()['name'] ?? 'Unknown',
              ...doc.data()
            })
            .toList();
      });
    } catch (e) {
      print('Error loading rombongan list: $e');
    }
  }

  void _startListeningToLocations() {
    _locationsSubscription = _database.child('locations').onValue.listen((event) {
      if (event.snapshot.exists) {
        _processLocationData(event.snapshot);
      }
    }, onError: (error) {
      setState(() {
        _error = 'Error listening to locations: $error';
      });
    });
  }

  Future<void> _processLocationData(DataSnapshot snapshot) async {
    try {
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;

      List<JamaahLocation> newJamaahList = [];

      for (var entry in data.entries) {
        final userId = entry.key as String;
        final locationData = entry.value as Map<dynamic, dynamic>;

        // Skip if no valid location data
        if (locationData['latitude'] == null || locationData['longitude'] == null) {
          continue;
        }

        // Get user data from Firestore
        final userData = await _getUserData(userId);
        if (userData == null) continue;

        // Check if user is jamaah (not admin/travel)
        if (userData['userType'] != 'jamaah') continue;

        final jamaah = JamaahLocation(
          userId: userId,
          name: userData['fullName'] ?? userData['email'] ?? 'Unknown',
          email: userData['email'] ?? '',
          rombonganName: userData['rombonganName'] ?? 'Tidak ada rombongan',
          location: LatLng(
            (locationData['latitude'] as num).toDouble(),
            (locationData['longitude'] as num).toDouble(),
          ),
          accuracy: (locationData['accuracy'] as num?)?.toDouble() ?? 0.0,
          speed: (locationData['speed'] as num?)?.toDouble() ?? 0.0,
          lastUpdate: locationData['lastUpdate'] ?? '',
          isTracking: locationData['isTracking'] ?? false,
          isOnline: _isOnline(locationData['lastUpdate']),
          avatarUrl: userData['profileImageUrl'] ?? _getDefaultAvatarUrl(),
        );

        newJamaahList.add(jamaah);
      }

      if (mounted) {
        setState(() {
          _jamaahList = newJamaahList;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error processing location data: $e';
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  bool _isOnline(String? lastUpdate) {
    if (lastUpdate == null) return false;
    
    try {
      final updateTime = DateTime.parse(lastUpdate);
      final now = DateTime.now();
      final difference = now.difference(updateTime);
      
      // Consider online if last update was within 5 minutes
      return difference.inMinutes < 5;
    } catch (e) {
      return false;
    }
  }

  String _getDefaultAvatarUrl() {
    return 'https://ui-avatars.com/api/?name=User&background=1658B3&color=fff&size=128';
  }

  Future<void> _refreshData() async {
    // Data sudah auto-refresh melalui listener
    // Method ini bisa digunakan untuk refresh manual jika diperlukan
  }

  List<JamaahLocation> _getFilteredJamaah() {
    List<JamaahLocation> filtered = _jamaahList;

    // Filter by rombongan
    if (_selectedRombonganFilter != null) {
      filtered = filtered.where((jamaah) => 
          jamaah.rombonganName == _selectedRombonganFilter).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((jamaah) => 
          jamaah.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          jamaah.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          jamaah.rombonganName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    return filtered;
  }

  void _selectJamaah(JamaahLocation jamaah) {
    setState(() {
      _selectedJamaah = jamaah;
    });

    // Center map on selected jamaah
    _mapController.move(jamaah.location, 16.0);
  }

  void _focusOnSelf() {
    if (_selfLocation != null) {
      _mapController.move(_selfLocation!, 16.0);
    }
  }

  void _resetMapOrientation() {
    // Flutter map doesn't have bearing, just center the map
    _mapController.move(_currentLocation, 15.0);
  }

  void _focusOnAllJamaah() {
    final filteredJamaah = _getFilteredJamaah();
    if (filteredJamaah.isEmpty) return;

    if (filteredJamaah.length == 1) {
      // If only one jamaah, focus on them
      _selectJamaah(filteredJamaah.first);
      return;
    }

    // Calculate bounds to include all jamaah
    List<LatLng> allPoints = filteredJamaah.map((j) => j.location).toList();
    if (_selfLocation != null) {
      allPoints.add(_selfLocation!);
    }

    if (allPoints.isEmpty) return;

    // Find bounds
    double minLat = allPoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    double maxLat = allPoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    double minLng = allPoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    double maxLng = allPoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

    // Add padding
    double latPadding = (maxLat - minLat) * 0.2;
    double lngPadding = (maxLng - minLng) * 0.2;

    // Create bounds for coverage of all points with padding
    LatLngBounds bounds = LatLngBounds(
      LatLng(minLat - latPadding, minLng - lngPadding),
      LatLng(maxLat + latPadding, maxLng + lngPadding),
    );

    // Calculate the center of the bounds
    LatLng center = LatLng(
      (bounds.northEast.latitude + bounds.southWest.latitude) / 2,
      (bounds.northEast.longitude + bounds.southWest.longitude) / 2,
    );

    // Move the map to the center of the bounds with an appropriate zoom level
    _mapController.move(center, 13); // Adjust zoom level as needed
  }

  void _toggleLocationSummary() {
    setState(() {
      _showLocationSummary = !_showLocationSummary;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text(
            'Lokasi Jamaah',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF1658B3),
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF1658B3),
              ),
              SizedBox(height: 16),
              Text(
                'Loading location data...',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF636363),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text(
            'Lokasi Jamaah',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF1658B3),
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF636363),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _isLoading = true;
                    });
                    _initializeLocation();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1658B3),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Flutter Map with Mapbox tiles
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15,
              maxZoom: MapboxConfig.maxZoom,
              minZoom: MapboxConfig.minZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: MapboxConfig.defaultTileUrl,
                userAgentPackageName: 'com.umrahtrack.app',
                maxZoom: MapboxConfig.maxZoom,
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
              if (_selfLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40,
                      height: 40,
                      point: _selfLocation!,
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

          // Floating action buttons
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
                    heroTag: "all",
                    mini: true,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    onPressed: _focusOnAllJamaah,
                    child: const Icon(
                      Icons.center_focus_strong_rounded,
                      color: Color(0xFF1658B3),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter and search panel
          _buildFilterPanel(),

          // Jamaah detail card
          if (_selectedJamaah != null) _buildJamaahDetailCard(),

          // Location summary
          if (_showLocationSummary) _buildLocationSummary(),

          // Bottom action buttons
          _buildBottomActionButtons(),
        ],
      ),
      bottomNavigationBar: BottomNavbarAdmin(
        currentIndex: 1,
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

  Widget _buildFilterPanel() {
    return Positioned(
      top: 16,
      left: 16,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.filter_list,
                    color: Color(0xFF1658B3),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Filter & Cari',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2E3A59),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_getFilteredJamaah().length} dari ${_jamaahList.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF636363),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Search field
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Cari nama atau email...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              
              // Rombongan filter
              DropdownButtonFormField<String>(
                value: _selectedRombonganFilter,
                decoration: const InputDecoration(
                  labelText: 'Filter Rombongan',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Semua Rombongan'),
                  ),
                  ..._rombonganList.map((rombongan) {
                    return DropdownMenuItem<String>(
                      value: rombongan['name'] as String,
                      child: Text(rombongan['name'] as String),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRombonganFilter = value;
                  });
                },
              ),
            ],
          ),
        ),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedJamaah!.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E3A59),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedJamaah!.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF636363),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedJamaah = null;
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            
            // Location details
            Row(
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
                const Icon(
                  Icons.access_time,
                  size: 20,
                  color: Color(0xFF1658B3),
                ),
                const SizedBox(width: 8),
                Text(
                  'Update terakhir: ${_selectedJamaah!.lastUpdate}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF636363),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _selectedJamaah!.isOnline ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _selectedJamaah!.isOnline ? 'Online' : 'Offline',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _selectedJamaah!.isTracking ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _selectedJamaah!.isTracking ? 'Tracking ON' : 'Tracking OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

  Widget _buildBottomActionButtons() {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(
                    _showLocationSummary ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                  label: Text(
                    _showLocationSummary ? 'Sembunyikan' : 'Ringkasan',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1658B3),
                    side: const BorderSide(color: Color(0xFF1658B3)),
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
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                color: Color(0xFF1658B3),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Ringkasan Lokasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3A59),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Jamaah',
                  '${_jamaahList.length}',
                  Icons.people,
                  const Color(0xFF1658B3),
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Online',
                  '${_jamaahList.where((j) => j.isOnline).length}',
                  Icons.circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Tracking ON',
                  '${_jamaahList.where((j) => j.isTracking).length}',
                  Icons.gps_fixed,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Offline',
                  '${_jamaahList.where((j) => !j.isOnline).length}',
                  Icons.circle,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF636363),
            ),
          ),
        ],
      ),
    );
  }
}

class JamaahLocation {
  final String userId;
  final String name;
  final String email;
  final String rombonganName;
  final LatLng location;
  final double accuracy;
  final double speed;
  final String lastUpdate;
  final bool isTracking;
  final bool isOnline;
  final String avatarUrl;

  JamaahLocation({
    required this.userId,
    required this.name,
    required this.email,
    required this.rombonganName,
    required this.location,
    required this.accuracy,
    required this.speed,
    required this.lastUpdate,
    required this.isTracking,
    required this.isOnline,
    required this.avatarUrl,
  });
}
