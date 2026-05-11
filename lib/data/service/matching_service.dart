import 'package:cloud_firestore/cloud_firestore.dart';

class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fungsi utama untuk mencari kecocokan tertinggi
  Future<Map<String, dynamic>?> findBestMatch({
    required String currentReportId,
    required bool isLost,
    required String category,
    required String location,
    required String description,
  }) async {
    try {
      // 1. Ambil semua data yang statusnya berlawanan (Hilang vs Temuan)
      // Jika yang dibuka adalah barang Hilang (isLost = true), cari barang Temuan (isLost = false)
      final querySnapshot = await _firestore
          .collection('reports')
          .where('isLost', isEqualTo: !isLost)
          .where('status', isEqualTo: 'Open') // Hanya cari yang belum diklaim
          .get();

      final docs = querySnapshot.docs;

      if (docs.isEmpty) return null;

      Map<String, dynamic>? bestMatchData;
      int highestScore = 0;
      String bestMatchId = '';

      // 2. Mulai Proses Penilaian (Scoring) untuk setiap barang
      for (var doc in docs) {
        final data = doc.data();
        int currentScore = 0;

        // A. Cek Kategori (Bobot 40%)
        final targetCategory = data['category'] ?? '';
        if (targetCategory == category) {
          currentScore += 40;
        }

        // B. Cek Lokasi (Bobot 30%)
        final targetLocation = data['location'] ?? '';
        if (targetLocation == location) {
          currentScore += 30;
        }

        // C. Cek Kemiripan Deskripsi (Bobot 30%)
        // Memecah kalimat menjadi kata-kata (huruf kecil semua)
        final sourceWords = description.toLowerCase().split(' ');
        final targetWords = (data['description'] ?? '')
            .toString()
            .toLowerCase()
            .split(' ');

        int matchWordsCount = 0;
        for (var word in sourceWords) {
          // Abaikan kata hubung yang tidak penting
          if (word.length > 2 && targetWords.contains(word)) {
            matchWordsCount++;
          }
        }

        // Jika ada 1 kata penting yang sama, tambah 15%. Jika lebih dari 1, tambah 30%.
        if (matchWordsCount == 1) currentScore += 15;
        if (matchWordsCount > 1) currentScore += 30;

        // 3. Update data jika skor ini adalah yang tertinggi sejauh ini
        if (currentScore > highestScore) {
          highestScore = currentScore;
          bestMatchData = data;
          bestMatchId = doc.id;
        }
      }

      // 4. Kembalikan data hanya jika skor kecocokannya meyakinkan (minimal 40%)
      if (highestScore >= 40 && bestMatchData != null) {
        bestMatchData['matchScore'] = highestScore;
        bestMatchData['id'] = bestMatchId;
        return bestMatchData;
      }

      return null; // Tidak ada yang cukup mirip
    } catch (e) {
      print('Error AI Matching: $e');
      return null;
    }
  }
}
