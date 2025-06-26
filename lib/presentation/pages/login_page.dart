import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:umrahtrack/data/services/session_manager.dart';
import 'package:umrahtrack/presentation/pages/admin/kelola_jamaah_page.dart';
import 'package:umrahtrack/presentation/pages/jamaah/jamaah_home.dart';
import 'package:umrahtrack/presentation/pages/travel_registration_page.dart';
import 'package:umrahtrack/presentation/pages/unverified_account_page.dart';

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
            backgroundColor: Color(0xFF1658B3),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.mosque,
                      size: 60,
                      color: Color(0xFF1658B3),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'UmrahTrack',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Manajemen Perjalanan Umrah',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 40),
                  CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ],
              ),
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

    // Refresh session to extend for another 14 days
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
  late AnimationController _logoController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _logoAnimation;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    
    _logoController.forward();
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
    _logoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
    void _toggleMode() {
    // Jamaah users cannot register, only travel users can
    if (!isTravelUser) return;
    
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
        // Force login mode for jamaah users
        isLogin = true;
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Berhasil'),
            ],
          ),
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
          .get();
          
      if (userDoc.exists) {
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

        // Save session data with 14-day expiration
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
    try {
      final query = await _firestore
          .collection('users')
          .where('travelId', isEqualTo: travelId)
          .get();
      return query.docs.isEmpty;
    } catch (e) {
      print('Error checking travel ID uniqueness: $e');
      return false;
    }
  }

  Future<String> _generateNextTravelId() async {
    try {
      for (int i = 1; i <= 9999; i++) {
        String travelId = 'TR${i.toString().padLeft(2, '0')}';
        bool isUnique = await _isTravelIdUnique(travelId);
        if (isUnique) {
          return travelId;
        }
      }
      throw Exception('No available Travel ID found');
    } catch (e) {
      throw Exception('Failed to generate Travel ID: $e');
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      String? generatedTravelId;
      
      // Generate Travel ID for travel users
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
      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);
      
      // For travel users, redirect to travel registration form
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
        );
      } else {
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
        return 'Tidak ada pengguna dengan email tersebut.';
      case 'wrong-password':
        return 'Password yang dimasukkan salah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun pengguna ini telah dinonaktifkan.';
      case 'weak-password':
        return 'Password terlalu lemah.';
      case 'email-already-in-use':
        return 'Email sudah digunakan oleh akun lain.';
      case 'invalid-credential':
        return 'Email atau password tidak valid.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan gagal. Silakan coba lagi nanti.';
      default:
        return 'Autentikasi gagal. Silakan coba lagi.';
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
      return 'Silakan masukkan email Anda';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Silakan masukkan email yang valid';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Silakan masukkan password Anda';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }
  
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Silakan masukkan nama Anda';
    }
    if (value.trim().length < 2) {
      return 'Nama minimal 2 karakter';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1658B3), // Primary blue
              Color(0xFF0F4C81), // Darker blue
              Color(0xFF083F69), // Darkest blue
            ],
            stops: [0.0, 0.7, 1.0],
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
                  // Header with logo and app name
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.35,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _logoAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoAnimation.value,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // App Logo
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.mosque,
                                    size: 60,
                                    color: Color(0xFF1658B3),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                // App Name
                                const Text(
                                  'UmrahTrack',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Manajemen Perjalanan Umrah',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Main content area
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.65,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
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
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                decoration: BoxDecoration(
                                                  color: isTravelUser ? const Color(0xFF1658B3) : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(25),
                                                  boxShadow: isTravelUser ? [
                                                    BoxShadow(
                                                      color: const Color(0xFF1658B3).withOpacity(0.3),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ] : null,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.business,
                                                      color: isTravelUser ? Colors.white : Colors.grey[600],
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Travel',
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: isTravelUser ? Colors.white : Colors.grey[600],
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => _toggleUserType(false),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                decoration: BoxDecoration(
                                                  color: !isTravelUser ? const Color(0xFF1658B3) : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(25),
                                                  boxShadow: !isTravelUser ? [
                                                    BoxShadow(
                                                      color: const Color(0xFF1658B3).withOpacity(0.3),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ] : null,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.person,
                                                      color: !isTravelUser ? Colors.white : Colors.grey[600],
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Jamaah',
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: !isTravelUser ? Colors.white : Colors.grey[600],
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 16,
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
                                    
                                    const SizedBox(height: 40),
                                      // Login/Register toggle (only for travel users)
                                    if (isTravelUser) Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            if (!isLogin) _toggleMode();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: isLogin ? const Color(0xFF1658B3).withOpacity(0.1) : Colors.transparent,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'Masuk',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: isLogin ? FontWeight.w700 : FontWeight.w500,
                                                color: isLogin ? const Color(0xFF1658B3) : Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 40),
                                        GestureDetector(
                                          onTap: () {
                                            if (isLogin) _toggleMode();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: !isLogin ? const Color(0xFF1658B3).withOpacity(0.1) : Colors.transparent,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'Daftar',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: !isLogin ? FontWeight.w700 : FontWeight.w500,
                                                color: !isLogin ? const Color(0xFF1658B3) : Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 40),
                                    
                                    // Form fields
                                    Column(
                                      children: [
                                        // Email field
                                        Container(
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: TextFormField(
                                            controller: _emailController,
                                            keyboardType: TextInputType.emailAddress,
                                            validator: _validateEmail,
                                            decoration: InputDecoration(
                                              labelText: 'Email',
                                              hintText: 'Masukkan email Anda',
                                              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF1658B3)),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: BorderSide.none,
                                              ),
                                              filled: true,
                                              fillColor: Colors.grey[50],
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: const BorderSide(color: Color(0xFF1658B3), width: 2),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: const BorderSide(color: Colors.red, width: 1),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                            ),
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 20),
                                            // Name field (only for travel register)
                                        if (!isLogin && isTravelUser) ...[
                                          Container(
                                            decoration: BoxDecoration(
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.05),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: TextFormField(
                                              controller: _nameController,
                                              validator: _validateName,
                                              decoration: InputDecoration(
                                                labelText: 'Nama Lengkap',
                                                hintText: 'Masukkan nama lengkap Anda',
                                                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF1658B3)),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  borderSide: BorderSide.none,
                                                ),
                                                filled: true,
                                                fillColor: Colors.grey[50],
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  borderSide: const BorderSide(color: Color(0xFF1658B3), width: 2),
                                                ),
                                                errorBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  borderSide: const BorderSide(color: Colors.red, width: 1),
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                        ],
                                          // Travel ID info (only for travel users in register mode)
                                        if (isTravelUser && !isLogin) ...[
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1658B3).withOpacity(0.05),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: const Color(0xFF1658B3).withOpacity(0.2)),
                                            ),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.card_membership, color: Color(0xFF1658B3)),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          const Text(
                                                            'Travel ID Anda',
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.w700,
                                                              color: Color(0xFF1658B3),
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 4),
                                                          if (_isGeneratingTravelId)
                                                            const Text(
                                                              'Sedang membuat Travel ID...',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: Color(0xFF1658B3),
                                                              ),
                                                            )
                                                          else if (_generatedTravelId != null)
                                                            Text(
                                                              'ID: $_generatedTravelId',
                                                              style: const TextStyle(
                                                                fontSize: 18,
                                                                color: Color(0xFF1658B3),
                                                                fontWeight: FontWeight.bold,
                                                                letterSpacing: 2,
                                                              ),
                                                            )
                                                          else
                                                            const Text(
                                                              'Travel ID akan dibuat otomatis',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: Color(0xFF1658B3),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (_generatedTravelId != null) ...[
                                                  const SizedBox(height: 12),
                                                  Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green[50],
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: Colors.green[300]!, width: 1),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.check_circle_outline, size: 18, color: Colors.green[600]),
                                                        const SizedBox(width: 8),
                                                        const Expanded(
                                                          child: Text(
                                                            'Travel ID ini akan digunakan untuk registrasi Anda',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Color(0xFF2E7D32),
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
                                          const SizedBox(height: 20),
                                        ],
                                        
                                        // Password field
                                        Container(
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: TextFormField(
                                            controller: _passwordController,
                                            obscureText: !isPasswordVisible,
                                            validator: _validatePassword,
                                            decoration: InputDecoration(
                                              labelText: 'Password',
                                              hintText: 'Masukkan password Anda',
                                              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1658B3)),
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
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: BorderSide.none,
                                              ),
                                              filled: true,
                                              fillColor: Colors.grey[50],
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: const BorderSide(color: Color(0xFF1658B3), width: 2),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: const BorderSide(color: Colors.red, width: 1),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                            ),
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 32),
  
                                        // Submit button
                                        SizedBox(
                                          width: double.infinity,
                                          height: 56,
                                          child: ElevatedButton(
                                            onPressed: isLoading ? null : _handleSubmit,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF1658B3),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              elevation: 8,
                                              shadowColor: const Color(0xFF1658B3).withOpacity(0.3),
                                            ),
                                            child: isLoading
                                                ? const SizedBox(
                                                    height: 24,
                                                    width: 24,
                                                    child: CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : Text(
                                                    isLogin ? 'Masuk' : 'Daftar',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                          ),
                                        ),                                        
                                        const SizedBox(height: 32),
                                        
                                        // Session info
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.green[200]!),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.security, color: Colors.green[700], size: 20),
                                              const SizedBox(width: 12),                                              const Expanded(
                                                child: Text(
                                                  'Login Anda akan tersimpan selama 14 hari. Jika diperlukan, silakan login ulang.',
                                                  style: TextStyle(
                                                    color: Color(0xFF2E7D32),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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
