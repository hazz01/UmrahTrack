import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AdminLocationTest extends StatefulWidget {
  const AdminLocationTest({super.key});

  @override
  State<AdminLocationTest> createState() => _AdminLocationTestState();
}

class _AdminLocationTestState extends State<AdminLocationTest> {
  final DatabaseReference _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://umrahtrack-hazz-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  StreamSubscription<DatabaseEvent>? _locationsSubscription;
  String? _adminTravelId;
  List<Map<String, dynamic>> _jamaahData = [];
  String _status = 'Initializing...';
  
  @override
  void initState() {
    super.initState();
    _testAdminLocationAccess();
  }
  
  @override
  void dispose() {
    _locationsSubscription?.cancel();
    super.dispose();
  }
  
  Future<void> _testAdminLocationAccess() async {
    try {
      setState(() {
        _status = 'Getting admin data...';
      });
      
      // Get current admin
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _status = 'Error: No authenticated user';
        });
        return;
      }
      
      print('Test: Current user: ${user.uid}');
      
      // Get admin's travelId
      final adminDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!adminDoc.exists) {
        setState(() {
          _status = 'Error: Admin document not found';
        });
        return;
      }
      
      final adminData = adminDoc.data()!;
      _adminTravelId = adminData['travelId'];
      
      setState(() {
        _status = 'Admin TravelId: $_adminTravelId\nUserType: ${adminData['userType']}';
      });
      
      print('Test: Admin travelId: $_adminTravelId');
      print('Test: Admin userType: ${adminData['userType']}');
      
      if (_adminTravelId == null) {
        setState(() {
          _status = 'Error: Admin has no travelId';
        });
        return;
      }
      
      // Start listening to realtime database
      _startListeningToLocations();
      
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
      print('Test: Error getting admin data: $e');
    }
  }
  
  void _startListeningToLocations() {
    print('Test: Starting to listen to realtime database...');
    setState(() {
      _status += '\nListening to realtime database...';
    });
    
    _locationsSubscription = _database.child('locations').onValue.listen((event) {
      print('Test: Received database event');
      if (event.snapshot.exists) {
        _processLocationData(event.snapshot);
      } else {
        print('Test: No location data found');
        setState(() {
          _jamaahData = [];
          _status += '\nNo location data found';
        });
      }
    }, onError: (error) {
      print('Test: Database error: $error');
      setState(() {
        _status += '\nDatabase error: $error';
      });
    });
  }
  
  Future<void> _processLocationData(DataSnapshot snapshot) async {
    try {
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;
      
      print('Test: Processing ${data.length} location entries');
      setState(() {
        _status += '\nProcessing ${data.length} location entries...';
      });
      
      List<Map<String, dynamic>> validJamaahData = [];
      
      for (var entry in data.entries) {
        final userId = entry.key as String;
        final locationData = entry.value as Map<dynamic, dynamic>;
        
        print('Test: Checking user: $userId');
        
        // Get user data
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (!userDoc.exists) {
          print('Test: User $userId not found in Firestore');
          continue;
        }
        
        final userData = userDoc.data()!;
        final userType = userData['userType'];
        final userTravelId = userData['travelId'];
        
        print('Test: User $userId - Type: $userType, TravelId: $userTravelId');
        
        // Check if user is jamaah
        if (userType != 'jamaah') {
          print('Test: Skipping $userId - not jamaah');
          continue;
        }
        
        // Check if same travel
        if (userTravelId != _adminTravelId) {
          print('Test: Skipping $userId - different travel ($userTravelId vs $_adminTravelId)');
          continue;
        }
        
        print('Test: VALID JAMAAH FOUND: ${userData['fullName']}');
        
        validJamaahData.add({
          'userId': userId,
          'name': userData['fullName'] ?? 'Unknown',
          'email': userData['email'] ?? '',
          'rombonganName': userData['rombonganName'] ?? 'No group',
          'userType': userType,
          'travelId': userTravelId,
          'latitude': locationData['latitude'],
          'longitude': locationData['longitude'],
          'lastUpdate': locationData['lastUpdate'],
          'isTracking': locationData['isTracking'] ?? false,
        });
      }
      
      setState(() {
        _jamaahData = validJamaahData;
        _status += '\nFound ${validJamaahData.length} valid jamaah';
      });
      
      print('Test: Found ${validJamaahData.length} valid jamaah for admin');
      
    } catch (e) {
      print('Test: Error processing location data: $e');
      setState(() {
        _status += '\nError processing data: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Location Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Test Status:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_status),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Jamaah Found: ${_jamaahData.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _jamaahData.length,
                itemBuilder: (context, index) {
                  final jamaah = _jamaahData[index];
                  return Card(
                    child: ListTile(
                      title: Text(jamaah['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${jamaah['email']}'),
                          Text('Group: ${jamaah['rombonganName']}'),
                          Text('TravelId: ${jamaah['travelId']}'),
                          Text('Location: ${jamaah['latitude']}, ${jamaah['longitude']}'),
                          Text('Last Update: ${jamaah['lastUpdate']}'),
                          Text('Tracking: ${jamaah['isTracking']}'),
                        ],
                      ),
                      leading: CircleAvatar(
                        child: Text(jamaah['name'][0]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _testAdminLocationAccess,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
