import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';

class TestLocationDebugPage extends StatefulWidget {
  const TestLocationDebugPage({super.key});

  @override
  State<TestLocationDebugPage> createState() => _TestLocationDebugPageState();
}

class _TestLocationDebugPageState extends State<TestLocationDebugPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Location _location = Location();
  
  String _debugInfo = 'Starting debug...\n';
  bool _isDebugging = false;

  @override
  void initState() {
    super.initState();
    _startDebug();
  }

  void _addDebugInfo(String info) {
    setState(() {
      _debugInfo += '$info\n';
    });
    print(info);
  }

  Future<void> _startDebug() async {
    setState(() {
      _isDebugging = true;
    });

    _addDebugInfo('=== STARTING LOCATION DEBUG ===');
    
    // 1. Check authentication
    _addDebugInfo('1. Checking authentication...');
    final user = _auth.currentUser;
    if (user == null) {
      _addDebugInfo('❌ ERROR: User not authenticated');
      _addDebugInfo('Please login first before testing location');
      setState(() {
        _isDebugging = false;
      });
      return;
    }
    _addDebugInfo('✅ User authenticated: ${user.uid}');
    _addDebugInfo('   Email: ${user.email}');

    // 2. Check location service
    _addDebugInfo('\n2. Checking location service...');
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      _addDebugInfo('   Service enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        _addDebugInfo('   Requesting location service...');
        serviceEnabled = await _location.requestService();
        _addDebugInfo('   Service request result: $serviceEnabled');
      }

      if (!serviceEnabled) {
        _addDebugInfo('❌ ERROR: Location service not available');
        setState(() {
          _isDebugging = false;
        });
        return;
      }
    } catch (e) {
      _addDebugInfo('❌ ERROR checking location service: $e');
      setState(() {
        _isDebugging = false;
      });
      return;
    }

    // 3. Check location permission
    _addDebugInfo('\n3. Checking location permission...');
    try {
      PermissionStatus permissionGranted = await _location.hasPermission();
      _addDebugInfo('   Permission status: $permissionGranted');
      
      if (permissionGranted == PermissionStatus.denied) {
        _addDebugInfo('   Requesting permission...');
        permissionGranted = await _location.requestPermission();
        _addDebugInfo('   Permission request result: $permissionGranted');
      }

      if (permissionGranted != PermissionStatus.granted) {
        _addDebugInfo('❌ ERROR: Location permission not granted');
        setState(() {
          _isDebugging = false;
        });
        return;
      }
    } catch (e) {
      _addDebugInfo('❌ ERROR checking permission: $e');
      setState(() {
        _isDebugging = false;
      });
      return;
    }

    // 4. Get current location
    _addDebugInfo('\n4. Getting current location...');
    try {
      final locationData = await _location.getLocation();
      _addDebugInfo('✅ Location obtained:');
      _addDebugInfo('   Latitude: ${locationData.latitude}');
      _addDebugInfo('   Longitude: ${locationData.longitude}');
      _addDebugInfo('   Accuracy: ${locationData.accuracy}');
      _addDebugInfo('   Speed: ${locationData.speed}');

      // 5. Test Firebase Realtime Database write
      _addDebugInfo('\n5. Testing Firebase RTDB write...');
      try {
        final testData = {
          'latitude': locationData.latitude,
          'longitude': locationData.longitude,
          'accuracy': locationData.accuracy,
          'altitude': locationData.altitude ?? 0.0,
          'speed': locationData.speed ?? 0.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'lastUpdate': DateTime.now().toIso8601String(),
          'userId': user.uid,
          'isTracking': true,
          'debugTest': true,
        };

        await _database
            .child('locations')
            .child(user.uid)
            .set(testData);
        
        _addDebugInfo('✅ RTDB write successful');

        // 6. Test Firebase Realtime Database read
        _addDebugInfo('\n6. Testing Firebase RTDB read...');
        final snapshot = await _database
            .child('locations')
            .child(user.uid)
            .get();
        
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          _addDebugInfo('✅ RTDB read successful');
          _addDebugInfo('   Data keys: ${data.keys.toList()}');
        } else {
          _addDebugInfo('❌ RTDB read failed: No data found');
        }

      } catch (e) {
        _addDebugInfo('❌ Firebase RTDB error: $e');
      }

      // 7. Test Firestore write
      _addDebugInfo('\n7. Testing Firestore write...');
      try {
        await _firestore
            .collection('location_verification')
            .doc(user.uid)
            .set({
          'userId': user.uid,
          'currentLocation': {
            'latitude': locationData.latitude,
            'longitude': locationData.longitude,
            'accuracy': locationData.accuracy,
          },
          'tracking': {
            'isActive': true,
            'lastUpdate': Timestamp.now(),
          },
          'debugTest': true,
          'testTimestamp': Timestamp.now(),
        }, SetOptions(merge: true));
        
        _addDebugInfo('✅ Firestore write successful');

        // 8. Test Firestore read
        _addDebugInfo('\n8. Testing Firestore read...');
        final doc = await _firestore
            .collection('location_verification')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          _addDebugInfo('✅ Firestore read successful');
          final data = doc.data();
          _addDebugInfo('   Data fields: ${data?.keys.toList()}');
        } else {
          _addDebugInfo('❌ Firestore read failed: No document found');
        }

      } catch (e) {
        _addDebugInfo('❌ Firestore error: $e');
      }

    } catch (e) {
      _addDebugInfo('❌ ERROR getting location: $e');
    }

    _addDebugInfo('\n=== DEBUG COMPLETE ===');
    setState(() {
      _isDebugging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Debug'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Debug Status: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _isDebugging ? 'Running...' : 'Complete',
                          style: TextStyle(
                            color: _isDebugging ? Colors.orange : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isDebugging) 
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Text(
                      _debugInfo,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isDebugging ? null : () {
                setState(() {
                  _debugInfo = 'Restarting debug...\n';
                });
                _startDebug();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(_isDebugging ? 'Running Debug...' : 'Restart Debug'),
            ),
          ],
        ),
      ),
    );
  }
}
