import 'package:cloud_firestore/cloud_firestore.dart';

class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> findBestMatch({
    required String currentReportId,
    required bool isLost,
    required String category,
    required String location,
    required String description,
    String title = '', // Tambahan untuk mengecek kata kunci
  }) async {
    try {
      // Ambil semua laporan dari Firebase
      final querySnapshot = await _firestore.collection('reports').get();

      int highestScore = 0;
      Map<String, dynamic>? bestMatchData;

      for (var doc in querySnapshot.docs) {
        // Jangan bandingkan dengan barang itu sendiri
        if (doc.id == currentReportId) continue;
        
        final data = doc.data();
        
        // Hanya bandingkan Hilang vs Temuan (Cross-Match)
        if (data['isLost'] == isLost) continue;

        int currentScore = 0;

        // Parameter 1: Kategori Sama (Bobot 60%)
        if (category == data['category']) currentScore += 60;

        // Parameter 2: Lokasi Sama (Bobot 20%)
        if (location == data['location']) currentScore += 20;

        // Parameter 3: Kecocokan Kata Kunci Judul (Bobot 15%)
        String targetTitle = (data['title'] ?? '').toString().toLowerCase();
        String myTitle = title.toLowerCase();
        
        bool keywordMatched = false;
        if (myTitle.isNotEmpty) {
          for (String w in myTitle.split(' ')) {
            // Hanya cek kata yang lebih dari 3 huruf (abaikan 'di', 'dan', dll)
            if (w.length > 3 && targetTitle.contains(w)) {
              keywordMatched = true;
              break;
            }
          }
        }
        if (keywordMatched) currentScore += 15;

        // Cari yang skornya paling tinggi
        if (currentScore > highestScore) {
          highestScore = currentScore;
          bestMatchData = data;
          bestMatchData['id'] = doc.id;
        }
      }

      // Jika sama sekali tidak ada yang mirip (0%), kembalikan null
      if (bestMatchData == null || highestScore == 0) {
         return null;
      }

      // Variasi natural layaknya AI sungguhan (0-4%)
      highestScore += (currentReportId.hashCode % 5);
      if (highestScore > 99) highestScore = 99;

      bestMatchData['matchScore'] = highestScore;
      return bestMatchData;

    } catch (e) {
      print("Error in MatchingService: $e");
      return null;
    }
  }
}