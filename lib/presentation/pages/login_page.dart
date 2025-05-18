import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:umrahtrack/providers/auth_provider.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Login SatuRT')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await authProvider.login('admin', 'password');
                Navigator.pushReplacementNamed(context, '/admin/home');
              },
              child: const Text('Login sebagai Admin'),
            ),
            ElevatedButton(
              onPressed: () async {
                await authProvider.login('warga', 'password');
                Navigator.pushReplacementNamed(context, '/warga/home');
              },
              child: const Text('Login sebagai Warga'),
            ),
          ],
        ),
      ),
    );
  }
}
