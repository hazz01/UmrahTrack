// File: jamaah_home_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class JamaahHomePage extends StatefulWidget {
  const JamaahHomePage({super.key});

  @override
  State<JamaahHomePage> createState() => _JamaahHomePageState();
}

class _JamaahHomePageState extends State<JamaahHomePage> {
  final user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  Map<String, dynamic>? travelData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users') // ✅ fixed: was 'user'
          .doc(user!.uid)
          .get();
      userData = doc.data();
      if (userData != null && userData!['travelId'] != null) {
        final travelQuery = await FirebaseFirestore.instance
            .collection('users') // ✅ fixed: was 'user'
            .where('userType', isEqualTo: 'travel')
            .where('travelId', isEqualTo: userData!['travelId'])
            .limit(1)
            .get();
        if (travelQuery.docs.isNotEmpty) {
          travelData = travelQuery.docs.first.data();
        }
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda Jamaah'),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null || userData!['travelId'] == null
              ? const InputTravelIDWidget()
              : InfoJamaahTravel(userData: userData!, travelData: travelData),
      bottomNavigationBar: BottomNavbarJamaah(currentIndex: 0, onTap: (i) {
        if (i == 1) Navigator.pushNamed(context, '/jamaah/lokasi');
      }),
    );
  }
}

class InputTravelIDWidget extends StatefulWidget {
  const InputTravelIDWidget({super.key});

  @override
  State<InputTravelIDWidget> createState() => _InputTravelIDWidgetState();
}

class _InputTravelIDWidgetState extends State<InputTravelIDWidget> {
  final _formKey = GlobalKey<FormState>();
  final _travelIDController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submitTravelID() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final travelID = _travelIDController.text.trim().toUpperCase();
    final query = await FirebaseFirestore.instance
        .collection('users') // ✅ fixed: was 'user'
        .where('userType', isEqualTo: 'travel')
        .where('travelId', isEqualTo: travelID)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Travel ID tidak ditemukan';
      });
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users') // ✅ fixed: was 'user'
        .doc(uid)
        .update({'travelId': travelID});

    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/jamaah/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Masukkan Travel ID Anda", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _travelIDController,
              maxLength: 4,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Travel ID (4 huruf)',
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.length != 4) return 'Travel ID harus 4 huruf';
                return null;
              },
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loading ? null : _submitTravelID,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoJamaahTravel extends StatelessWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic>? travelData;

  const InfoJamaahTravel({super.key, required this.userData, this.travelData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Nama: ${userData['name']}", style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 12),
          if (travelData != null) ...[
            Text("Travel: ${travelData!['name']}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text("Target Keberangkatan: 1 Juli 2025", style: const TextStyle(fontSize: 16)),
          ],
        ],
      ),
    );
  }
}

class BottomNavbarJamaah extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavbarJamaah({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Jamaah'),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Lokasi'),
        BottomNavigationBarItem(icon: Icon(Icons.warning), label: '[Upcoming]'),
        BottomNavigationBarItem(icon: Icon(Icons.warning), label: '[Upcoming]'),
        BottomNavigationBarItem(icon: Icon(Icons.warning), label: '[Upcoming]'),
      ],
    );
  }
}
