import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Temporary SessionManager without SharedPreferences to fix the plugin issue
class SessionManager {
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyLoginTime = 'loginTime';
  static const String _keyUserType = 'userType';
  static const String _keyTravelId = 'travelId';
  static const String _keyUserId = 'userId';
  static const String _keyUserEmail = 'userEmail';
  static const String _keyUserName = 'userName';
  
  // Session duration: 1 day (24 hours)
  static const int sessionDurationHours = 24;

  // In-memory storage as fallback (will be reset on app restart)
  static Map<String, dynamic> _inMemoryStorage = {};
  static bool _useInMemoryFallback = true;

  // Save login session
  static Future<void> saveLoginSession({
    required String userId,
    required String userType,
    required String email,
    required String name,
    String? travelId,
  }) async {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    if (_useInMemoryFallback) {
      // Use in-memory storage as fallback
      _inMemoryStorage = {
        _keyIsLoggedIn: true,
        _keyLoginTime: currentTime,
        _keyUserType: userType,
        _keyUserId: userId,
        _keyUserEmail: email,
        _keyUserName: name,
        if (travelId != null) _keyTravelId: travelId,
      };
      return;
    }

    // Try to use SharedPreferences (when plugin is working)
    try {
      // SharedPreferences implementation will be added later
      print('SharedPreferences not available, using in-memory storage');
      _useInMemoryFallback = true;
      await saveLoginSession(
        userId: userId,
        userType: userType,
        email: email,
        name: name,
        travelId: travelId,
      );
    } catch (e) {
      print('Error saving session: $e');
      _useInMemoryFallback = true;
      _inMemoryStorage = {
        _keyIsLoggedIn: true,
        _keyLoginTime: currentTime,
        _keyUserType: userType,
        _keyUserId: userId,
        _keyUserEmail: email,
        _keyUserName: name,
        if (travelId != null) _keyTravelId: travelId,
      };
    }
  }

  // Check if session is valid (not expired)
  static Future<bool> isSessionValid() async {
    if (_useInMemoryFallback) {
      final isLoggedIn = _inMemoryStorage[_keyIsLoggedIn] as bool? ?? false;
      if (!isLoggedIn) return false;
      
      final loginTime = _inMemoryStorage[_keyLoginTime] as int? ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final sessionDuration = const Duration(hours: sessionDurationHours).inMilliseconds;
      
      // Check if session has expired
      if (currentTime - loginTime > sessionDuration) {
        await clearSession(); // Clear expired session
        return false;
      }
      
      return true;
    }

    // Firebase Auth check as fallback
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null;
  }

  // Get stored user data
  static Future<Map<String, dynamic>?> getStoredUserData() async {
    if (!await isSessionValid()) {
      return null;
    }
    
    if (_useInMemoryFallback) {
      return {
        'userId': _inMemoryStorage[_keyUserId],
        'userType': _inMemoryStorage[_keyUserType],
        'email': _inMemoryStorage[_keyUserEmail],
        'name': _inMemoryStorage[_keyUserName],
        'travelId': _inMemoryStorage[_keyTravelId],
      };
    }

    return null;
  }

  // Get travel ID from stored session
  static Future<String?> getStoredTravelId() async {
    if (!await isSessionValid()) {
      return null;
    }
    
    if (_useInMemoryFallback) {
      return _inMemoryStorage[_keyTravelId] as String?;
    }

    return null;
  }

  // Clear session data
  static Future<void> clearSession() async {
    if (_useInMemoryFallback) {
      _inMemoryStorage.clear();
      return;
    }

    try {
      // SharedPreferences clearing will be added later
      _inMemoryStorage.clear();
    } catch (e) {
      print('Error clearing session: $e');
      _inMemoryStorage.clear();
    }
  }

  // Refresh session (extend for another 24 hours)
  static Future<void> refreshSession() async {
    if (_useInMemoryFallback) {
      final isLoggedIn = _inMemoryStorage[_keyIsLoggedIn] as bool? ?? false;
      if (isLoggedIn) {
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        _inMemoryStorage[_keyLoginTime] = currentTime;
      }
      return;
    }

    // Firebase Auth refresh is automatic
  }

  // Get current user's travel ID with Firebase fallback
  static Future<String?> getCurrentTravelId() async {
    // First, try to get from stored session
    final storedTravelId = await getStoredTravelId();
    if (storedTravelId != null) {
      return storedTravelId;
    }

    // If not available in session, get from Firebase
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final travelId = userData['travelId'] as String?;
          
          // Update session with the retrieved travel ID
          if (travelId != null && _useInMemoryFallback) {
            _inMemoryStorage[_keyTravelId] = travelId;
          }
          
          return travelId;
        }
      } catch (e) {
        print('Error getting travel ID from Firebase: $e');
      }
    }
    
    return null;
  }

  // Logout and clear all session data
  static Future<void> logout() async {
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Error signing out from Firebase: $e');
    }
    
    // Clear local session
    await clearSession();
  }
}