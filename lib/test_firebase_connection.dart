// Test Firebase Connection and Data Writing
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

class TestFirebaseConnectionPage extends StatefulWidget {
  const TestFirebaseConnectionPage({super.key});

  @override
  State<TestFirebaseConnectionPage> createState() => _TestFirebaseConnectionPageState();
}

class _TestFirebaseConnectionPageState extends State<TestFirebaseConnectionPage> {
  String _log = '';
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _log += '${DateTime.now().toString()}: $message\n';
    });
    print(message);
  }

  Future<void> _testFirebaseConnection() async {
    setState(() {
      _isLoading = true;
      _log = '';
    });

    try {
      _addLog('🔄 Starting Firebase connection test...');

      // 1. Test Firebase initialization
      _addLog('✅ Firebase already initialized');
      _addLog('📱 Project ID: ${Firebase.app().options.projectId}');

      // 2. Test Authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _addLog('✅ User authenticated: ${user.uid}');
        _addLog('📧 User email: ${user.email ?? 'No email'}');
      } else {
        _addLog('⚠️ No user authenticated - creating anonymous user');
        try {
          final userCredential = await FirebaseAuth.instance.signInAnonymously();
          _addLog('✅ Anonymous user created: ${userCredential.user!.uid}');
        } catch (e) {
          _addLog('❌ Failed to create anonymous user: $e');
          return;
        }
      }

      final currentUser = FirebaseAuth.instance.currentUser!;

      // 3. Test Realtime Database write
      _addLog('🔄 Testing Realtime Database write...');
      try {
        final rtdbRef = FirebaseDatabase.instance.ref();
        final testData = {
          'latitude': -6.200000,
          'longitude': 106.816666,
          'accuracy': 10.0,
          'timestamp': ServerValue.timestamp,
          'testMessage': 'Hello from Flutter test!',
          'userId': currentUser.uid,
          'isTracking': true,
        };

        await rtdbRef
            .child('locations')
            .child(currentUser.uid)
            .set(testData);
        
        _addLog('✅ RTDB write successful!');
        _addLog('📍 Data written to: locations/${currentUser.uid}');
      } catch (e) {
        _addLog('❌ RTDB write failed: $e');
      }

      // 4. Test Realtime Database read
      _addLog('🔄 Testing Realtime Database read...');
      try {
        final snapshot = await FirebaseDatabase.instance
            .ref()
            .child('locations')
            .child(currentUser.uid)
            .get();
        
        if (snapshot.exists) {
          _addLog('✅ RTDB read successful!');
          _addLog('📄 Data: ${snapshot.value}');
        } else {
          _addLog('⚠️ No data found in RTDB');
        }
      } catch (e) {
        _addLog('❌ RTDB read failed: $e');
      }

      // 5. Test Firestore write
      _addLog('🔄 Testing Firestore write...');
      try {
        final firestoreData = {
          'userId': currentUser.uid,
          'currentLocation': {
            'latitude': -6.200000,
            'longitude': 106.816666,
            'accuracy': 10.0,
          },
          'tracking': {
            'isActive': true,
            'lastUpdate': Timestamp.now(),
            'updateCount': 1,
          },
          'verification': {
            'status': 'active',
            'lastVerified': Timestamp.now(),
            'source': 'test_script',
          },
          'metadata': {
            'updatedAt': Timestamp.now(),
            'testMessage': 'Hello from Flutter Firestore test!',
          },
        };

        await FirebaseFirestore.instance
            .collection('location_verification')
            .doc(currentUser.uid)
            .set(firestoreData);
        
        _addLog('✅ Firestore write successful!');
        _addLog('📍 Document written to: location_verification/${currentUser.uid}');
      } catch (e) {
        _addLog('❌ Firestore write failed: $e');
      }

      // 6. Test Firestore read
      _addLog('🔄 Testing Firestore read...');
      try {
        final doc = await FirebaseFirestore.instance
            .collection('location_verification')
            .doc(currentUser.uid)
            .get();
        
        if (doc.exists) {
          _addLog('✅ Firestore read successful!');
          _addLog('📄 Document data exists: ${doc.data()?.keys.join(', ')}');
        } else {
          _addLog('⚠️ No document found in Firestore');
        }
      } catch (e) {
        _addLog('❌ Firestore read failed: $e');
      }

      // 7. Test RTDB Rules
      _addLog('🔄 Testing RTDB security rules...');
      try {
        // Try to write to another user's location (should fail if rules are properly set)
        await FirebaseDatabase.instance
            .ref()
            .child('locations')
            .child('test_unauthorized_uid')
            .set({'test': 'unauthorized'});
        
        _addLog('⚠️ RTDB rules may be too permissive - unauthorized write succeeded');
      } catch (e) {
        _addLog('✅ RTDB rules working correctly - unauthorized write blocked');
      }

      _addLog('🎉 Firebase connection test completed!');

    } catch (e) {
      _addLog('❌ General error during test: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearTestData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _addLog('🔄 Clearing test data...');
        
        // Clear RTDB
        await FirebaseDatabase.instance
            .ref()
            .child('locations')
            .child(user.uid)
            .remove();
        _addLog('✅ RTDB test data cleared');

        // Clear Firestore
        await FirebaseFirestore.instance
            .collection('location_verification')
            .doc(user.uid)
            .delete();
        _addLog('✅ Firestore test data cleared');
      }
    } catch (e) {
      _addLog('❌ Error clearing test data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Connection Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testFirebaseConnection,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Test Firebase'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _clearTestData,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Test Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _log.isEmpty ? 'Press "Test Firebase" to start testing...' : _log,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
