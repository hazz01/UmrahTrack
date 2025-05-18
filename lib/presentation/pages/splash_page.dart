import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      final user = context.read<AuthProvider>().currentUser;

      if (user == null) {
        Navigator.pushReplacementNamed(context, '/login');
      } else if (user.role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin/home');
      } else {
        Navigator.pushReplacementNamed(context, '/warga/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("SatuRT Loading...")),
    );
  }
}
