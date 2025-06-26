import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class LocationService {
  // Use explicit database URL for Asia Southeast region
  static final DatabaseReference _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://umrahtrack-hazz-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;static Future<void> saveLocationToFirebase({
    required double latitude,
    required double longitude,
    required double accuracy,
    double? altitude,
    double? speed,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ LocationService: User not authenticated');
        return;
      }

      print('🔄 LocationService: Saving location for user ${user.uid}');
      print('📍 Location: $latitude, $longitude');      final timestamp = DateTime.now();
      final timestampMs = timestamp.millisecondsSinceEpoch;
      
      final locationData = {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude ?? 0.0,
        'speed': speed ?? 0.0,
        'timestamp': timestampMs, // Use regular timestamp instead of ServerValue
        'lastUpdate': timestamp.toIso8601String(),
        'userId': user.uid,
        'isTracking': true,
      };print('📤 LocationService: Writing to RTDB path: locations/${user.uid}');
      print('📋 LocationService: Data to write: $locationData');      // 1. Save coordinates to RTDB for real-time updates (faster)
      try {
        print('⏱️ LocationService: Starting RTDB write with 10s timeout...');
        
        // Add timeout to prevent hanging
        await _database
            .child('locations')
            .child(user.uid)
            .set(locationData)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw Exception('RTDB write timeout after 10 seconds - possible rules/connection issue');
              },
            );
        
        print('✅ LocationService: RTDB write successful');
        
        // Verify write by reading back
        final snapshot = await _database
            .child('locations')
            .child(user.uid)
            .get();
        
        if (snapshot.exists) {
          print('✅ LocationService: RTDB write verified - data exists');
          final readData = snapshot.value as Map<dynamic, dynamic>;
          print('📥 LocationService: Read back data keys: ${readData.keys.toList()}');
        } else {
          print('❌ LocationService: RTDB write verification failed - no data found');
        }
        
      } catch (e) {
        print('❌ LocationService: RTDB write failed: $e');
        print('❌ LocationService: Error type: ${e.runtimeType}');
        if (e.toString().contains('permission') || e.toString().contains('rules')) {
          print('🔒 LocationService: Possible database rules issue');
        }
        rethrow;
      }      // 2. Save verification data to Firestore for structured monitoring
      try {
        await _saveLocationVerificationToFirestore(
          user.uid,
          latitude,
          longitude,
          accuracy,
          altitude ?? 0.0,
          speed ?? 0.0,
          timestamp,
        );
        print('✅ LocationService: Firestore write successful');
      } catch (e) {
        print('❌ LocationService: Firestore write failed: $e');
        // Don't rethrow, let RTDB success continue
      }
    } catch (e) {
      print('❌ LocationService: Error saving location to Firebase: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  static Future<void> _saveLocationVerificationToFirestore(
    String userId,
    double latitude,
    double longitude,
    double accuracy,
    double altitude,
    double speed,
    DateTime timestamp,
  ) async {
    try {
      // Save to Firestore for verification and monitoring
      await _firestore
          .collection('location_verification')
          .doc(userId)
          .set({
        'userId': userId,
        'currentLocation': {
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': accuracy,
          'altitude': altitude,
          'speed': speed,
        },
        'tracking': {
          'isActive': true,
          'lastUpdate': Timestamp.fromDate(timestamp),
          'updateCount': FieldValue.increment(1),
        },
        'verification': {
          'status': 'active',
          'lastVerified': Timestamp.fromDate(timestamp),
          'source': 'mobile_gps',
        },
        'metadata': {
          'updatedAt': Timestamp.fromDate(timestamp),
          'day': timestamp.day,
          'month': timestamp.month,
          'year': timestamp.year,
          'hour': timestamp.hour,
        },
      }, SetOptions(merge: true));

      // Also save to history subcollection for tracking records
      await _firestore
          .collection('location_verification')
          .doc(userId)
          .collection('history')
          .add({
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
        'timestamp': Timestamp.fromDate(timestamp),
        'source': 'realtime_tracking',
      });
    } catch (e) {
      print('Error saving location verification to Firestore: $e');
    }
  }
  static Future<void> saveTrackingStatusToFirebase(bool isTracking) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final timestamp = DateTime.now();

      // 1. Update RTDB for real-time status
      await _database
          .child('locations')
          .child(user.uid)
          .update({
            'isTracking': isTracking,
            'trackingStatusUpdatedAt': timestamp.toIso8601String(),
          });

      // 2. Update Firestore verification for monitoring
      await _firestore
          .collection('location_verification')
          .doc(user.uid)
          .set({
        'tracking': {
          'isActive': isTracking,
          'statusChangedAt': Timestamp.fromDate(timestamp),
          'lastStatusUpdate': timestamp.toIso8601String(),
        },
        'verification': {
          'status': isTracking ? 'active' : 'inactive',
          'lastVerified': Timestamp.fromDate(timestamp),
        },
        'metadata': {
          'updatedAt': Timestamp.fromDate(timestamp),
        },
      }, SetOptions(merge: true));

      // Log status change to history
      await _firestore
          .collection('location_verification')
          .doc(user.uid)
          .collection('status_logs')
          .add({
        'action': isTracking ? 'start_tracking' : 'stop_tracking',
        'timestamp': Timestamp.fromDate(timestamp),
        'source': 'user_action',
      });
    } catch (e) {
      print('Error saving tracking status to Firebase: $e');
    }
  }

  static Stream<DatabaseEvent> getLocationStream(String userId) {
    return _database
        .child('locations')
        .child(userId)
        .onValue;
  }

  static Future<Map<String, dynamic>?> getLastKnownLocation(String userId) async {
    try {
      final snapshot = await _database
          .child('locations')
          .child(userId)
          .get();
      
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      print('Error getting location from Firebase: $e');
      return null;
    }
  }
  static Future<void> removeUserLocation(String userId) async {
    try {
      // Remove from RTDB
      await _database
          .child('locations')
          .child(userId)
          .remove();

      // Update Firestore verification status
      await _firestore
          .collection('location_verification')
          .doc(userId)
          .set({
        'tracking': {
          'isActive': false,
          'statusChangedAt': Timestamp.now(),
        },
        'verification': {
          'status': 'removed',
          'lastVerified': Timestamp.now(),
        },
        'metadata': {
          'updatedAt': Timestamp.now(),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error removing location from Firebase: $e');
    }
  }

  // Firestore Verification Functions
  static Future<Map<String, dynamic>?> getLocationVerification(String userId) async {
    try {
      final doc = await _firestore
          .collection('location_verification')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting location verification from Firestore: $e');
      return null;
    }
  }

  static Stream<DocumentSnapshot> getLocationVerificationStream(String userId) {
    return _firestore
        .collection('location_verification')
        .doc(userId)
        .snapshots();
  }

  static Future<List<Map<String, dynamic>>> getLocationHistory(String userId, {int limit = 50}) async {
    try {
      final query = await _firestore
          .collection('location_verification')
          .doc(userId)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return query.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting location history from Firestore: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllActiveTracking() async {
    try {
      final query = await _firestore
          .collection('location_verification')
          .where('tracking.isActive', isEqualTo: true)
          .get();
      
      return query.docs.map((doc) => {
        'userId': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting active tracking users from Firestore: $e');
      return [];
    }
  }
}
