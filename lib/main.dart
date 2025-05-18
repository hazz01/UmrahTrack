import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:umrahtrack/providers/auth_provider.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const SatuRTApp(),
    ),
  );
}
