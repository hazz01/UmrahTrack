import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationStatusTestPage extends StatefulWidget {
  const LocationStatusTestPage({super.key});

  @override
  State<LocationStatusTestPage> createState() => _LocationStatusTestPageState();
}

class _LocationStatusTestPageState extends State<LocationStatusTestPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String _testResults = '';
  bool _isTestingLocation = false;
  bool _isTestingStatus = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Status Test'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firebase Realtime Database Test',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _isTestingLocation ? null : _testLocationSave,
              child: _isTestingLocation 
                ? const CircularProgressIndicator()
                : const Text('Test Save Location Data'),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _isTestingStatus ? null : _testTrackingStatus,
              child: _isTestingStatus 
                ? const CircularProgressIndicator()
                : const Text('Test Tracking Status'),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _testRealtimeListener,
              child: const Text('Test Realtime Listener'),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _checkCurrentLocationData,
              child: const Text('Check Current Location Data'),
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Test Results:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(_testResults.isEmpty ? 'No tests run yet' : _testResults),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testLocationSave() async {
    setState(() {
      _isTestingLocation = true;
      _testResults = 'Testing location save...\n';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _testResults += 'ERROR: User not logged in\n';
          _isTestingLocation = false;
        });
        return;
      }

      // Test data
      final testLocationData = {
        'latitude': -6.2088,
        'longitude': 106.8456,
        'accuracy': 5.0,
        'altitude': 0.0,
        'speed': 0.0,
        'timestamp': ServerValue.timestamp,
        'lastUpdate': DateTime.now().toIso8601String(),
        'userId': user.uid,
        'isTracking': true,
        'testData': true,
      };

      await _database
          .child('locations')
          .child(user.uid)
          .set(testLocationData);

      setState(() {
        _testResults += '✅ Location data saved successfully\n';
        _testResults += 'User ID: ${user.uid}\n';
        _testResults += 'Latitude: ${testLocationData['latitude']}\n';
        _testResults += 'Longitude: ${testLocationData['longitude']}\n';
        _testResults += 'IsTracking: ${testLocationData['isTracking']}\n';
        _testResults += 'Timestamp: ${testLocationData['lastUpdate']}\n\n';
      });
    } catch (e) {
      setState(() {
        _testResults += '❌ ERROR saving location: $e\n\n';
      });
    } finally {
      setState(() {
        _isTestingLocation = false;
      });
    }
  }

  Future<void> _testTrackingStatus() async {
    setState(() {
      _isTestingStatus = true;
      _testResults += 'Testing tracking status...\n';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _testResults += 'ERROR: User not logged in\n';
          _isTestingStatus = false;
        });
        return;
      }

      // Test turning tracking ON
      await _database
          .child('locations')
          .child(user.uid)
          .update({
            'isTracking': true,
            'trackingStatusUpdatedAt': DateTime.now().toIso8601String(),
          });

      setState(() {
        _testResults += '✅ Tracking status set to ON\n';
      });

      await Future.delayed(const Duration(seconds: 2));

      // Test turning tracking OFF
      await _database
          .child('locations')
          .child(user.uid)
          .update({
            'isTracking': false,
            'trackingStatusUpdatedAt': DateTime.now().toIso8601String(),
          });

      setState(() {
        _testResults += '✅ Tracking status set to OFF\n\n';
      });
    } catch (e) {
      setState(() {
        _testResults += '❌ ERROR updating tracking status: $e\n\n';
      });
    } finally {
      setState(() {
        _isTestingStatus = false;
      });
    }
  }

  Future<void> _testRealtimeListener() async {
    setState(() {
      _testResults += 'Setting up realtime listener...\n';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _testResults += 'ERROR: User not logged in\n';
        });
        return;
      }

      _database
          .child('locations')
          .child(user.uid)
          .onValue
          .listen((event) {
        if (event.snapshot.exists) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          setState(() {
            _testResults += '🔄 REALTIME UPDATE received:\n';
            _testResults += 'IsTracking: ${data['isTracking']}\n';
            _testResults += 'LastUpdate: ${data['lastUpdate']}\n';
            if (data['latitude'] != null) {
              _testResults += 'Location: ${data['latitude']}, ${data['longitude']}\n';
            }
            _testResults += '---\n';
          });
        }
      });

      setState(() {
        _testResults += '✅ Realtime listener active\n\n';
      });
    } catch (e) {
      setState(() {
        _testResults += '❌ ERROR setting up listener: $e\n\n';
      });
    }
  }

  Future<void> _checkCurrentLocationData() async {
    setState(() {
      _testResults += 'Checking current location data...\n';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _testResults += 'ERROR: User not logged in\n';
        });
        return;
      }

      final snapshot = await _database
          .child('locations')
          .child(user.uid)
          .get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _testResults += '📍 CURRENT LOCATION DATA:\n';
          _testResults += 'User ID: ${data['userId']}\n';
          _testResults += 'Latitude: ${data['latitude']}\n';
          _testResults += 'Longitude: ${data['longitude']}\n';
          _testResults += 'Accuracy: ${data['accuracy']}\n';
          _testResults += 'IsTracking: ${data['isTracking']}\n';
          _testResults += 'LastUpdate: ${data['lastUpdate']}\n';
          _testResults += 'TrackingStatusUpdatedAt: ${data['trackingStatusUpdatedAt']}\n';
          
          // Check for monitoring capability
          final lastUpdate = DateTime.tryParse(data['lastUpdate'] ?? '');
          if (lastUpdate != null) {
            final timeDiff = DateTime.now().difference(lastUpdate);
            _testResults += 'Time since last update: ${timeDiff.inMinutes} minutes\n';
            
            if (data['isTracking'] == true && timeDiff.inMinutes > 5) {
              _testResults += '🚨 ALERT: Tracking ON but location not updated for ${timeDiff.inMinutes} minutes\n';
            }
          }
          _testResults += '\n';
        });
      } else {
        setState(() {
          _testResults += '❌ No location data found for current user\n\n';
        });
      }
    } catch (e) {
      setState(() {
        _testResults += '❌ ERROR checking location data: $e\n\n';
      });
    }
  }
}
