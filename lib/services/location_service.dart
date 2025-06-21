import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  static Future<void> saveLocationToFirebase({
    required double latitude,
    required double longitude,
    required double accuracy,
    double? altitude,
    double? speed,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final locationData = {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude ?? 0.0,
        'speed': speed ?? 0.0,
        'timestamp': ServerValue.timestamp,
        'lastUpdate': DateTime.now().toIso8601String(),
        'userId': user.uid,
      };

      await _database
          .child('locations')
          .child(user.uid)
          .set(locationData);
    } catch (e) {
      print('Error saving location to Firebase: $e');
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
      await _database
          .child('locations')
          .child(userId)
          .remove();
    } catch (e) {
      print('Error removing location from Firebase: $e');
    }
  }
}
