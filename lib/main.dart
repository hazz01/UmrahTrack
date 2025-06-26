import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:umrahtrack/providers/auth_provider.dart';
import 'package:umrahtrack/providers/location_provider.dart';
import 'package:umrahtrack/presentation/pages/login_page.dart';
import 'package:umrahtrack/presentation/pages/travel_registration_page.dart';
import 'package:umrahtrack/presentation/pages/admin/kelola_jamaah_page.dart';
import 'package:umrahtrack/presentation/pages/admin/kelola_rombongan_page.dart';
import 'package:umrahtrack/presentation/pages/admin/lokasi_person.dart';
import 'package:umrahtrack/presentation/pages/jamaah/jamaah_home.dart';
import 'package:umrahtrack/presentation/pages/jamaah/jamaah_lokasi.dart';
import 'package:umrahtrack/presentation/pages/unverified_account_page.dart';
import 'package:umrahtrack/test_geolocator.dart';
import 'package:umrahtrack/test_firebase_realtime.dart';
import 'package:umrahtrack/test_location_realtime_verification.dart';
import 'package:umrahtrack/test_firebase_connection.dart';
import 'package:umrahtrack/test_location_debug.dart';
import 'package:umrahtrack/simple_firebase_test.dart';
import 'package:umrahtrack/location_diagnostic_page.dart';
import 'package:umrahtrack/quick_rtdb_test.dart';
import 'package:umrahtrack/emergency_rtdb_test.dart';
import 'package:umrahtrack/database_region_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with duplicate app protection
  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized successfully');
    } else {
      print('✅ Firebase already initialized (${Firebase.apps.length} apps)');
    }
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      print('⚠️ Firebase already initialized (duplicate app caught)');
      // Firebase is already initialized, which is fine
    } else {
      print('❌ Firebase initialization error: $e');
      rethrow; // Re-throw if it's a different error
    }
  }
  
  // Initialize locale data for Indonesian date formatting
  await initializeDateFormatting('id_ID', null);
    runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: const UmrahTrackApp(),
    ),
  );
}

class UmrahTrackApp extends StatelessWidget {
  const UmrahTrackApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UmrahTrack',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1658B3),
          brightness: Brightness.light,
        ),
      ),
      // Start with SplashScreen instead of AuthWrapper
      home: const LoginPage(),routes: {
        '/login': (context) => LoginPage(),
        '/travel-registration': (context) => const TravelRegistrationPage(),
        '/kelola_jamaah': (context) => const KelolaWargaPage(),'/admin/home': (context) => const KelolaWargaPage(), // Main admin page
        '/admin/rombongan': (context) => const KelolaRombonganPage(),
        '/admin/lokasi': (context) => const LocationPage(),
        '/jamaah/home': (context) => const JamaahHomePage(),        '/jamaah/lokasi': (context) => const JamaahLokasiPage(),        '/unverified_account': (context) => const UnverifiedAccountPage(),        '/test-geolocator': (context) => const TestLocationPage(),
        '/test-firebase-realtime': (context) => const TestFirebaseRealtimePage(),
        '/test-location-verification': (context) => const TestLocationRealtimeVerificationPage(),
        '/test-firebase-connection': (context) => const TestFirebaseConnectionPage(),
        '/test-location-debug': (context) => const TestLocationDebugPage(),
        '/simple-firebase-test': (context) => const SimpleFirebaseTest(),
        '/location-diagnostic': (context) => const LocationDiagnosticPage(),        '/quick-rtdb-test': (context) => const QuickRTDBTest(),
        '/emergency-rtdb-test': (context) => const EmergencyRTDBTest(),
        '/database-region-test': (context) => const DatabaseRegionTest(),
      },onGenerateRoute: (RouteSettings settings) {
        // Handle specific missing admin routes 
        switch (settings.name) {          case '/admin/cctv':
            return MaterialPageRoute(
              builder: (context) => const KelolaRombonganPage(),
            );
          case '/admin/surat':
            return MaterialPageRoute(
              builder: (context) => _buildPlaceholderPage('Surat', 'Fitur Surat sedang dalam pengembangan'),
            );
          case '/admin/laporan':
            return MaterialPageRoute(
              builder: (context) => _buildPlaceholderPage('Laporan', 'Fitur Laporan sedang dalam pengembangan'),
            );
          case '/admin/keuangan':
            return MaterialPageRoute(
              builder: (context) => _buildPlaceholderPage('Keuangan', 'Fitur Keuangan sedang dalam pengembangan'),
            );
          default:
            // Handle any other undefined routes
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: const Text('Page Not Found'),
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Route "${settings.name}" not found',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                        child: const Text('Go to Login'),
                      ),
                    ],
                  ),
                ),
              ),
            );
        }
      },
      debugShowCheckedModeBanner: false,
    );
  }
    Widget _buildPlaceholderPage(String title, String message) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF1658B3),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Kembali'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
