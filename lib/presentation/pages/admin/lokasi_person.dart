import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/bottom_navbar_admin.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  // Controller untuk map
  final MapController _mapController = MapController();
  
  // Koordinat lokasi diri sendiri (admin)
  LatLng _selfLocation = LatLng(21.417729508894676, 39.82747184158817); // Lokasi diri sendiri di Mekkah
  
  // Koordinat lokasi jamaah (bisa diganti)
  LatLng _currentLocation = LatLng(21.416729508894676, 39.82647184158817); // Lokasi di Mekkah
  
  // List jamaah dan lokasi mereka (untuk simulasi data)
  List<JamaahLocation> _jamaahList = [];
  
  // Jamaah yang dipilih untuk ditampilkan detailnya
  JamaahLocation? _selectedJamaah;

  // Flag untuk menampilkan ringkasan lokasi
  bool _showLocationSummary = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  void _loadData() {
    // Mock data untuk jamaah dengan koordinat baru di Mekkah
    setState(() {
      _jamaahList = [
        JamaahLocation(
          name: 'Ahmad Fauzi',
          phone: '0812345678',
          address: 'Dekat Masjidil Haram',
          lastSeen: 'Baru saja',
          groupName: 'Grup Umroh Berkah',
          location: LatLng(21.416729508894676, 39.82647184158817),
          avatarUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
        ),
        JamaahLocation(
          name: 'Siti Aisyah',
          phone: '0823456789',
          address: 'Area Abraj Al Bait',
          lastSeen: '5 menit yang lalu',
          groupName: 'Grup Umroh Berkah',
          location: LatLng(21.42245559576951, 39.823298386374326),
          avatarUrl: 'https://randomuser.me/api/portraits/women/2.jpg',
        ),
        JamaahLocation(
          name: 'Abdullah Mahmud',
          phone: '0834567890',
          address: 'Dekat Jam Makkah Royal Clock',
          lastSeen: '10 menit yang lalu',
          groupName: 'Grup Umroh Barokah',
          location: LatLng(21.423149230123666, 39.82706711224022),
          avatarUrl: 'https://randomuser.me/api/portraits/men/3.jpg',
        ),
      ];
      
      // Set jamaah pertama sebagai yang dipilih
      _selectedJamaah = _jamaahList[0];
      _currentLocation = _selectedJamaah!.location;
    });
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
    // Buat list semua titik lokasi termasuk lokasi diri sendiri
    List<LatLng> allPoints = [..._jamaahList.map((j) => j.location), _selfLocation];
    
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Color(0xFF1658B3),
        elevation: 0,
        title: const Text(
          'Lokasi Jamaah',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: () {
              // Refresh lokasi
              _loadData();
            },
          ),
        ],
      ),
      body: Stack(
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
                markers: _jamaahList.map((jamaah) {
                  return Marker(
                    width: 40,
                    height: 40,
                    point: jamaah.location,
                    child: GestureDetector(
                      onTap: () => _selectJamaah(jamaah),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedJamaah == jamaah
                                ? Color(0xFF1658B3)
                                : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(jamaah.avatarUrl),
                        ),
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
                      child: Icon(
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
          
          // Tombol kompas di pojok kanan atas
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: "compass",
              mini: true,
              backgroundColor: Colors.white,
              elevation: 2,
              child: Icon(
                Icons.compass_calibration,
                color: Color(0xFF1658B3),
              ),
              onPressed: _resetMapOrientation,
            ),
          ),
          
          // Tombol untuk fokus lokasi diri dan semua orang
          Positioned(
            top: 76,
            right: 16,
            child: FloatingActionButton(
              heroTag: "focus",
              mini: true,
              backgroundColor: Colors.white,
              elevation: 2,
              child: Icon(
                Icons.my_location,
                color: Color(0xFF1658B3),
              ),
              onPressed: _focusOnSelf,
            ),
          ),
          
          Positioned(
            top: 136,
            right: 16,
            child: FloatingActionButton(
              heroTag: "showAll",
              mini: true,
              backgroundColor: Colors.white,
              elevation: 2,
              child: Icon(
                Icons.people,
                color: Color(0xFF1658B3),
              ),
              onPressed: _showAllPeople,
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
      ),
      bottomNavigationBar: BottomNavbarAdmin(
        currentIndex: 4, // Sesuaikan dengan index menu lokasi
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/admin/home');
              break;
            case 1:
              Navigator.pushNamed(context, '/admin/keuangan');
              break;
            case 2:
              Navigator.pushNamed(context, '/admin/cctv');
              break;
            case 3:
              Navigator.pushNamed(context, '/admin/surat');
              break;
            case 4:
              // Sudah di halaman lokasi
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
                      ),
                      Text(
                        _selectedJamaah!.phone,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF1658B3),
                      side: BorderSide(color: Color(0x261658B3)),
                      backgroundColor: Color(0x261658B3),
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
                      backgroundColor: Color(0xFF1658B3),
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
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.group,
                size: 20,
                color: Color(0xFF1658B3),
              ),
              const SizedBox(width: 8),
              Text(
                _selectedJamaah!.groupName,
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
        ],
      ),
    );
  }
}

// Model untuk data lokasi jamaah
class JamaahLocation {
  final String name;
  final String phone;
  final String address;
  final String lastSeen;
  final String groupName;
  final LatLng location;
  final String avatarUrl;

  JamaahLocation({
    required this.name,
    required this.phone,
    required this.address,
    required this.lastSeen,
    required this.groupName,
    required this.location,
    required this.avatarUrl,
  });
}