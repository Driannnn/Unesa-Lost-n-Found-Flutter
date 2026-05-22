import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _generateChatRoomId(String userId1, String userId2, String reportId) {
    final sorted = [userId1, userId2]..sort();
    return '${sorted[0]}_${sorted[1]}_$reportId';
  }

  Future<String> getOrCreateChatRoom({
    required String currentUserId,
    required String otherUserId,
    required String reportId,
    required String reportTitle,
    String? currentUserName,
    String? otherUserName,
  }) async {
    final chatRoomId = _generateChatRoomId(
      currentUserId,
      otherUserId,
      reportId,
    );
    final docRef = _db.collection('chat_rooms').doc(chatRoomId);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'participants': [currentUserId, otherUserId],
        'participantNames': {
          currentUserId: currentUserName ?? currentUserId,
          otherUserId: otherUserName ?? otherUserId,
        },
        'reportId': reportId,
        'reportTitle': reportTitle,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return chatRoomId;
  }

  // ── PERBAIKAN: Membuang fitur Batch dan menggunakan pengiriman langsung ──
  Future<void> sendMessage({
  required String chatRoomId,
  required String senderId,
  required String text,
}) async {
  // 1. Tambahkan pesan sebagai dokumen baru di sub-koleksi 'messages'
  // Gunakan .doc() kosong agar Firestore otomatis membuat ID unik (Auto-ID)
  await _db
      .collection('chat_rooms')
      .doc(chatRoomId)
      .collection('messages')
      .add({
    'senderId': senderId,
    'text': text,
    'createdAt': FieldValue.serverTimestamp(),
  });

  // 2. Update 'lastMessage' di dokumen utama hanya untuk keperluan tampilan di ChatList
  await _db.collection('chat_rooms').doc(chatRoomId).update({
    'lastMessage': text,
    'lastMessageTime': FieldValue.serverTimestamp(),
  });
}

Stream<QuerySnapshot> getMessages(String chatRoomId) {
  return _db
      .collection('chat_rooms')
      .doc(chatRoomId)
      .collection('messages') // Arahkan ke sub-koleksi
      .orderBy('createdAt', descending: false) // Pesan lama di atas, baru di bawah
      .snapshots();
}

  Stream<QuerySnapshot> getChatRooms(String userId) {
    return _db
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .snapshots();
  }
}
