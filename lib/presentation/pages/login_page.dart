// main.dart - Complete Firebase Auth Implementation with Session Management

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:umrahtrack/data/services/session_manager.dart';
import 'package:umrahtrack/firebase_options.dart';
import 'package:umrahtrack/presentation/pages/admin/kelola_jamaah_page.dart';
import 'package:umrahtrack/presentation/pages/jamaah/jamaah_home.dart';
import 'package:umrahtrack/presentation/pages/travel_registration_page.dart';
import 'package:umrahtrack/presentation/pages/unverified_account_page.dart';

// Firebase configuration - Replace with your own config

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      // Use AuthWrapper to handle authentication state
      home: const AuthWrapper(),      routes: {
        '/login': (context) => const LoginPage(),
        '/admin/home': (context) => const AdminHomePage(),
        '/jamaah/home': (context) => const JamaahHomePage(),
        '/kelola_jamaah': (context) => const KelolaWargaPage(),
        '/unverified_account': (context) => const UnverifiedAccountPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// Auth Wrapper to handle authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAuthState(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final isAuthenticated = snapshot.data ?? false;
        
        if (isAuthenticated) {
          return const UserTypeRouter();
        } else {
          return const LoginPage();
        }
      },
    );
  }

  Future<bool> _checkAuthState() async {
    // Check session validity first
    final isSessionValid = await SessionManager.isSessionValid();
    if (!isSessionValid) {
      // Clear any existing Firebase auth if session is expired
      if (FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.signOut();
      }
      return false;
    }

    // Check if Firebase user exists
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      await SessionManager.clearSession();
      return false;
    }

    // Refresh session to extend for another 24 hours
    await SessionManager.refreshSession();
    return true;
  }
}

// Router to determine user type and navigate accordingly
class UserTypeRouter extends StatelessWidget {
  const UserTypeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final userData = snapshot.data;
        if (userData == null) {
          // If no user data, logout and redirect to login
          SessionManager.logout();
          return const LoginPage();
        }
          final userType = userData['userType'] ?? '';
        
        // For travel users, check appStatus for verification
        if (userType == 'travel') {
          String appStatus = userData['appStatus'] ?? '';
          
          if (appStatus != 'verified') {
            // Block access for unverified travel accounts
            SessionManager.logout();
            return const UnverifiedAccountPage();
          }
        }
        
