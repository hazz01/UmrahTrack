import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserVerificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if current user is verified
  static Future<bool> isCurrentUserVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data();
      return data?['verified'] ?? false;
    } catch (e) {
      print('Error checking user verification: $e');
      return false;
    }
  }

  /// Check if a specific user is verified
  static Future<bool> isUserVerified(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data();
      return data?['verified'] ?? false;
    } catch (e) {
      print('Error checking user verification: $e');
      return false;
    }
  }

  /// Stream to listen to current user verification status
  static Stream<bool> getCurrentUserVerificationStream() {
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
          final data = doc.data();
          return data?['verified'] ?? false;
        });
  }

  /// Admin function to verify a user
  static Future<void> verifyUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'verified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error verifying user: $e');
      rethrow;
    }
  }

  /// Admin function to unverify a user
  static Future<void> unverifyUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'verified': false,
        'unverifiedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error unverifying user: $e');
      rethrow;
    }
  }

  /// Get all unverified users for admin panel
  static Future<List<Map<String, dynamic>>> getUnverifiedUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('verified', isEqualTo: false)
          .where('registrationStatus', isEqualTo: 'complete')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting unverified users: $e');
      return [];
    }
  }
}
