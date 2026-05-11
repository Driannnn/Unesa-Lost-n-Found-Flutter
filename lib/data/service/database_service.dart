import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> submitReport({
    required String title,
    required String description,
    required String category,
    required String location,
    required String date,
    required bool isLost,
    required String reporterNim,
    String? imageBase64, // <-- Sekarang kita menerima teks Base64, bukan file
  }) async {
    try {
      await _db.collection('reports').add({
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'date': date,
        'isLost': isLost,
        'reporterNim': reporterNim,
        'imageBase64': imageBase64 ?? '', // Simpan teks panjang fotonya di sini
        'status': 'Open',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal menyimpan ke database: $e');
    }
  }
}