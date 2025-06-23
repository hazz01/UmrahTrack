import 'package:cloud_firestore/cloud_firestore.dart';

class Rombongan {
  final String id;
  final String namaRombongan;
  final String deskripsi;
  final String travelId;
  final int kapasitas;
  final int jumlahJamaah;
  final String status; // 'active', 'inactive', 'full'
  final DateTime tanggalBerangkat;
  final DateTime? tanggalKembali;
  final String? guide;
  final String? kontak;
  final DateTime createdAt;
  final DateTime updatedAt;

  Rombongan({
    required this.id,
    required this.namaRombongan,
    required this.deskripsi,
    required this.travelId,
    required this.kapasitas,
    this.jumlahJamaah = 0,
    this.status = 'active',
    required this.tanggalBerangkat,
    this.tanggalKembali,
    this.guide,
    this.kontak,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor untuk membuat dari Firestore document
  factory Rombongan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Rombongan(
      id: doc.id,
      namaRombongan: data['namaRombongan'] ?? '',
      deskripsi: data['deskripsi'] ?? '',
      travelId: data['travelId'] ?? '',
      kapasitas: data['kapasitas'] ?? 0,
      jumlahJamaah: data['jumlahJamaah'] ?? 0,
      status: data['status'] ?? 'active',
      tanggalBerangkat: (data['tanggalBerangkat'] as Timestamp).toDate(),
      tanggalKembali: data['tanggalKembali'] != null 
          ? (data['tanggalKembali'] as Timestamp).toDate()
          : null,
      guide: data['guide'],
      kontak: data['kontak'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert ke Map untuk Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'namaRombongan': namaRombongan,
      'deskripsi': deskripsi,
      'travelId': travelId,
      'kapasitas': kapasitas,
      'jumlahJamaah': jumlahJamaah,
      'status': status,
      'tanggalBerangkat': Timestamp.fromDate(tanggalBerangkat),
      'tanggalKembali': tanggalKembali != null 
          ? Timestamp.fromDate(tanggalKembali!)
          : null,
      'guide': guide,
      'kontak': kontak,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Copy with untuk update
  Rombongan copyWith({
    String? id,
    String? namaRombongan,
    String? deskripsi,
    String? travelId,
    int? kapasitas,
    int? jumlahJamaah,
    String? status,
    DateTime? tanggalBerangkat,
    DateTime? tanggalKembali,
    String? guide,
    String? kontak,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Rombongan(
      id: id ?? this.id,
      namaRombongan: namaRombongan ?? this.namaRombongan,
      deskripsi: deskripsi ?? this.deskripsi,
      travelId: travelId ?? this.travelId,
      kapasitas: kapasitas ?? this.kapasitas,
      jumlahJamaah: jumlahJamaah ?? this.jumlahJamaah,
      status: status ?? this.status,
      tanggalBerangkat: tanggalBerangkat ?? this.tanggalBerangkat,
      tanggalKembali: tanggalKembali ?? this.tanggalKembali,
      guide: guide ?? this.guide,
      kontak: kontak ?? this.kontak,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isFull => jumlahJamaah >= kapasitas;
  bool get isActive => status == 'active';
  int get sisaKapasitas => kapasitas - jumlahJamaah;
  
  String get statusText {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'inactive':
        return 'Tidak Aktif';
      case 'full':
        return 'Penuh';
      default:
        return 'Unknown';
    }
  }
}