        if (userType == 'travel') {
          return const KelolaWargaPage();
        } else if (userType == 'jamaah') {
          return const JamaahHomePage();
        } else {
          // Invalid user type, logout
          SessionManager.logout();
          return const LoginPage();
        }
      },
    );
  }

  Future<Map<String, dynamic>?> _getUserData() async {
    try {
      // First try to get from session
      final storedData = await SessionManager.getStoredUserData();
      if (storedData != null && storedData['userType'] != null) {
        return storedData;
      }

      // If not in session, get from Firebase
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          
          // Save to session for future use
          await SessionManager.saveLoginSession(
            userId: currentUser.uid,
            userType: userData['userType'] ?? '',
            email: userData['email'] ?? currentUser.email ?? '',
            name: userData['name'] ?? currentUser.displayName ?? '',
            travelId: userData['travelId'],
          );
          
          return userData;
        }
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
    
    return null;
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  bool isLogin = true;
  bool isTravelUser = true;
  bool isPasswordVisible = false;
  bool isLoading = false;
  String? _generatedTravelId;
  bool _isGeneratingTravelId = false;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    
    // Generate Travel ID if starting in register mode with travel user selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isLogin && isTravelUser) {
        _generateTravelIdForPreview();
      }
    });
  }
  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
  void _toggleMode() {
    setState(() {
      isLogin = !isLogin;
      // Reset travel ID when switching modes
      _generatedTravelId = null;
    });
    _animationController.reset();
    _animationController.forward();
    
    // Generate Travel ID if switching to register mode and travel user is selected
    if (!isLogin && isTravelUser) {
      _generateTravelIdForPreview();
    }
  }

  void _toggleUserType(bool isTravelSelected) {
    setState(() {
      isTravelUser = isTravelSelected;
      // Reset travel ID when switching user types
      if (!isTravelSelected) {
        _generatedTravelId = null;
      }
    });
    
    // Generate Travel ID if switching to travel user and in register mode
    if (isTravelSelected && !isLogin) {
      _generateTravelIdForPreview();
    }
  }

  Future<void> _generateTravelIdForPreview() async {
    if (_generatedTravelId != null) return; // Already generated
    
    setState(() {
      _isGeneratingTravelId = true;
    });

    try {
      final travelId = await _generateNextTravelId();
      setState(() {
        _generatedTravelId = travelId;
        _isGeneratingTravelId = false;
      });
    } catch (e) {
      setState(() {
        _isGeneratingTravelId = false;
      });
      // Don't show error here, will handle it during registration
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Login with Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Get user data from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String userType = userData['userType'] ?? '';

        // For travel users, check appStatus for verification
        if (userType == 'travel') {
          String appStatus = userData['appStatus'] ?? '';
          
          if (appStatus != 'verified') {
            // Block access for unverified travel accounts
            _showErrorDialog('Akun Anda belum terverifikasi oleh admin. Silakan tunggu proses verifikasi.');
            await SessionManager.logout(); // Clear session and sign out
            
            // Navigate to unverified account page
            Navigator.of(context).pushReplacementNamed('/unverified_account');
            return;
          }
        }

        // Save session data with 24-hour expiration
        await SessionManager.saveLoginSession(
          userId: userCredential.user!.uid,
          userType: userType,
          email: userData['email'] ?? userCredential.user!.email ?? '',
          name: userData['name'] ?? userCredential.user!.displayName ?? '',
          travelId: userData['travelId'],
        );

        // Navigate to the appropriate dashboard based on user type
        if (userType == 'travel') {
          Navigator.of(context).pushReplacementNamed('/kelola_jamaah');
        } else if (userType == 'jamaah') {
          Navigator.of(context).pushReplacementNamed('/jamaah/home');
        } else {
          _showErrorDialog('Invalid user type');
          await SessionManager.logout(); // Clear session and sign out
        }
      } else {
        _showErrorDialog('User data not found');
        await SessionManager.logout(); // Clear session and sign out
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getAuthErrorMessage(e.code);
      _showErrorDialog(errorMessage);
    } catch (e) {
      _showErrorDialog('An unexpected error occurred: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  Future<bool> _isTravelIdUnique(String travelId) async {
    final QuerySnapshot result = await _firestore
        .collection('users')
        .where('travelId', isEqualTo: travelId)
        .limit(1)
        .get();
    
    return result.docs.isEmpty;
  }
  Future<String> _generateNextTravelId() async {
    try {
      // Get all travel users - simpler query that doesn't require composite index
      final QuerySnapshot result = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'travel')
          .get();
      
      // Extract existing numbers and find the highest one
      int highestNumber = 10; // Start from BS811 (11-1 = 10)
      
      for (var doc in result.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final travelId = data['travelId'] as String?;
        
        // Check if it matches BS8xx pattern
        if (travelId != null && 
            travelId.startsWith('BS8') && 
            travelId.length == 5) {
          final numberPart = travelId.substring(3); // Get the last 2 digits
          final number = int.tryParse(numberPart);
          if (number != null && number > highestNumber) {
            highestNumber = number;
          }
        }
      }
      
      // Generate next Travel ID
      final nextNumber = highestNumber + 1;
      final nextTravelId = 'BS8${nextNumber.toString().padLeft(2, '0')}';
      
      // Ensure it doesn't exceed BS899
      if (nextNumber > 99) {
        throw Exception('Travel ID limit reached. Maximum is BS899.');
      }
      
      return nextTravelId;
    } catch (e) {
      throw Exception('Error generating Travel ID: $e');
    }
  }Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      String? generatedTravelId;
      
      // Use pre-generated Travel ID for travel users, or generate new one if not available
      if (isTravelUser) {
        try {
          generatedTravelId = _generatedTravelId ?? await _generateNextTravelId();
        } catch (e) {
          _showErrorDialog('Failed to generate Travel ID: $e');
          setState(() {
            isLoading = false;
          });
          return;
        }
      }

      // Create user with Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Update display name
      await userCredential.user!.updateDisplayName(_nameController.text.trim());

      // Prepare user data
      final Map<String, dynamic> userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'userType': isTravelUser ? 'travel' : 'jamaah',
        'createdAt': FieldValue.serverTimestamp(),
        'uid': userCredential.user!.uid,
      };
        // Add travel ID for travel users (but keep registration status as incomplete)
      if (isTravelUser && generatedTravelId != null) {
        userData['travelId'] = generatedTravelId;
        userData['registrationStatus'] = 'incomplete'; // They need to complete full registration
        userData['appStatus'] = 'pending'; // Set initial status to pending verification
      }

      // Save user data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);      // For travel users, redirect to travel registration form
      if (isTravelUser) {
        _showSuccessDialog('Akun berhasil dibuat!\n\nTravel ID Anda: $generatedTravelId\n\nSilakan lengkapi registrasi travel Anda.');
          // Clear form and navigate to travel registration
        _emailController.clear();
        _passwordController.clear();
        _nameController.clear();
        _generatedTravelId = null; // Reset generated travel ID
        
        // Navigate to travel registration page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const TravelRegistrationPage()),
        );      } else {
        _showSuccessDialog('Registrasi berhasil! Silakan login.');
        
        // Clear form and switch to login mode
        _emailController.clear();
        _passwordController.clear();
        _nameController.clear();
        _generatedTravelId = null; // Reset generated travel ID
        _toggleMode();
      }
      
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getAuthErrorMessage(e.code);
      _showErrorDialog(errorMessage);
    } catch (e) {
      _showErrorDialog('An unexpected error occurred: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  void _handleSubmit() {
    if (isLogin) {
      _handleLogin();
    } else {
      _handleRegister();
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A), // Dark blue
              Color(0xFF3B82F6), // Medium blue
              Color(0xFF60A5FA), // Light blue
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                           MediaQuery.of(context).padding.top,
              ),
              child: Column(
                children: [
                  // Header with logo
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.25,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'TravelApp',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'by ${isTravelUser ? 'Travel' : 'Jamaah'} Service',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Main content area
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.75,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // User type selector
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _toggleUserType(true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isTravelUser ? const Color(0xFF3B82F6) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                        child: Text(
                                          'User Travel',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: isTravelUser ? Colors.white : Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _toggleUserType(false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: !isTravelUser ? const Color(0xFF3B82F6) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                        child: Text(
                                          'User Jamaah',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: !isTravelUser ? Colors.white : Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Login/Register toggle
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (!isLogin) _toggleMode();
                                  },
                                  child: Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: isLogin ? FontWeight.w600 : FontWeight.w400,
                                      color: isLogin ? const Color(0xFF3B82F6) : Colors.grey[600],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 32),
                                GestureDetector(
                                  onTap: () {
                                    if (isLogin) _toggleMode();
                                  },
                                  child: Text(
                                    'Register',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: !isLogin ? FontWeight.w600 : FontWeight.w400,
                                      color: !isLogin ? const Color(0xFF3B82F6) : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Form fields
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Column(
                                children: [
                                  // Email field
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: _validateEmail,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF3B82F6)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.red, width: 1),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                    // Name field (only for register)
                                  if (!isLogin) ...[
                                    TextFormField(
                                      controller: _nameController,
                                      validator: _validateName,
                                      decoration: InputDecoration(
                                        labelText: 'Nama',
                                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF3B82F6)),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Colors.red, width: 1),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                      // Travel ID info (only for travel users in register mode)
                                    if (isTravelUser) ...[
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFF3B82F6), width: 1),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.card_membership, color: Color(0xFF3B82F6)),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [                                                      const Text(
                                                        'Travel ID Anda',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          color: Color(0xFF3B82F6),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      if (_isGeneratingTravelId)
                                                        const Text(
                                                          'Auto-generated dengan id [generating...]',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Color(0xFF1E40AF),
                                                          ),
                                                        )
                                                      else if (_generatedTravelId != null)
                                                        Text(
                                                          'Auto-generated dengan id $_generatedTravelId',
                                                          style: const TextStyle(
                                                            fontSize: 13,
                                                            color: Color(0xFF1E40AF),
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        )
                                                      else
                                                        const Text(
                                                          'Auto-generated dengan id [akan dibuat]',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Color(0xFF1E40AF),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (_generatedTravelId != null) ...[
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.green[50],
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.green[300]!, width: 1),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.check_circle_outline, size: 16, color: Colors.green[600]),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        'Travel ID ini akan digunakan untuk registrasi Anda',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.green[700],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ],
                                  
                                  // Password field
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: !isPasswordVisible,
                                    validator: _validatePassword,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF3B82F6)),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            isPasswordVisible = !isPasswordVisible;
                                          });
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.red, width: 1),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 24),
  
                                  // Submit button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : _handleSubmit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF3B82F6),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              isLogin ? 'Login' : 'Register',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Toggle text
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        isLogin ? 'Belum punya akun? ' : 'Sudah punya akun? ',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                      GestureDetector(
                                        onTap: _toggleMode,
                                        child: Text(
                                          isLogin ? 'Register' : 'Login',
                                          style: const TextStyle(
                                            color: Color(0xFF3B82F6),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Enhanced Admin Home Page with user info
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Home'),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // Navigation will be handled by AuthWrapper
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome, Admin!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Email: ${user?.email ?? 'N/A'}'),
                    Text('Name: ${user?.displayName ?? 'N/A'}'),
                    const Text('User Type: Travel Admin'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Admin Dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                children: [
                  _buildDashboardCard('Manage Users', Icons.people, () {}),
                  _buildDashboardCard('Travel Packages', Icons.flight, () {}),
                  _buildDashboardCard('Bookings', Icons.book, () {}),
                  _buildDashboardCard('Reports', Icons.assessment, () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: const Color(0xFF3B82F6)),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Enhanced Warga Home Page with user info
class WargaHomePage extends StatelessWidget {
  const WargaHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jamaah Home'),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // Navigation will be handled by AuthWrapper
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome, Jamaah!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Email: ${user?.email ?? 'N/A'}'),
                    Text('Name: ${user?.displayName ?? 'N/A'}'),
                    const Text('User Type: Jamaah'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Jamaah Dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                children: [
                  _buildDashboardCard('Browse Packages', Icons.search, () {}),
                  _buildDashboardCard('My Bookings', Icons.bookmark, () {}),
                  _buildDashboardCard('Profile', Icons.person, () {}),
                  _buildDashboardCard('Support', Icons.help, () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: const Color(0xFF3B82F6)),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
