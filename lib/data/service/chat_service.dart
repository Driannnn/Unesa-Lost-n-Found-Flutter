import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Chat room ID hanya berdasarkan 2 user (sorted).
  /// Sehingga percakapan antara 2 orang yang sama TIDAK bertumpuk.
  String _generateChatRoomId(String userId1, String userId2) {
    final sorted = [userId1, userId2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<String> getOrCreateChatRoom({
    required String currentUserId,
    required String otherUserId,
    required String reportId,
    required String reportTitle,
    String? currentUserName,
    String? otherUserName,
  }) async {
    final chatRoomId = _generateChatRoomId(currentUserId, otherUserId);
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
        'lastReadBy': {
          currentUserId: FieldValue.serverTimestamp(),
          otherUserId: null,
        },
      });
    } else {
      // Update participant names jika sudah ada (bisa berubah)
      await docRef.update({
        'participantNames.$currentUserId':
            currentUserName ?? currentUserId,
        'participantNames.$otherUserId':
            otherUserName ?? otherUserId,
        // Update report title ke yang terbaru
        'reportTitle': reportTitle,
      });
    }

    return chatRoomId;
  }

  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String text,
  }) async {
    await _db
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('chat_rooms').doc(chatRoomId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastReadBy.$senderId': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _db
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> getChatRooms(String userId) {
    return _db
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .snapshots();
  }

  Future<void> markChatAsRead(String chatRoomId, String userId) async {
    try {
      await _db.collection('chat_rooms').doc(chatRoomId).update({
        'lastReadBy.$userId': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking chat as read: $e');
    }
  }

  Stream<int> getUnreadChatCount(String userId) {
    return _db
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int unreadCount = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final lastMessageTime = data['lastMessageTime'] as Timestamp?;
        final lastReadBy = data['lastReadBy'] as Map<String, dynamic>? ?? {};
        final lastRead = lastReadBy[userId] as Timestamp?;
        final lastMessage = data['lastMessage'] as String? ?? '';

        if (lastMessage.isNotEmpty && lastMessageTime != null) {
          if (lastRead == null || lastMessageTime.compareTo(lastRead) > 0) {
            unreadCount++;
          }
        }
      }
      return unreadCount;
    });
  }
}
