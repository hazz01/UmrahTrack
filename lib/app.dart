import 'package:flutter/material.dart';
import 'presentation/routes/app_routes.dart';

class SatuRTApp extends StatelessWidget {
  const SatuRTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SatuRT',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRoutes.generateRoute,
      initialRoute: '/admin/home',
    );
  }
}
