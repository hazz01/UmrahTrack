import 'package:flutter/material.dart';
import 'package:umrahtrack/presentation/pages/admin/lokasi_person.dart';

import '../pages/admin/kelola_warga_page.dart';
import '../pages/login_page.dart';
import '../pages/splash_page.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/admin/home':
        return MaterialPageRoute(builder: (_) => const KelolaWargaPage());
      case '/admin/lokasi':
        return MaterialPageRoute(
            builder: (_) => const LocationPage());
      case '/warga/home':
        return MaterialPageRoute(
            builder: (_) => const Scaffold(
                  body: Center(child: Text('Home Warga (under development)')),
                ));

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}
