import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:umrahtrack/providers/auth_provider.dart';
import 'app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); 
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const SatuRTApp(),
    ),
  );
}
