import 'package:flutter/material.dart';
import '../../data/services/user_verification_service.dart';

class VerificationStatusWidget extends StatelessWidget {
  const VerificationStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: UserVerificationService.getCurrentUserVerificationStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final isVerified = snapshot.data ?? false;

        if (!isVerified) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.pending,
                  color: Colors.orange,
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Akun Menunggu Verifikasi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Akun Anda sedang dalam proses verifikasi oleh tim kami. Anda akan mendapat notifikasi setelah verifikasi selesai.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Refresh or navigate to help
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Hubungi Support'),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.verified,
                color: Colors.green,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Akun Terverifikasi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class VerificationGuard extends StatelessWidget {
  final Widget child;
  final Widget? unverifiedWidget;
  
  const VerificationGuard({
    super.key,
    required this.child,
    this.unverifiedWidget,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: UserVerificationService.isCurrentUserVerified(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final isVerified = snapshot.data ?? false;

        if (!isVerified) {
          return unverifiedWidget ?? 
            Scaffold(
              appBar: AppBar(
                title: const Text('Akses Terbatas'),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              body: const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock,
                        size: 80,
                        color: Colors.orange,
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Akun Belum Terverifikasi',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Silakan tunggu verifikasi dari admin untuk mengakses fitur ini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            );
        }

        return child;
      },
    );
  }
}
