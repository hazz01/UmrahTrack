import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:umrahtrack/providers/location_provider.dart';

class TestLocationRealtimeVerificationPage extends StatefulWidget {
  const TestLocationRealtimeVerificationPage({super.key});

  @override
  State<TestLocationRealtimeVerificationPage> createState() => _TestLocationRealtimeVerificationPageState();
}

class _TestLocationRealtimeVerificationPageState extends State<TestLocationRealtimeVerificationPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _currentLocationData;
  Map<String, dynamic>? _firestoreVerificationData;
  bool _isListening = false;
  String? _currentUserId;
  StreamSubscription<DatabaseEvent>? _locationSubscription;
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
      _startListeningToLocationData();
    }
  }
  void _startListeningToLocationData() {
    if (_currentUserId == null) return;

    setState(() {
      _isListening = true;
    });

    // Listen to RTDB for real-time coordinates
    _locationSubscription = _database
        .child('locations')
        .child(_currentUserId!)
        .onValue
        .listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _currentLocationData = data;
        });
      } else {
        setState(() {
          _currentLocationData = null;
        });
      }
    });

    // Listen to Firestore for verification data
    _firestoreSubscription = _firestore
        .collection('location_verification')
        .doc(_currentUserId!)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        setState(() {
          _firestoreVerificationData = snapshot.data() as Map<String, dynamic>?;
        });
      } else {
        setState(() {
          _firestoreVerificationData = null;
        });
      }
    });
  }
  void _stopListeningToLocationData() {
    _locationSubscription?.cancel();
    _firestoreSubscription?.cancel();
    setState(() {
      _isListening = false;
      _currentLocationData = null;
      _firestoreVerificationData = null;
    });
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      if (timestamp is int) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}:${date.second}';
      }
      return timestamp.toString();
    } catch (e) {
      return 'Invalid timestamp';
    }
  }

  Color _getStatusColor(bool? isTracking) {
    if (isTracking == null) return Colors.grey;
    return isTracking ? Colors.green : Colors.red;
  }
  String _getStatusText(bool? isTracking) {
    if (isTracking == null) return 'Unknown';
    return isTracking ? 'AKTIF' : 'MATI';
  }

  Color _getVerificationStatusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.orange;
      case 'removed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getVerificationStatusText(String? status) {
    switch (status) {
      case 'active':
        return 'AKTIF';
      case 'inactive':
        return 'TIDAK AKTIF';
      case 'removed':
        return 'DIHAPUS';
      default:
        return 'TIDAK DIKETAHUI';
    }
  }

  String _formatFirestoreTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}:${date.second}';
      } else if (timestamp is String) {
        final date = DateTime.parse(timestamp);
        return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}:${date.second}';
      }
      return timestamp.toString();
    } catch (e) {
      return 'Invalid timestamp';
    }
  }
  @override
  void dispose() {
    _locationSubscription?.cancel();
    _firestoreSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Location Realtime Verification'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firebase Realtime Database Verification',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('User ID: ${_currentUserId ?? "Not logged in"}'),
                    Text('Listening: ${_isListening ? "YES" : "NO"}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Location Provider Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Consumer<LocationProvider>(
                  builder: (context, locationProvider, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location Provider Status',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              locationProvider.isTracking ? Icons.location_on : Icons.location_off,
                              color: locationProvider.isTracking ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tracking: ${locationProvider.isTracking ? "ON" : "OFF"}',
                              style: TextStyle(
                                color: locationProvider.isTracking ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: locationProvider.isTracking 
                                    ? () => locationProvider.stopLocationTracking()
                                    : () => locationProvider.startLocationTracking(),
                                icon: Icon(
                                  locationProvider.isTracking ? Icons.stop : Icons.play_arrow,
                                ),
                                label: Text(
                                  locationProvider.isTracking ? 'Stop Tracking' : 'Start Tracking',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: locationProvider.isTracking ? Colors.red : Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),            
            const SizedBox(height: 16),
            
            // Firestore Verification Display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Firestore Verification Data',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const Spacer(),
                        if (_firestoreVerificationData != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getVerificationStatusColor(_firestoreVerificationData!['verification']?['status']),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getVerificationStatusText(_firestoreVerificationData!['verification']?['status']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _firestoreVerificationData == null
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'No verification data found in Firestore',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Current Location from Firestore
                              const Text(
                                'Current Location (Firestore):',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              if (_firestoreVerificationData!['currentLocation'] != null) ...[
                                _buildDataRow('Latitude', _firestoreVerificationData!['currentLocation']['latitude']?.toString() ?? 'N/A'),
                                _buildDataRow('Longitude', _firestoreVerificationData!['currentLocation']['longitude']?.toString() ?? 'N/A'),
                                _buildDataRow('Accuracy', '${_firestoreVerificationData!['currentLocation']['accuracy']?.toString() ?? 'N/A'} meters'),
                                _buildDataRow('Speed', '${_firestoreVerificationData!['currentLocation']['speed']?.toString() ?? 'N/A'} m/s'),
                              ],
                              
                              const Divider(height: 20),
                              
                              // Tracking Status
                              const Text(
                                'Tracking Status:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              if (_firestoreVerificationData!['tracking'] != null) ...[
                                _buildDataRow(
                                  'Is Active', 
                                  _firestoreVerificationData!['tracking']['isActive']?.toString() ?? 'N/A',
                                  color: _firestoreVerificationData!['tracking']['isActive'] == true ? Colors.green : Colors.red,
                                ),
                                _buildDataRow('Update Count', _firestoreVerificationData!['tracking']['updateCount']?.toString() ?? 'N/A'),
                                _buildDataRow('Last Update', _formatFirestoreTimestamp(_firestoreVerificationData!['tracking']['lastUpdate'])),
                              ],
                              
                              const Divider(height: 20),
                              
                              // Verification Info
                              const Text(
                                'Verification Info:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              if (_firestoreVerificationData!['verification'] != null) ...[
                                _buildDataRow('Status', _firestoreVerificationData!['verification']['status']?.toString() ?? 'N/A'),
                                _buildDataRow('Source', _firestoreVerificationData!['verification']['source']?.toString() ?? 'N/A'),
                                _buildDataRow('Last Verified', _formatFirestoreTimestamp(_firestoreVerificationData!['verification']['lastVerified'])),
                              ],
                            ],
                          ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Firebase Data Display
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Firebase Realtime Data',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_currentLocationData != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(_currentLocationData!['isTracking']),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusText(_currentLocationData!['isTracking']),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _currentLocationData == null
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.location_off, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      'No location data found in Firebase',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDataRow('Latitude', _currentLocationData!['latitude']?.toString() ?? 'N/A'),
                                    _buildDataRow('Longitude', _currentLocationData!['longitude']?.toString() ?? 'N/A'),
                                    _buildDataRow('Accuracy', '${_currentLocationData!['accuracy']?.toString() ?? 'N/A'} meters'),
                                    _buildDataRow('Altitude', '${_currentLocationData!['altitude']?.toString() ?? 'N/A'} meters'),
                                    _buildDataRow('Speed', '${_currentLocationData!['speed']?.toString() ?? 'N/A'} m/s'),
                                    _buildDataRow('Timestamp', _formatTimestamp(_currentLocationData!['timestamp'])),
                                    _buildDataRow('Last Update', _currentLocationData!['lastUpdate']?.toString() ?? 'N/A'),
                                    _buildDataRow('User ID', _currentLocationData!['userId']?.toString() ?? 'N/A'),
                                    const Divider(),
                                    _buildDataRow('Is Tracking', _getStatusText(_currentLocationData!['isTracking']), 
                                        color: _getStatusColor(_currentLocationData!['isTracking'])),
                                    _buildDataRow('Tracking Status Updated', _currentLocationData!['trackingStatusUpdatedAt']?.toString() ?? 'N/A'),
                                      const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.green.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Dual Database Implementation',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade800,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            '🚀 RTDB: Real-time coordinates untuk speed\n'
                                            '🔍 Firestore: Verification & monitoring untuk quality\n'
                                            '📊 History: Complete tracking logs tersimpan\n'
                                            '⚡ Cloud Function: Dapat monitor dari kedua database',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Comparison Table
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Database Comparison',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade800,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'RTDB Status:',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.orange.shade700,
                                                      ),
                                                    ),
                                                    Text(
                                                      _currentLocationData != null ? '✅ Connected' : '❌ No Data',
                                                      style: TextStyle(
                                                        color: _currentLocationData != null ? Colors.green : Colors.red,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Firestore Status:',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.blue.shade700,
                                                      ),
                                                    ),
                                                    Text(
                                                      _firestoreVerificationData != null ? '✅ Connected' : '❌ No Data',
                                                      style: TextStyle(
                                                        color: _firestoreVerificationData != null ? Colors.green : Colors.red,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? Colors.black87,
                fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
