import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:umrahtrack/providers/location_provider.dart';
import 'package:umrahtrack/presentation/pages/jamaah/jamaah_home.dart';

class JamaahLokasiPage extends StatefulWidget {
  const JamaahLokasiPage({super.key});

  @override
  State<JamaahLokasiPage> createState() => _JamaahLokasiPageState();
}

class _JamaahLokasiPageState extends State<JamaahLokasiPage> {
  final MapController _mapController = MapController();
  final LatLng _currentMapCenter = const LatLng(21.4225, 39.8262); // Mecca default
  double _currentZoom = 15.0;
  bool _followUser = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }
  void _initializeLocation() {
    try {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      locationProvider.getCurrentLocation();
    } catch (e) {
      // Handle plugin initialization error gracefully
      debugPrint('Location initialization error: $e');
    }
  }

  void _onLocationToggle(LocationProvider locationProvider) {
    if (locationProvider.isTracking) {
      locationProvider.stopLocationTracking();
    } else {
      locationProvider.startLocationTracking();
    }
  }

  void _onRestartLocation(LocationProvider locationProvider) {
    locationProvider.restartLocationTracking();
  }
  void _centerMapOnUser(LocationProvider locationProvider) {
    if (locationProvider.currentPosition != null) {
      final userLocation = LatLng(
        locationProvider.currentPosition!.latitude!,
        locationProvider.currentPosition!.longitude!,
      );
      _mapController.move(userLocation, 16.0);
      setState(() {
        _followUser = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Lokasi Real-Time',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
            ),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {          // Auto-follow user if tracking and follow is enabled
          if (locationProvider.currentPosition != null && _followUser) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final userLocation = LatLng(
                locationProvider.currentPosition!.latitude ?? 0.0,
                locationProvider.currentPosition!.longitude ?? 0.0,
              );
              _mapController.move(userLocation, _currentZoom);
            });
          }

          return Stack(
            children: [
              // Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentMapCenter,
                  initialZoom: _currentZoom,
                  onMapEvent: (MapEvent event) {
                    if (event is MapEventMove) {
                      setState(() {
                        _followUser = false;
                        _currentZoom = event.camera.zoom;
                      });
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.umrahtrack.app',
                  ),                  if (locationProvider.currentPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 60,
                          height: 60,
                          point: LatLng(
                            locationProvider.currentPosition!.latitude ?? 0.0,
                            locationProvider.currentPosition!.longitude ?? 0.0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const CircleAvatar(
                              backgroundColor: Colors.blue,
                              radius: 30,
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 25,
                                child: Icon(
                                  Icons.person_pin_circle,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Location controls
              Positioned(
                top: 16,
                right: 16,
                child: Column(
                  children: [
                    // Center on user button
                    if (locationProvider.currentPosition != null)
                      FloatingActionButton.small(
                        heroTag: "center",
                        backgroundColor: Colors.white,
                        onPressed: () => _centerMapOnUser(locationProvider),
                        child: Icon(
                          _followUser ? Icons.my_location : Icons.location_searching,
                          color: _followUser ? Colors.blue : Colors.grey,
                        ),
                      ),
                    const SizedBox(height: 8),
                    
                    // Restart location button
                    FloatingActionButton.small(
                      heroTag: "restart",
                      backgroundColor: Colors.orange,
                      onPressed: () => _onRestartLocation(locationProvider),
                      child: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Location status card
              Positioned(
                bottom: 100,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              locationProvider.isTracking
                                  ? Icons.location_on
                                  : Icons.location_off,
                              color: locationProvider.isTracking
                                  ? Colors.green
                                  : Colors.red,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              locationProvider.isTracking
                                  ? 'Lokasi Aktif'
                                  : 'Lokasi Tidak Aktif',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: locationProvider.isTracking
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: locationProvider.isTracking,
                              onChanged: (_) => _onLocationToggle(locationProvider),
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                          if (locationProvider.error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.error_outline, 
                                         color: Colors.red.shade600, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        locationProvider.error!,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (locationProvider.error!.contains('MissingPluginException')) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Plugin belum terdaftar. Silakan lakukan Hot Restart (Ctrl+Shift+F5) atau rebuild aplikasi.',
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => locationProvider.openLocationSettings(),
                                  icon: const Icon(Icons.settings),
                                  label: const Text('Pengaturan'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _initializeLocation(),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Coba Lagi'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],                        if (locationProvider.currentPosition != null) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          _buildLocationInfo(
                            'Koordinat',
                            '${locationProvider.currentPosition!.latitude?.toStringAsFixed(6) ?? 'N/A'}, ${locationProvider.currentPosition!.longitude?.toStringAsFixed(6) ?? 'N/A'}',
                            Icons.place,
                          ),
                          const SizedBox(height: 8),
                          _buildLocationInfo(
                            'Akurasi',
                            '±${locationProvider.currentPosition!.accuracy?.toStringAsFixed(1) ?? 'N/A'} meter',
                            Icons.gps_fixed,
                          ),
                          const SizedBox(height: 8),
                          _buildLocationInfo(
                            'Kecepatan',
                            '${((locationProvider.currentPosition!.speed ?? 0.0) * 3.6).toStringAsFixed(1)} km/h',
                            Icons.speed,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavbarJamaah(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/jamaah/home');
              break;
            case 1:
              // Already on location page
              break;
            case 2:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur akan segera hadir!')),
              );
              break;
          }
        },
      ),
    );
  }

  Widget _buildLocationInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6C7B8A)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6C7B8A),
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2E3A59),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
