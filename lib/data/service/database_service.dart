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
    String? reporterName, // Nama pelapor
    String? imageBase64, // Teks Base64 dari foto barang
    GeoPoint? geo, // Titik koordinat tepat dari peta UNESA Magetan
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
        'reporterName': reporterName ?? reporterNim, // Simpan nama pelapor
        'imageBase64': imageBase64 ?? '', // Simpan teks panjang fotonya di sini
        if (geo != null) 'geo': geo, // Koordinat presisi (opsional)
        'status': 'Open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Buat notifikasi otomatis untuk admin
      try {
        final String tipe = isLost ? 'hilang' : 'temuan';
        await _db.collection('admin_notifications').add({
          'title': 'Laporan Baru ($tipe)',
          'body': '$title - dilaporkan oleh ${reporterName ?? reporterNim}',
          'type': 'new_report',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // Abaikan error notifikasi agar tidak mengganggu laporan utama
      }
    } catch (e) {
      throw Exception('Gagal menyimpan ke database: $e');
    }
  }
}