import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class SimpleFirebaseTest extends StatefulWidget {
  const SimpleFirebaseTest({super.key});

  @override
  State<SimpleFirebaseTest> createState() => _SimpleFirebaseTestState();
}

class _SimpleFirebaseTestState extends State<SimpleFirebaseTest> {
  String _status = 'Initializing...';
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _runSimpleTest();
  }

  Future<void> _runSimpleTest() async {
    try {
      setState(() => _status = 'Checking Firebase initialization...');
      
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        setState(() => _status = '❌ Firebase not initialized');
        return;
      }
      
      setState(() => _status = '✅ Firebase initialized\n\nChecking authentication...');
      
      // Check authentication
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _status = '❌ User not authenticated\nPlease login first');
        return;
      }
      
      setState(() => _status = '✅ User authenticated: ${user.email}\nUID: ${user.uid}\n\nTesting RTDB connection...');
      
      // Test basic RTDB connection
      await Future.delayed(const Duration(seconds: 1));
      
      // Try to write simple test data
      try {
        await _database.child('test').child('connection').set({
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'message': 'Connection test successful',
          'userId': user.uid,
        });
        
        setState(() => _status += '\n✅ RTDB write successful');
        
        // Try to read back the data
        final snapshot = await _database.child('test').child('connection').get();
        if (snapshot.exists) {
          setState(() => _status += '\n✅ RTDB read successful');
          
          // Now test the actual locations path
          final testLocationData = {
            'latitude': -6.2088,
            'longitude': 106.8456,
            'accuracy': 5.0,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'userId': user.uid,
            'testData': true,
          };
          
          await _database.child('locations').child(user.uid).set(testLocationData);
          setState(() => _status += '\n✅ Location data write successful');
          
          // Read it back
          final locationSnapshot = await _database.child('locations').child(user.uid).get();
          if (locationSnapshot.exists) {
            setState(() => _status += '\n✅ Location data read successful');
            final data = locationSnapshot.value as Map;
            setState(() => _status += '\n📍 Location: ${data['latitude']}, ${data['longitude']}');
          } else {
            setState(() => _status += '\n❌ Location data read failed');
          }
          
        } else {
          setState(() => _status += '\n❌ RTDB read failed');
        }
        
      } catch (e) {
        setState(() => _status += '\n❌ RTDB error: $e');
      }
      
    } catch (e) {
      setState(() => _status = '❌ Test failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Firebase Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Text(
                      _status,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _status = 'Restarting test...');
                _runSimpleTest();
              },
              child: const Text('Restart Test'),
            ),
          ],
        ),
      ),
    );
  }
}
