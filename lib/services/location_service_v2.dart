import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationServiceV2 {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> saveLocationToFirebaseV2({
    required double latitude,
    required double longitude,
    required double accuracy,
    double? altitude,
    double? speed,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ LocationServiceV2: User not authenticated');
        return;
      }

      print('🔄 LocationServiceV2: Saving location for user ${user.uid}');
      print('📍 Location: $latitude, $longitude');

      final timestamp = DateTime.now();
      final timestampMs = timestamp.millisecondsSinceEpoch;
      
      // Use regular timestamp instead of ServerValue.timestamp
      final locationData = {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude ?? 0.0,
        'speed': speed ?? 0.0,
        'timestamp': timestampMs, // Regular timestamp instead of ServerValue
        'lastUpdate': timestamp.toIso8601String(),
        'userId': user.uid,
        'isTracking': true,
      };

      print('📤 LocationServiceV2: Writing to RTDB path: locations/${user.uid}');
      print('📋 LocationServiceV2: Data to write: $locationData');

      // Try the simplest possible write first
      try {
        print('⏱️ LocationServiceV2: Starting simple RTDB write with 8s timeout...');
        
        await _database
            .child('locations')
            .child(user.uid)
            .set(locationData)
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () {
                throw Exception('RTDB write timeout - database rules might be blocking writes');
              },
            );
        
        print('✅ LocationServiceV2: RTDB write successful');
        
        // Verify write
        final snapshot = await _database
            .child('locations')
            .child(user.uid)
            .get()
            .timeout(const Duration(seconds: 5));
        
        if (snapshot.exists) {
          print('✅ LocationServiceV2: Write verified - data exists');
          final readData = snapshot.value as Map<dynamic, dynamic>;
          print('📥 LocationServiceV2: Verified data has ${readData.keys.length} fields');
        } else {
          print('❌ LocationServiceV2: Write verification failed - no data found');
        }
        
      } catch (e) {
        print('❌ LocationServiceV2: RTDB write failed: $e');
        if (e.toString().contains('timeout')) {
          print('⏰ LocationServiceV2: DIAGNOSIS → Database rules are likely blocking writes');
          print('💡 LocationServiceV2: SOLUTION → Deploy emergency open rules for testing');
        }
        rethrow;
      }

      // Try Firestore (might work even if RTDB doesn't)
      try {
        print('🔄 LocationServiceV2: Attempting Firestore save...');
        await _firestore
            .collection('location_verification')
            .doc(user.uid)
            .set({
          'userId': user.uid,
          'currentLocation': {
            'latitude': latitude,
            'longitude': longitude,
            'accuracy': accuracy,
            'altitude': altitude ?? 0.0,
            'speed': speed ?? 0.0,
          },
          'tracking': {
            'isActive': true,
            'lastUpdate': Timestamp.fromDate(timestamp),
          },
          'timestamp': timestampMs,
          'lastUpdate': timestamp.toIso8601String(),
        }, SetOptions(merge: true))
        .timeout(const Duration(seconds: 8));
        
        print('✅ LocationServiceV2: Firestore write successful');
      } catch (e) {
        print('❌ LocationServiceV2: Firestore write failed: $e');
      }

    } catch (e) {
      print('❌ LocationServiceV2: Error saving location: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  // Test method to check if basic writes work
  static Future<bool> testBasicWrite() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      print('🧪 LocationServiceV2: Testing basic write capability...');

      // Test simplest possible write
      await _database
          .child('test_write')
          .child(user.uid)
          .set({
            'test': true,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          })
          .timeout(const Duration(seconds: 5));

      print('✅ LocationServiceV2: Basic write test successful');
      return true;
    } catch (e) {
      print('❌ LocationServiceV2: Basic write test failed: $e');
      return false;
    }
  }
}
