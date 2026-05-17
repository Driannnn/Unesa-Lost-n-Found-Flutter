import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ══════════════════════════════════════════════════════
  // AUTENTIKASI ADMIN
  // ══════════════════════════════════════════════════════

  /// Login admin: cek ke Firestore dulu, fallback ke akun demo statis
  Future<Map<String, String>?> loginAdmin(String username, String password) async {
    try {
      // 1. Cek di Firestore collection 'admin_users'
      final snapshot = await _db
          .collection('admin_users')
          .where('username', isEqualTo: username.toLowerCase())
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        return {
          'username': data['username'] ?? username,
          'role': data['role'] ?? 'Satpam',
          'name': data['name'] ?? username,
        };
      }
    } catch (e) {
      print('Firestore admin login error: $e');
    }

    // 2. Fallback ke akun demo statis jika Firestore kosong/error
    const accounts = [
      {'username': 'satpam', 'password': 'admin123', 'role': 'Satpam', 'name': 'A. Wibowo'},
      {'username': 'adminit', 'password': 'admin123', 'role': 'Admin IT', 'name': 'Admin IT'},
      {'username': 'koordinator', 'password': 'admin123', 'role': 'Koordinator Keamanan', 'name': 'Koordinator'},
    ];

    for (var acc in accounts) {
      if (acc['username'] == username.toLowerCase() && acc['password'] == password) {
        return {
          'username': acc['username']!,
          'role': acc['role']!,
          'name': acc['name']!,
        };
      }
    }

    return null; // Login gagal
  }

  // ══════════════════════════════════════════════════════
  // PENGUMUMAN (ANNOUNCEMENTS)
  // ══════════════════════════════════════════════════════

  /// Stream pengumuman dari Firestore, diurutkan berdasarkan pinned dan tanggal
  Stream<QuerySnapshot> getAnnouncementsStream() {
    return _db
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Buat pengumuman baru
  Future<void> createAnnouncement({
    required String title,
    required String body,
    required String type,
    required String author,
  }) async {
    await _db.collection('announcements').add({
      'title': title,
      'body': body,
      'type': type,
      'author': author,
      'pinned': false,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Toggle pin/unpin pengumuman
  Future<void> togglePin(String docId, bool currentPinned) async {
    await _db.collection('announcements').doc(docId).update({
      'pinned': !currentPinned,
    });
  }

  /// Toggle aktif/nonaktif pengumuman
  Future<void> toggleActive(String docId, bool currentActive) async {
    await _db.collection('announcements').doc(docId).update({
      'active': !currentActive,
    });
  }

  /// Hapus pengumuman
  Future<void> deleteAnnouncement(String docId) async {
    await _db.collection('announcements').doc(docId).delete();
  }

  /// Seed data pengumuman default jika collection kosong
  Future<void> seedDefaultAnnouncements(String authorName) async {
    final snapshot = await _db.collection('announcements').limit(1).get();
    if (snapshot.docs.isNotEmpty) return; // Sudah ada data

    final defaults = [
      {
        'title': 'Penemuan Dompet di Perpustakaan',
        'body': 'Telah ditemukan sebuah dompet warna hitam di area perpustakaan lantai 1.',
        'type': 'found',
        'author': authorName,
        'pinned': true,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Zona Rawan Kehilangan: Kantin',
        'body': 'Tingkat kehilangan barang di area kantin meningkat minggu ini.',
        'type': 'warning',
        'author': 'Admin IT',
        'pinned': true,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Prosedur Pengambilan Barang',
        'body': 'Pengambilan barang hilang wajib disertai KTM asli dan deskripsi barang.',
        'type': 'info',
        'author': 'Koordinator',
        'pinned': false,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (var ann in defaults) {
      await _db.collection('announcements').add(ann);
    }
  }

  // ══════════════════════════════════════════════════════
  // NOTIFIKASI ADMIN
  // ══════════════════════════════════════════════════════

  /// Stream notifikasi admin
  Stream<QuerySnapshot> getNotificationsStream() {
    return _db
        .collection('admin_notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Hitung notifikasi yang belum dibaca
  Stream<QuerySnapshot> getUnreadNotificationsStream() {
    return _db
        .collection('admin_notifications')
        .snapshots();
  }

  /// Hitung unread dari snapshot lokal (tidak perlu composite index)
  int countUnread(QuerySnapshot snapshot) {
    return snapshot.docs.where((d) => (d.data() as Map<String, dynamic>)['read'] == false).length;
  }

  /// Tandai notifikasi sebagai sudah dibaca
  Future<void> markNotificationRead(String docId) async {
    await _db.collection('admin_notifications').doc(docId).update({
      'read': true,
    });
  }

  /// Tandai semua notifikasi sebagai sudah dibaca
  Future<void> markAllNotificationsRead() async {
    final snapshot = await _db
        .collection('admin_notifications')
        .where('read', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  /// Buat notifikasi baru (dipanggil otomatis saat ada event)
  Future<void> createNotification({
    required String title,
    required String body,
    required String type, // 'new_report', 'claim_update', 'system'
  }) async {
    await _db.collection('admin_notifications').add({
      'title': title,
      'body': body,
      'type': type,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ══════════════════════════════════════════════════════
  // HELPER: Format waktu
  // ══════════════════════════════════════════════════════

  String timeAgo(DateTime d) {
    Duration diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${diff.inDays} hari lalu';
  }
}
