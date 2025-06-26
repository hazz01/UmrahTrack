import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class QuickRTDBTest extends StatefulWidget {
  const QuickRTDBTest({super.key});

  @override
  State<QuickRTDBTest> createState() => _QuickRTDBTestState();
}

class _QuickRTDBTestState extends State<QuickRTDBTest> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String _status = 'Initializing...';
  
  @override
  void initState() {
    super.initState();
    _testRTDB();
  }

  Future<void> _testRTDB() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _status = '❌ User not authenticated');
      return;
    }

    setState(() => _status = '✅ User: ${user.email}\nUID: ${user.uid}\n\n🔍 Testing RTDB...');

    try {
      // Test 1: Simple write to test path
      setState(() => _status += '\n🧪 Test 1: Writing to /test path...');
      await _database.child('test').child('connection').set({
        'message': 'Hello from Flutter',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'uid': user.uid,
      });
      setState(() => _status += '\n✅ Test path write successful');

      // Test 2: Write to locations path (the actual path we use)
      setState(() => _status += '\n\n🧪 Test 2: Writing to /locations/${user.uid}...');
      await _database.child('locations').child(user.uid).set({
        'latitude': -7.96662,
        'longitude': 112.6326317,
        'accuracy': 5.0,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'test': true,
      });
      setState(() => _status += '\n✅ Locations path write successful');

      // Test 3: Read back the data
      setState(() => _status += '\n\n🧪 Test 3: Reading back data...');
      final snapshot = await _database.child('locations').child(user.uid).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() => _status += '\n✅ Read successful');
        setState(() => _status += '\n📥 Data: ${data.toString()}');
      } else {
        setState(() => _status += '\n❌ Read failed - no data found');
      }

      // Test 4: Test with ServerValue.timestamp
      setState(() => _status += '\n\n🧪 Test 4: Testing ServerValue.timestamp...');
      await _database.child('locations').child(user.uid).update({
        'serverTimestamp': ServerValue.timestamp,
        'lastUpdate': DateTime.now().toIso8601String(),
      });
      setState(() => _status += '\n✅ ServerValue.timestamp test successful');

    } catch (e) {
      setState(() => _status += '\n❌ ERROR: $e');
      
      // Analyze error type
      if (e.toString().contains('permission') || e.toString().contains('rules')) {
        setState(() => _status += '\n\n🔒 DIAGNOSIS: Database Rules Issue');
        setState(() => _status += '\n💡 Fix: Update database rules in Firebase Console');
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        setState(() => _status += '\n\n📡 DIAGNOSIS: Network Issue');
        setState(() => _status += '\n💡 Fix: Check internet connection');
      } else {
        setState(() => _status += '\n\n🔧 DIAGNOSIS: Unknown Error');
        setState(() => _status += '\n💡 Fix: Check Firebase configuration');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick RTDB Test'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              color: Color(0xFFFFEBEE),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '🚨 RTDB DIAGNOSIS TEST\n\nThis will test Firebase Realtime Database write/read operations to identify why location data is not saving.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
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
                      _status,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _status = 'Restarting test...');
                _testRTDB();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Restart Test'),
            ),
          ],
        ),
      ),
    );
  }
}
