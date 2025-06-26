import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class DatabaseRegionTest extends StatefulWidget {
  const DatabaseRegionTest({super.key});

  @override
  State<DatabaseRegionTest> createState() => _DatabaseRegionTestState();
}

class _DatabaseRegionTestState extends State<DatabaseRegionTest> {
  String _logs = '';
  bool _testing = false;

  void _log(String message) {
    setState(() {
      _logs += '[${DateTime.now().toString().substring(11, 19)}] $message\n';
    });
    print('DatabaseRegionTest: $message');
  }

  Future<void> _testDatabaseConnection() async {
    setState(() {
      _testing = true;
      _logs = '';
    });

    _log('🌏 DATABASE REGION CONNECTION TEST');
    _log('Expected URL: https://umrahtrack-hazz-default-rtdb.asia-southeast1.firebasedatabase.app/');
    
    // Test authentication first
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _log('❌ No authenticated user');
      setState(() => _testing = false);
      return;
    }
    
    _log('✅ User authenticated: ${user.email}');
    _log('📱 UID: ${user.uid}');    // Test Firebase app configuration
    _log('\n🔧 Testing Firebase configuration...');
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
        _log('✅ Database URL configured: ${options.databaseURL}');
        if (options.databaseURL!.contains('asia-southeast1')) {
          _log('✅ Correct Asia Southeast region detected');
        } else {
          _log('⚠️ Different region detected');
        }
      } else {
        _log('❌ No database URL configured!');
        _log('💡 This is likely the main issue');
      }
    } catch (e) {
      _log('❌ Firebase config error: $e');
    }    // Test database instance
    _log('\n📡 Testing database instance...');
    try {
      FirebaseDatabase.instance; // Check if default database is accessible
      _log('✅ Database instance created');
      
      // Test with explicit URL - only if Firebase is properly initialized
      if (Firebase.apps.isNotEmpty) {
        final databaseWithUrl = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: 'https://umrahtrack-hazz-default-rtdb.asia-southeast1.firebasedatabase.app',
        );
        _log('✅ Database instance with explicit URL created');
        
        // Test connection info
        _log('\n🔍 Testing connection info...');
        try {
          final connectedRef = databaseWithUrl.ref('.info/connected');
          final connectedSnapshot = await connectedRef.get().timeout(const Duration(seconds: 8));
          final isConnected = connectedSnapshot.value as bool?;
          _log('📡 Connected: ${isConnected ?? false}');
          
          if (isConnected == true) {
          _log('✅ Database connection successful!');
          
          // Test write operation
          _log('\n📝 Testing write operation...');
          try {
            await databaseWithUrl
                .ref('test_region')
                .child(user.uid)
                .set({
                  'message': 'Region test successful',
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                  'region': 'asia-southeast1',
                })
                .timeout(const Duration(seconds: 8));
            
            _log('✅ Write operation successful!');
            
            // Test read back
            final readSnapshot = await databaseWithUrl
                .ref('test_region')
                .child(user.uid)
                .get()
                .timeout(const Duration(seconds: 5));
            
            if (readSnapshot.exists) {
              _log('✅ Read operation successful!');
              _log('📥 Data verified in Asia Southeast region');
              
              // Now test location path
              _log('\n📍 Testing location path write...');
              await databaseWithUrl
                  .ref('locations')
                  .child(user.uid)
                  .set({
                    'latitude': -7.96662,
                    'longitude': 112.6326317,
                    'accuracy': 5.0,
                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                    'test': 'region_fix',
                    'region': 'asia-southeast1',
                  })
                  .timeout(const Duration(seconds: 8));
              
              _log('✅ Location path write successful!');
              _log('🎉 REGION ISSUE FIXED!');
              
            } else {
              _log('❌ Read verification failed');
            }
            
          } catch (e) {
            _log('❌ Write operation failed: $e');
          }
            } else {
          _log('❌ Database not connected');
        }
        
      } catch (e) {
        _log('❌ Connection test failed: $e');
      }
      
      } else {
        _log('❌ Firebase not properly initialized, cannot create explicit database instance');
      }
      
    } catch (e) {
      _log('❌ Database instance error: $e');
    }

    _log('\n🎯 Test completed');
    setState(() => _testing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌏 Database Region Test'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.green.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '🌏 REGION CONFIGURATION TEST\n\nYour database is in Asia Southeast region.\nThis test will verify the region configuration and fix connection issues.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testing ? null : _testDatabaseConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
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
                        Text('Testing Region...'),
                      ],
                    )
                  : const Text('🌏 TEST REGION CONNECTION'),
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
                            _logs.isEmpty ? 'Click "TEST REGION CONNECTION" to start...' : _logs,
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
