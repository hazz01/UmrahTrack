import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:umrahtrack/providers/auth_provider.dart';
import 'package:umrahtrack/providers/location_provider.dart';
import 'package:umrahtrack/presentation/pages/login_page.dart';
import 'package:umrahtrack/presentation/pages/travel_registration_page.dart';
import 'package:umrahtrack/presentation/pages/admin/kelola_jamaah_page.dart';
import 'package:umrahtrack/presentation/pages/admin/lokasi_person.dart';
import 'package:umrahtrack/presentation/pages/jamaah/jamaah_home.dart';
import 'package:umrahtrack/presentation/pages/jamaah/jamaah_lokasi.dart';
import 'package:umrahtrack/presentation/pages/unverified_account_page.dart';
import 'package:umrahtrack/test_geolocator.dart';
import 'package:umrahtrack/test_firebase_realtime.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
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
          seedColor: const  Color(0xFF1658B3),
          brightness: Brightness.light,
        ),
      ),      // Use AuthWrapper from login_page.dart to handle authentication state
      home: const AuthWrapper(),      routes: {
        '/login': (context) => const LoginPage(),
        '/travel-registration': (context) => const TravelRegistrationPage(),
        '/kelola_jamaah': (context) => const KelolaWargaPage(),
        '/admin/home': (context) => const KelolaWargaPage(), // Main admin page
        '/admin/lokasi': (context) => const LocationPage(),
        '/jamaah/home': (context) => const JamaahHomePage(),        '/jamaah/lokasi': (context) => const JamaahLokasiPage(),
        '/unverified_account': (context) => const UnverifiedAccountPage(),
        '/test-geolocator': (context) => const TestLocationPage(),
        '/test-firebase-realtime': (context) => const TestFirebaseRealtimePage(),
      },onGenerateRoute: (RouteSettings settings) {
        // Handle specific missing admin routes
        switch (settings.name) {
          case '/admin/cctv':
            return MaterialPageRoute(
              builder: (context) => _buildPlaceholderPage('Rombongan', 'Fitur sedang dalam pengembangan'),
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
