// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';

// class JamaahLokasiPage extends StatefulWidget {
//   const JamaahLokasiPage({super.key});

//   @override
//   State<JamaahLokasiPage> createState() => _JamaahLokasiPageState();
// }

// class _JamaahLokasiPageState extends State<JamaahLokasiPage> {
//   String lokasi = "Belum tersedia";

//   Future<void> getLokasi() async {
//     LocationPermission permission = await Geolocator.requestPermission();
//     if (permission == LocationPermission.denied) return;

//     final pos = await Geolocator.getCurrentPosition();
//     setState(() {
//       lokasi = "Lat: ${pos.latitude}, Lng: ${pos.longitude}";
//     });
//   }

//   @override
//   void initState() {
//     super.initState();
//     getLokasi();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Lokasi Saya')),
//       body: Center(child: Text(lokasi)),
//     );
//   }
// }
