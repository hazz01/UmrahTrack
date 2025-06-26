import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:umrahtrack/providers/location_provider.dart';
import 'package:umrahtrack/services/location_service.dart';

class LocationDiagnosticPage extends StatefulWidget {
  const LocationDiagnosticPage({super.key});

  @override
  State<LocationDiagnosticPage> createState() => _LocationDiagnosticPageState();
}

class _LocationDiagnosticPageState extends State<LocationDiagnosticPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String _logs = '';
  Map<String, dynamic>? _currentLocationData;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _startDiagnostic();
  }

  void _log(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _logs += '[$timestamp] $message\n';
    });
    print('LocationDiagnostic: $message');
  }

  Future<void> _startDiagnostic() async {
    _log('=== STARTING LOCATION DIAGNOSTIC ===');
    
    // Check authentication
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _log('❌ USER NOT AUTHENTICATED');
      return;
    }
    _log('✅ User authenticated: ${user.email}');
    _log('UID: ${user.uid}');

    // Start listening to location updates from Firebase
    _startListeningToFirebase(user.uid);

    // Check location provider state
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    _log('Location Provider Status:');
    _log('  - isTracking: ${locationProvider.isTracking}');
    _log('  - isLocationServiceEnabled: ${locationProvider.isLocationServiceEnabled}');
    _log('  - error: ${locationProvider.error ?? 'none'}');
    _log('  - currentPosition: ${locationProvider.currentPosition != null ? 'available' : 'null'}');

    if (locationProvider.currentPosition != null) {
      _log('Current Position:');
      _log('  - Lat: ${locationProvider.currentPosition!.latitude}');
      _log('  - Lng: ${locationProvider.currentPosition!.longitude}');
      _log('  - Accuracy: ${locationProvider.currentPosition!.accuracy}');
    }
  }

  void _startListeningToFirebase(String uid) {
    if (_isListening) return;
    
    _isListening = true;
    _log('🔄 Starting Firebase RTDB listener for: locations/$uid');

    _database.child('locations').child(uid).onValue.listen(
      (DatabaseEvent event) {
        if (event.snapshot.exists) {
          _log('📥 FIREBASE DATA RECEIVED');
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          setState(() {
            _currentLocationData = data;
          });
          _log('Data keys: ${data.keys.join(', ')}');
          _log('Lat/Lng: ${data['latitude']}, ${data['longitude']}');
          _log('Timestamp: ${data['lastUpdate']}');
        } else {
          _log('📭 No data found in Firebase RTDB');
        }
      },
      onError: (error) {
        _log('❌ Firebase listener error: $error');
      },
    );
  }

  Future<void> _testManualLocationSave() async {
    _log('🧪 Testing manual location save...');
    
    try {
      await LocationService.saveLocationToFirebase(
        latitude: -6.2088,
        longitude: 106.8456,
        accuracy: 5.0,
        altitude: 100.0,
        speed: 0.0,
      );
      _log('✅ Manual save completed');
    } catch (e) {
      _log('❌ Manual save failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Diagnostic'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Cards
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: locationProvider.isTracking 
                            ? Colors.green.shade50 
                            : Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Icon(
                                locationProvider.isTracking 
                                    ? Icons.gps_fixed 
                                    : Icons.gps_off,
                                color: locationProvider.isTracking 
                                    ? Colors.green 
                                    : Colors.red,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                locationProvider.isTracking 
                                    ? 'TRACKING' 
                                    : 'STOPPED',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: locationProvider.isTracking 
                                      ? Colors.green 
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Card(
                        color: _currentLocationData != null 
                            ? Colors.blue.shade50 
                            : Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Icon(
                                _currentLocationData != null 
                                    ? Icons.cloud_done 
                                    : Icons.cloud_off,
                                color: _currentLocationData != null 
                                    ? Colors.blue 
                                    : Colors.orange,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentLocationData != null 
                                    ? 'FIREBASE OK' 
                                    : 'NO DATA',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _currentLocationData != null 
                                      ? Colors.blue 
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Control Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (locationProvider.isTracking) {
                            locationProvider.stopLocationTracking();
                            _log('🛑 Stopped location tracking');
                          } else {
                            locationProvider.startLocationTracking();
                            _log('▶️ Started location tracking');
                          }
                        },
                        icon: Icon(locationProvider.isTracking 
                            ? Icons.stop 
                            : Icons.play_arrow),
                        label: Text(locationProvider.isTracking 
                            ? 'Stop' 
                            : 'Start'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: locationProvider.isTracking 
                              ? Colors.red 
                              : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _testManualLocationSave,
                        icon: const Icon(Icons.upload),
                        label: const Text('Test Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Firebase Data Display
                if (_currentLocationData != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Latest Firebase Data:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Latitude: ${_currentLocationData!['latitude']}'),
                          Text('Longitude: ${_currentLocationData!['longitude']}'),
                          Text('Accuracy: ${_currentLocationData!['accuracy']} m'),
                          Text('Speed: ${_currentLocationData!['speed']} m/s'),
                          Text('Last Update: ${_currentLocationData!['lastUpdate']}'),
                          if (_currentLocationData!['isTracking'] == true)
                            const Text(
                              '🟢 Tracking Active',
                              style: TextStyle(color: Colors.green),
                            ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Logs
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Diagnostic Logs:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _logs = '';
                                  });
                                  _startDiagnostic();
                                },
                                icon: const Icon(Icons.refresh),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                _logs.isEmpty ? 'No logs yet...' : _logs,
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
