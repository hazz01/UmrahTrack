import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rombongan_model.dart';

class RombonganService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  static CollectionReference get _rombonganCollection =>
      _firestore.collection('rombongan');
  
  static CollectionReference get _usersCollection =>
      _firestore.collection('users');

  // Create new rombongan
  static Future<String> createRombongan(Rombongan rombongan) async {
    try {
      final docRef = await _rombonganCollection.add(rombongan.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create rombongan: $e');
    }
  }

  // Get all rombongan for a travel ID
  static Stream<List<Rombongan>> getRombonganByTravelId(String travelId) {
    return _rombonganCollection
        .where('travelId', isEqualTo: travelId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Rombongan.fromFirestore(doc))
            .toList());
  }

  // Get single rombongan by ID
  static Future<Rombongan?> getRombonganById(String rombonganId) async {
    try {
      final doc = await _rombonganCollection.doc(rombonganId).get();
      if (doc.exists) {
        return Rombongan.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get rombongan: $e');
    }
  }

  // Update rombongan
  static Future<void> updateRombongan(String rombonganId, Map<String, dynamic> updates) async {
    try {
      // Add updatedAt timestamp
      updates['updatedAt'] = FieldValue.serverTimestamp();
      
      await _rombonganCollection.doc(rombonganId).update(updates);
    } catch (e) {
      throw Exception('Failed to update rombongan: $e');
    }
  }

  // Delete rombongan
  static Future<void> deleteRombongan(String rombonganId) async {
    try {
      // First check if there are jamaah in this rombongan
      final jamaahCount = await getJamaahCountInRombongan(rombonganId);
      if (jamaahCount > 0) {
        throw Exception('Cannot delete rombongan with jamaah members. Please move or remove all jamaah first.');
      }

      await _rombonganCollection.doc(rombonganId).delete();
    } catch (e) {
      throw Exception('Failed to delete rombongan: $e');
    }
  }

  // Get jamaah count in a rombongan
  static Future<int> getJamaahCountInRombongan(String rombonganId) async {
    try {
      final jamaahQuery = await _usersCollection
          .where('userType', isEqualTo: 'jamaah')
          .where('rombonganId', isEqualTo: rombonganId)
          .get();
      
      return jamaahQuery.docs.length;
    } catch (e) {
      throw Exception('Failed to get jamaah count: $e');
    }
  }

  // Assign jamaah to rombongan
  static Future<void> assignJamaahToRombongan(String jamaahId, String rombonganId) async {
    try {
      final batch = _firestore.batch();

      // Update jamaah document
      batch.update(_usersCollection.doc(jamaahId), {
        'rombonganId': rombonganId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update rombongan jamaah count
      final rombongan = await getRombonganById(rombonganId);
      if (rombongan != null) {
        final newCount = rombongan.jumlahJamaah + 1;
        batch.update(_rombonganCollection.doc(rombonganId), {
          'jumlahJamaah': newCount,
          'status': newCount >= rombongan.kapasitas ? 'full' : 'active',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to assign jamaah to rombongan: $e');
    }
  }

  // Remove jamaah from rombongan
  static Future<void> removeJamaahFromRombongan(String jamaahId, String rombonganId) async {
    try {
      final batch = _firestore.batch();

      // Update jamaah document
      batch.update(_usersCollection.doc(jamaahId), {
        'rombonganId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update rombongan jamaah count
      final rombongan = await getRombonganById(rombonganId);
      if (rombongan != null) {
        final newCount = (rombongan.jumlahJamaah - 1).clamp(0, rombongan.kapasitas);
        batch.update(_rombonganCollection.doc(rombonganId), {
          'jumlahJamaah': newCount,
          'status': newCount < rombongan.kapasitas ? 'active' : 'full',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to remove jamaah from rombongan: $e');
    }
  }

  // Get jamaah in a specific rombongan
  static Stream<List<Map<String, dynamic>>> getJamaahInRombongan(String rombonganId) {
    return _usersCollection
        .where('userType', isEqualTo: 'jamaah')
        .where('rombonganId', isEqualTo: rombonganId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList());
  }

  // Get jamaah without rombongan for a travel ID
  static Stream<List<Map<String, dynamic>>> getJamaahWithoutRombongan(String travelId) {
    return _usersCollection
        .where('userType', isEqualTo: 'jamaah')
        .where('travelId', isEqualTo: travelId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return !data.containsKey('rombonganId') || data['rombonganId'] == null;
            })
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList());
  }

  // Update rombongan capacities after jamaah changes
  static Future<void> updateRombonganCapacities(String travelId) async {
    try {
      final rombonganSnapshot = await _rombonganCollection
          .where('travelId', isEqualTo: travelId)
          .get();

      final batch = _firestore.batch();

      for (var rombonganDoc in rombonganSnapshot.docs) {
        final rombonganId = rombonganDoc.id;
        final rombongan = Rombongan.fromFirestore(rombonganDoc);
        
        // Count actual jamaah in this rombongan
        final actualCount = await getJamaahCountInRombongan(rombonganId);
        
        // Update if different
        if (actualCount != rombongan.jumlahJamaah) {
          batch.update(_rombonganCollection.doc(rombonganId), {
            'jumlahJamaah': actualCount,
            'status': actualCount >= rombongan.kapasitas ? 'full' : 'active',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update rombongan capacities: $e');
    }
  }

  // Validate rombongan data
  static String? validateRombonganData({
    required String namaRombongan,
    required String travelId,
    required int kapasitas,
    required DateTime tanggalBerangkat,
  }) {
    if (namaRombongan.trim().isEmpty) {
      return 'Nama rombongan tidak boleh kosong';
    }
    
    if (travelId.trim().isEmpty) {
      return 'Travel ID tidak valid';
    }
    
    if (kapasitas <= 0) {
      return 'Kapasitas harus lebih dari 0';
    }
    
    if (tanggalBerangkat.isBefore(DateTime.now())) {
      return 'Tanggal berangkat tidak boleh di masa lalu';
    }
    
    return null; // No errors
  }

  // Get rombongan statistics for a travel
  static Future<Map<String, dynamic>> getRombonganStats(String travelId) async {
    try {
      final rombonganSnapshot = await _rombonganCollection
          .where('travelId', isEqualTo: travelId)
          .get();

      int totalRombongan = rombonganSnapshot.docs.length;
      int totalKapasitas = 0;
      int totalJamaah = 0;
      int activeRombongan = 0;
      int fullRombongan = 0;

      for (var doc in rombonganSnapshot.docs) {
        final rombongan = Rombongan.fromFirestore(doc);
        totalKapasitas += rombongan.kapasitas;
        totalJamaah += rombongan.jumlahJamaah;
        
        if (rombongan.status == 'active') activeRombongan++;
        if (rombongan.status == 'full') fullRombongan++;
      }

      return {
        'totalRombongan': totalRombongan,
        'totalKapasitas': totalKapasitas,
        'totalJamaah': totalJamaah,
        'activeRombongan': activeRombongan,
        'fullRombongan': fullRombongan,
        'sisaKapasitas': totalKapasitas - totalJamaah,
      };
    } catch (e) {
      throw Exception('Failed to get rombongan stats: $e');
    }
  }
}
