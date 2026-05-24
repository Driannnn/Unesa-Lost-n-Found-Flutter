import 'package:cloud_firestore/cloud_firestore.dart';

class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Daftar kata umum yang diabaikan saat matching keyword
  static const _stopWords = {
    'di', 'dan', 'yang', 'ini', 'itu', 'ada', 'dari', 'untuk',
    'dengan', 'ke', 'pada', 'saya', 'satu', 'warna', 'biru',
    'hitam', 'putih', 'merah', 'kuning', 'hijau', 'the', 'a',
    'tidak', 'bisa', 'sudah', 'belum', 'akan', 'lagi', 'juga',
    'atau', 'jika', 'mau', 'seperti', 'sekitar', 'kira',
  };

  /// Hitung berapa kata yang cocok antara 2 string
  static int _countKeywordMatches(String source, String target) {
    if (source.isEmpty || target.isEmpty) return 0;
    int matches = 0;
    for (String w in source.toLowerCase().split(RegExp(r'\s+'))) {
      if (w.length <= 2 || _stopWords.contains(w)) continue;
      if (target.toLowerCase().contains(w)) {
        matches++;
      }
    }
    return matches;
  }

  /// Hitung total kata bermakna (bukan stopword, bukan terlalu pendek)
  static int _countMeaningfulWords(String text) {
    if (text.isEmpty) return 0;
    int count = 0;
    for (String w in text.toLowerCase().split(RegExp(r'\s+'))) {
      if (w.length <= 2 || _stopWords.contains(w)) continue;
      count++;
    }
    return count;
  }

  Future<Map<String, dynamic>?> findBestMatch({
    required String currentReportId,
    required bool isLost,
    required String category,
    required String location,
    required String description,
    String title = '',
  }) async {
    try {
      final querySnapshot = await _firestore.collection('reports').get();

      int highestScore = 0;
      Map<String, dynamic>? bestMatchData;

      for (var doc in querySnapshot.docs) {
        // Jangan bandingkan dengan barang itu sendiri
        if (doc.id == currentReportId) continue;

        final data = doc.data();

        // Hanya bandingkan Hilang vs Temuan (Cross-Match)
        if (data['isLost'] == isLost) continue;

        // ═══════════════════════════════════════════════════
        // MANDATORY 1: Kategori HARUS sama
        // ═══════════════════════════════════════════════════
        if (category != data['category']) continue;

        String targetTitle = (data['title'] ?? '').toString();
        String targetDesc = (data['description'] ?? '').toString();

        // Hitung keyword matches di judul dan deskripsi
        int titleMatches = _countKeywordMatches(title, targetTitle);
        int descMatches = _countKeywordMatches(description, targetDesc);
        int totalKeywordMatches = titleMatches + descMatches;

        // ═══════════════════════════════════════════════════
        // MANDATORY 2: HARUS ada minimal 1 keyword yang cocok
        // di judul ATAU deskripsi. Ini mencegah barang yang
        // cuma kebetulan kategori & lokasi sama tapi beda total
        // (misal TWS vs Ikan di kategori "Lainnya")
        // ═══════════════════════════════════════════════════
        if (totalKeywordMatches == 0) continue;

        int currentScore = 0;

        // Parameter 1: Lokasi Sama (Bobot 30%)
        if (location.isNotEmpty &&
            location.toLowerCase() == (data['location'] ?? '').toString().toLowerCase()) {
          currentScore += 30;
        }

        // Parameter 2: Kecocokan Kata Kunci Judul (Bobot 40%)
        int titleTotal = _countMeaningfulWords(title);
        if (titleTotal > 0) {
          double ratio = titleMatches / titleTotal;
          currentScore += (ratio * 40).round();
        }

        // Parameter 3: Kecocokan Kata Kunci Deskripsi (Bobot 30%)
        int descTotal = _countMeaningfulWords(description);
        if (descTotal > 0) {
          double ratio = descMatches / descTotal;
          currentScore += (ratio * 30).round();
        }

        // Cari yang skornya paling tinggi
        if (currentScore > highestScore) {
          highestScore = currentScore;
          bestMatchData = Map<String, dynamic>.from(data);
          bestMatchData['id'] = doc.id;
        }
      }

      // Minimum threshold 25% — jika di bawah, anggap tidak ada match
      if (bestMatchData == null || highestScore < 25) {
        return null;
      }

      // Variasi natural (0-4%) agar tidak selalu bulat
      highestScore += (currentReportId.hashCode % 5).abs();
      if (highestScore > 99) highestScore = 99;

      bestMatchData['matchScore'] = highestScore;
      return bestMatchData;
    } catch (e) {
      print("Error in MatchingService: $e");
      return null;
    }
  }
}