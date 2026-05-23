import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../../data/service/chat_service.dart';

/// Screen daftar semua percakapan chat milik user
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();

  // Menggunakan NIM, bukan UID
  String get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email?.split('@')[0] ?? user?.uid ?? '';
  }

  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inDays > 0) return '${diff.inDays}h lalu';
    if (diff.inHours > 0) return '${diff.inHours}j lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m lalu';
    return 'Baru saja';
  }

  @override
  Widget build(BuildContext context) {
    final userId = _currentUserId;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Column(
        children: [
          // ── Header ──
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
            ),
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Chat',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Percakapan dengan penemu / pencari barang',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Chat List ──
          Expanded(
            child: userId.isEmpty
                ? const Center(
                    child: Text(
                      'Silakan login terlebih dahulu',
                      style: TextStyle(color: AppColors.mutedText),
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: _chatService.getChatRooms(userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.unesaBlue,
                          ),
                        );
                      }

                      // Mencegah error jika stream gagal
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('💬', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 16),
                              Text(
                                'Terjadi Kesalahan: ${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Ambil data dan urutkan secara manual (Client-Side Sorting)
                      var docs = snapshot.data?.docs.toList() ?? [];

                      docs.sort((a, b) {
                        final dataA = a.data() as Map<String, dynamic>;
                        final dataB = b.data() as Map<String, dynamic>;
                        final timeA = dataA['lastMessageTime'] as Timestamp?;
                        final timeB = dataB['lastMessageTime'] as Timestamp?;

                        if (timeA == null && timeB == null) return 0;
                        if (timeA == null) return 1;
                        if (timeB == null) return -1;
                        return timeB.compareTo(
                          timeA,
                        ); // Terlama di bawah, terbaru di atas
                      });

                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('💬', style: TextStyle(fontSize: 48)),
                              SizedBox(height: 16),
                              Text(
                                'Belum Ada Percakapan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.mutedText,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Buka detail laporan dan tekan tombol\n"Chat dengan Penemu" untuk memulai.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.lightMuted,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          final chatRoomId = docs[index].id;
                          final reportTitle =
                              data['reportTitle'] ?? 'Percakapan';
                          final lastMessage = data['lastMessage'] ?? '';
                          final lastTime =
                              data['lastMessageTime'] as Timestamp?;
                          final participantNames =
                              data['participantNames']
                                  as Map<String, dynamic>? ??
                              {};

                          String otherName = 'Pengguna';
                          for (var entry in participantNames.entries) {
                            if (entry.key != userId) {
                              otherName = entry.value ?? 'Pengguna';
                              break;
                            }
                          }

                          return GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/chat-room',
                                arguments: {
                                  'chatRoomId': chatRoomId,
                                  'reportTitle': reportTitle,
                                  'otherUserName': otherName,
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.unesaLightBlue,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.chat_bubble_outline,
                                      size: 22,
                                      color: AppColors.unesaBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                reportTitle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _formatTimeAgo(lastTime),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.mutedText,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          lastMessage.isEmpty
                                              ? 'Belum ada pesan'
                                              : lastMessage,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: lastMessage.isEmpty
                                                ? AppColors.lightMuted
                                                : AppColors.mutedText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right,
                                    size: 20,
                                    color: AppColors.lightMuted,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),

          // ── Bottom nav ──
          BottomNavBar(
            currentIndex: 2,
            onTap: (i) {
              if (i == 0) Navigator.pushReplacementNamed(context, '/home');
              if (i == 1) Navigator.pushReplacementNamed(context, '/dashboard');
            },
          ),
        ],
      ),
    );
  }
}
