import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Generate random 6-digit OTP
  static String _generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Send OTP to email (mock implementation)
  static Future<bool> sendOTPToEmail(String email, String companyName) async {
    try {
      print('=== SENDING OTP ===');
      print('Email: $email');
      print('Company: $companyName');
      
      // Validate input parameters
      if (email.isEmpty || companyName.isEmpty) {
        print('ERROR: Email or company name is empty');
        return false;
      }
      
      // Generate OTP
      final otp = _generateOTP();
      
      // Store OTP in Firestore with expiration time (5 minutes)
      final expirationTime = DateTime.now().add(const Duration(minutes: 5));
      
      print('Generated OTP: $otp');
      print('Storing in Firestore...');
      
      await _firestore.collection('otps').doc(email).set({
        'otp': otp,
        'email': email,
        'companyName': companyName,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expirationTime),
        'verified': false,
      });

      print('OTP stored successfully in Firestore');
      
      // In a real implementation, you would send the OTP via email service
      // For now, we'll just print it to console for testing
      print('=== OTP SENT SUCCESSFULLY ===');
      print('Email: $email');
      print('Company: $companyName');
      print('OTP Code: $otp');
      print('Expires at: $expirationTime');
      print('============================');

      return true;
    } catch (e) {
      print('ERROR sending OTP: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Verify OTP
  static Future<bool> verifyOTP(String email, String otpCode) async {
    try {
      print('=== VERIFYING OTP ===');
      print('Email: $email');
      print('Provided OTP: $otpCode');
      
      // Validate input parameters
      if (email.isEmpty || otpCode.isEmpty) {
        print('ERROR: Email or OTP code is empty');
        return false;
      }
      
      if (otpCode.length != 6) {
        print('ERROR: OTP code must be 6 digits, provided: ${otpCode.length}');
        return false;
      }
      
      // Get OTP document
      print('Fetching OTP document from Firestore...');
      final otpDoc = await _firestore.collection('otps').doc(email).get();
      
      if (!otpDoc.exists) {
        print('ERROR: OTP document not found for email: $email');
        return false;
      }

      print('OTP document found, validating...');
      final otpData = otpDoc.data() as Map<String, dynamic>;
      final storedOTP = otpData['otp'] as String;
      final expiresAt = (otpData['expiresAt'] as Timestamp).toDate();
      final isVerified = otpData['verified'] as bool? ?? false;

      print('Stored OTP: $storedOTP');
      print('Expires at: $expiresAt');
      print('Already verified: $isVerified');

      // Check if OTP is already verified
      if (isVerified) {
        print('ERROR: OTP already verified for email: $email');
        return false;
      }

      // Check if OTP is expired
      if (DateTime.now().isAfter(expiresAt)) {
        print('ERROR: OTP expired for email: $email');
        return false;
      }

      // Check if OTP matches
      if (storedOTP != otpCode) {
        print('ERROR: OTP mismatch. Expected: $storedOTP, Provided: $otpCode');
        return false;
      }

      // Mark OTP as verified
      print('OTP matches! Marking as verified...');
      await _firestore.collection('otps').doc(email).update({
        'verified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      print('=== OTP VERIFIED SUCCESSFULLY ===');
      print('Email: $email');
      print('================================');
      return true;
    } catch (e) {
      print('ERROR verifying OTP: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Get OTP for debugging purposes (remove in production)
  static Future<String?> getOTPForTesting(String email) async {
    try {
      final otpDoc = await _firestore.collection('otps').doc(email).get();
      
      if (!otpDoc.exists) {
        return null;
      }

      final otpData = otpDoc.data() as Map<String, dynamic>;
      final storedOTP = otpData['otp'] as String;
      final expiresAt = (otpData['expiresAt'] as Timestamp).toDate();
      final isVerified = otpData['verified'] as bool? ?? false;

      if (isVerified || DateTime.now().isAfter(expiresAt)) {
        return null; // OTP is not valid
      }

      return storedOTP;
    } catch (e) {
      print('Error getting OTP for testing: $e');
      return null;
    }
  }

  // Clean up expired OTPs (optional utility method)
  static Future<void> cleanupExpiredOTPs() async {
    try {
      print('Cleaning up expired OTPs...');
      final now = Timestamp.now();
      final expiredOTPs = await _firestore
          .collection('otps')
          .where('expiresAt', isLessThan: now)
          .get();

      for (final doc in expiredOTPs.docs) {
        await doc.reference.delete();
      }

      print('Cleaned up ${expiredOTPs.docs.length} expired OTPs');
    } catch (e) {
      print('Error cleaning up expired OTPs: $e');
    }
  }

  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Debug method to check if OTP exists
  static Future<Map<String, dynamic>?> getOTPStatus(String email) async {
    try {
      final otpDoc = await _firestore.collection('otps').doc(email).get();
      
      if (!otpDoc.exists) {
        return {'exists': false};
      }

      final otpData = otpDoc.data() as Map<String, dynamic>;
      final expiresAt = (otpData['expiresAt'] as Timestamp).toDate();
      final isExpired = DateTime.now().isAfter(expiresAt);
      
      return {
        'exists': true,
        'otp': otpData['otp'],
        'verified': otpData['verified'] ?? false,
        'expired': isExpired,
        'expiresAt': expiresAt.toString(),
        'createdAt': otpData['createdAt']?.toString() ?? 'unknown',
      };
    } catch (e) {
      print('Error getting OTP status: $e');
      return {'error': e.toString()};
    }
  }
}