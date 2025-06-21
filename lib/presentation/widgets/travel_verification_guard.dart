import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/unverified_account_page.dart';

/// Widget that guards travel pages and redirects to unverified page if appStatus is not "verified"
class TravelVerificationGuard extends StatelessWidget {
  final Widget child;
  final Widget? loadingWidget;
  
  const TravelVerificationGuard({
    super.key,
    required this.child,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _getCurrentUserStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ?? 
            const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          // If there's an error or no user data, redirect to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final userType = userData['userType'] ?? '';
        
        // Only check appStatus for travel users
        if (userType != 'travel') {
          return child; // Allow non-travel users to pass through
        }
        
        final appStatus = userData['appStatus'] ?? '';
        
        if (appStatus != 'verified') {
          // Redirect to unverified account page for unverified travel users
          return const UnverifiedAccountPage();
        }

        // User is verified, show the protected content
        return child;
      },
    );
  }

  Stream<DocumentSnapshot>? _getCurrentUserStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots();
  }
}
