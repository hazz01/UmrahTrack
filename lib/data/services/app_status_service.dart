import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppStatusService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if current travel user has verified appStatus
  static Future<bool> isCurrentTravelUserVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data() as Map<String, dynamic>;
      final userType = data['userType'] ?? '';
      
      // Only check appStatus for travel users
      if (userType != 'travel') return true;
      
      final appStatus = data['appStatus'] ?? '';
      return appStatus == 'verified';
    } catch (e) {
      print('Error checking travel user verification: $e');
      return false;
    }
  }

  /// Check if a specific user has verified appStatus
  static Future<bool> isUserVerified(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data() as Map<String, dynamic>;
      final userType = data['userType'] ?? '';
      
      // Only check appStatus for travel users
      if (userType != 'travel') return true;
      
      final appStatus = data['appStatus'] ?? '';
      return appStatus == 'verified';
    } catch (e) {
      print('Error checking user verification: $e');
      return false;
    }
  }

  /// Stream to listen to current user appStatus changes
  static Stream<bool> getCurrentUserAppStatusStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return false;
          
          final data = doc.data() as Map<String, dynamic>;
          final userType = data['userType'] ?? '';
          
          // Only check appStatus for travel users
          if (userType != 'travel') return true;
          
          final appStatus = data['appStatus'] ?? '';
          return appStatus == 'verified';
        });
  }

  /// Admin function to verify a travel user
  static Future<void> verifyTravelUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'appStatus': 'verified',
        'verifiedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error verifying travel user: $e');
      rethrow;
    }
  }

  /// Admin function to unverify a travel user
  static Future<void> unverifyTravelUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'appStatus': 'pending',
        'unverifiedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error unverifying travel user: $e');
      rethrow;
    }
  }

  /// Get all unverified travel users for admin panel
  static Future<List<Map<String, dynamic>>> getUnverifiedTravelUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'travel')
          .where('appStatus', whereIn: ['pending', ''])
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting unverified travel users: $e');
      return [];
    }
  }

  /// Get user's current appStatus
  static Future<String> getCurrentUserAppStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return '';

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return '';

      final data = userDoc.data() as Map<String, dynamic>;
      return data['appStatus'] ?? '';
    } catch (e) {
      print('Error getting user app status: $e');
      return '';
    }
  }
}
