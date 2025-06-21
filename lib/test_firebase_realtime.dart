import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestFirebaseRealtimePage extends StatefulWidget {
  const TestFirebaseRealtimePage({super.key});

  @override
  State<TestFirebaseRealtimePage> createState() => _TestFirebaseRealtimePageState();
}

class _TestFirebaseRealtimePageState extends State<TestFirebaseRealtimePage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String _testResult = 'Belum ditest';
  bool _isLoading = false;
  Map<String, dynamic>? _locationData;

  @override
  void initState() {
    super.initState();
    _listenToLocationUpdates();
  }

  void _listenToLocationUpdates() {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _database
          .child('locations')
          .child(currentUser.uid)
          .onValue
          .listen((event) {
        if (event.snapshot.exists) {
          setState(() {
            _locationData = Map<String, dynamic>.from(event.snapshot.value as Map);
          });
        }
      });
    }
  }

  Future<void> _testWriteLocation() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing write...';
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final testLocationData = {
        'latitude': -6.2088,
        'longitude': 106.8456,
        'accuracy': 5.0,
        'altitude': 0.0,
        'speed': 0.0,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'lastUpdate': DateTime.now().toIso8601String(),
        'userId': currentUser.uid,
        'testData': true,
      };

      await _database
          .child('locations')
          .child(currentUser.uid)
          .set(testLocationData);

      setState(() {
        _testResult = '✅ Write berhasil!';
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Write gagal: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testReadAllLocations() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing read all...';
    });

    try {
      final snapshot = await _database.child('locations').get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _testResult = '✅ Read berhasil! Found ${data.length} users with location data';
        });
      } else {
        setState(() {
          _testResult = '⚠️ Tidak ada data lokasi ditemukan';
        });
      }
    } catch (e) {
      setState(() {
        _testResult = '❌ Read gagal: $e';
      });
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
        title: const Text('Test Firebase Realtime DB'),
        backgroundColor: const Color(0xFF1658B3),
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
                    const Text(
                      'Test Result:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _testResult,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            if (_locationData != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Location Data:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Latitude: ${_locationData!['latitude']}'),
                      Text('Longitude: ${_locationData!['longitude']}'),
                      Text('Accuracy: ${_locationData!['accuracy']} m'),
                      Text('Speed: ${_locationData!['speed']} m/s'),
                      Text('Last Update: ${_locationData!['lastUpdate']}'),
                      if (_locationData!['testData'] == true)
                        const Text(
                          '⚠️ Test Data',
                          style: TextStyle(color: Colors.orange),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton(
              onPressed: _isLoading ? null : _testWriteLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1658B3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isLoading && _testResult.contains('write')
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Test Write Location'),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testReadAllLocations,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isLoading && _testResult.contains('read')
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Test Read All Locations'),
            ),

            const SizedBox(height: 16),
            
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cara Test:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Klik "Test Write Location" untuk menulis data test'),
                    Text('2. Klik "Test Read All Locations" untuk membaca semua data'),
                    Text('3. Lihat hasil di "Current Location Data" (real-time)'),
                    Text('4. Jika berhasil, Firebase Realtime DB siap digunakan'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
