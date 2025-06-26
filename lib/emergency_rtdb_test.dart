import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class EmergencyRTDBTest extends StatefulWidget {
  const EmergencyRTDBTest({super.key});

  @override
  State<EmergencyRTDBTest> createState() => _EmergencyRTDBTestState();
}

class _EmergencyRTDBTestState extends State<EmergencyRTDBTest> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String _logs = '';
  bool _testing = false;

  void _log(String message) {
    setState(() {
      _logs += '[${DateTime.now().toString().substring(11, 19)}] $message\n';
    });
    print('EmergencyTest: $message');
  }
  Future<void> _runEmergencyTest() async {
    setState(() {
      _testing = true;
      _logs = '';
    });

    _log('🚨 EMERGENCY RTDB TEST - DIAGNOSIS MODE');
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _log('❌ No authenticated user');
      setState(() => _testing = false);
      return;
    }

    _log('✅ User: ${user.email}');
    _log('📱 UID: ${user.uid}');    // Test 0: Database configuration
    _log('\n🔧 TEST 0: Database Configuration');
    try {
      // Check if Firebase is initialized properly
      if (Firebase.apps.isEmpty) {
        _log('❌ Firebase not initialized!');
        setState(() => _testing = false);
        return;
      }
      
      final app = Firebase.app();
      final options = app.options;
      _log('📋 Project ID: ${options.projectId}');
      
      if (options.databaseURL != null) {
        _log('✅ Database URL: ${options.databaseURL}');
        if (options.databaseURL!.contains('asia-southeast1')) {
          _log('✅ Asia Southeast region detected');
        } else {
          _log('⚠️ Different region: ${options.databaseURL}');
        }
      } else {
        _log('❌ No database URL configured!');
      }
    } catch (e) {
      _log('❌ Firebase config error: $e');
    }    // Test explicit database instance with URL
    _log('\n🌏 TEST 0.5: Explicit Database Instance');
    DatabaseReference dbToUse = _database;
    try {
      // Check if we have a valid Firebase app first
      if (Firebase.apps.isNotEmpty) {
        final explicitDb = FirebaseDatabase.instanceFor(
          app: Firebase.app(), // This uses the already initialized app
          databaseURL: 'https://umrahtrack-hazz-default-rtdb.asia-southeast1.firebasedatabase.app',
        );
        dbToUse = explicitDb.ref();
        _log('✅ Explicit database instance created');
      } else {
        _log('⚠️ No Firebase app available, using default database');
      }
    } catch (e) {
      _log('❌ Explicit database error: $e');
      // Fall back to default database if explicit fails
      _log('📝 Falling back to default database instance');
    }// Test 1: Very simple write to root
    _log('\n🧪 TEST 1: Write to /emergency_test');
    try {
      await dbToUse
          .child('emergency_test')
          .set('Hello World')
          .timeout(const Duration(seconds: 5));
      _log('✅ Root write SUCCESS');
    } catch (e) {
      _log('❌ Root write FAILED: $e');
    }// Test 2: Write to test path
    _log('\n🧪 TEST 2: Write to /test/simple');
    try {
      await dbToUse
          .child('test')
          .child('simple')
          .set({
            'message': 'test',
            'uid': user.uid,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          })
          .timeout(const Duration(seconds: 5));
      _log('✅ Test path write SUCCESS');
    } catch (e) {
      _log('❌ Test path write FAILED: $e');
    }

    // Test 3: Write to locations path (problematic one)
    _log('\n🧪 TEST 3: Write to /locations/${user.uid}');
    try {
      await dbToUse
          .child('locations')
          .child(user.uid)
          .set({
            'latitude': -7.96662,
            'longitude': 112.6326317,
            'test': true,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          })
          .timeout(const Duration(seconds: 5));
      _log('✅ Locations write SUCCESS');
    } catch (e) {
      _log('❌ Locations write FAILED: $e');
    }

    // Test 4: Write with ServerValue.timestamp (problematic)
    _log('\n🧪 TEST 4: Write with ServerValue.timestamp');
    try {
      await dbToUse
          .child('locations')
          .child(user.uid)
          .set({
            'latitude': -7.96662,
            'longitude': 112.6326317,
            'timestamp': ServerValue.timestamp, // This might be the issue
            'test': 'servervalue',
          })
          .timeout(const Duration(seconds: 5));
      _log('✅ ServerValue write SUCCESS');
    } catch (e) {
      _log('❌ ServerValue write FAILED: $e');
    }

    // Test 5: Check connectivity
    _log('\n🧪 TEST 5: Check database connectivity');
    try {
      await _database.child('.info/connected').once().timeout(const Duration(seconds: 5));
      _log('✅ Database connection OK');
    } catch (e) {
      _log('❌ Database connection FAILED: $e');
    }

    // Test 6: Read test
    _log('\n🧪 TEST 6: Read data back');
    try {
      final snapshot = await _database
          .child('locations')
          .child(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));
      
      if (snapshot.exists) {
        _log('✅ Read SUCCESS - data exists');
        final data = snapshot.value;
        _log('📥 Data type: ${data.runtimeType}');
        if (data is Map) {
          _log('📥 Keys: ${(data as Map).keys.toList()}');
        }
      } else {
        _log('⚠️ Read SUCCESS but no data found');
      }
    } catch (e) {
      _log('❌ Read FAILED: $e');
    }

    _log('\n🎯 DIAGNOSIS COMPLETE');
    _log('If all tests FAILED → Check Firebase rules');
    _log('If only ServerValue FAILED → Remove ServerValue.timestamp');
    _log('If locations path FAILED → Check path permissions');

    setState(() => _testing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚨 Emergency RTDB Test'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.red.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '🚨 EMERGENCY DIAGNOSIS\n\nThis test will identify why RTDB writes are hanging.\nIt tests different paths and methods to isolate the issue.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testing ? null : _runEmergencyTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _testing 
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Testing...'),
                            ],
                          )
                        : const Text('🚨 RUN EMERGENCY TEST'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _logs = '');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Results:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _logs.isEmpty ? 'Click "RUN EMERGENCY TEST" to start...' : _logs,
                            style: const TextStyle(
                              fontFamily: 'monospace',
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
      ),
    );
  }
}
