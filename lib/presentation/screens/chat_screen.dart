import 'package:flutter/material.dart';
import '../widgets/app_colors.dart';

/// Anonymous chat screen for claim coordination.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  bool _showInfo = false;

  final _messages = <Map<String, String>>[
    {'sender': 'other', 'text': 'Halo! Saya menemukan dompet coklat di Gedung A Lt. 2. Apakah ini milik Anda?', 'time': '09:14'},
    {'sender': 'user', 'text': 'Ya benar! Itu dompet saya. Terima kasih sudah menemukannya!', 'time': '09:16'},
    {'sender': 'other', 'text': 'Saya sudah serahkan ke pos satpam Gedung A. Bisa diambil dengan menunjukkan KTM.', 'time': '09:17'},
    {'sender': 'user', 'text': 'Baik, terima kasih banyak! Saya akan ke sana sekarang.', 'time': '09:18'},
  ];

  static const _quickReplies = [
    'Kapan bisa diambil?',
    'Di mana lokasinya?',
    'Apakah masih ada?',
    'Terima kasih!',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({'sender': 'user', 'text': text.trim(), 'time': TimeOfDay.now().format(context)});
      _inputController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Header ──
          Container(
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.chevron_left, size: 24, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Expanded(
                                child: Text('Dompet Coklat',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.verified_user, size: 16, color: AppColors.success),
                            ],
                          ),
                          Text('Chat Anonim · Terverifikasi',
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _showInfo = !_showInfo),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.info_outline, size: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Claim status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.goldBgLight, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.access_time, size: 16, color: AppColors.unesaGold),
                          SizedBox(width: 8),
                          Text('Status Klaim', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.unesaGold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.unesaGold.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text('Menunggu Verifikasi Admin',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.unesaGold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Info panel
          if (_showInfo)
            Container(
              color: AppColors.unesaLightBlue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.verified_user, size: 16, color: AppColors.unesaBlue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: 'Chat Anonim: ', style: TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(text: 'Identitas Anda tidak akan dibagikan. Koordinasi pengambilan barang dilakukan melalui pos keamanan. Jam layanan: 07.00–17.00 WIB.'),
                      ]),
                      style: TextStyle(fontSize: 12, color: AppColors.unesaBlue),
                    ),
                  ),
                ],
              ),
            ),

          // Privacy bar
          if (!_showInfo)
            Container(
              color: AppColors.bgLight,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, size: 14, color: AppColors.unesaBlue),
                  const SizedBox(width: 8),
                  Text('Chat anonim · Identitas terlindungi · Koordinasi via pos keamanan',
                      style: TextStyle(fontSize: 12, color: AppColors.unesaBlue.withOpacity(0.7))),
                ],
              ),
            ),

          // ── Messages ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                if (_messages.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Text('💬', style: TextStyle(fontSize: 40)),
                        SizedBox(height: 12),
                        Text('Mulai percakapan dengan penemu barang',
                            style: TextStyle(fontSize: 14, color: AppColors.mutedText)),
                      ],
                    ),
                  ),
                ..._messages.map((msg) {
                  final isUser = msg['sender'] == 'user';
                  final isAdmin = msg['sender'] == 'admin';
                  if (isAdmin) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.unesaBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(msg['text']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.unesaBlue)),
                      ),
                    );
                  }
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.unesaBlue : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isUser ? 16 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 16),
                        ),
                        boxShadow: isUser ? null : const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(msg['text']!,
                              style: TextStyle(fontSize: 14, height: 1.5, color: isUser ? Colors.white : Colors.black)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(msg['time']!, style: TextStyle(fontSize: 10, color: isUser ? Colors.white60 : AppColors.mutedText)),
                              if (isUser) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.done_all, size: 12, color: Colors.white.withOpacity(0.6)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                // Encryption notice
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text('🔒 Chat dienkripsi & dipantau sistem untuk keamanan',
                        style: TextStyle(fontSize: 12, color: AppColors.mutedText)),
                  ),
                ),
              ],
            ),
          ),

          // ── Quick replies ──
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: _quickReplies.map((q) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _inputController.text = q,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.bgLight,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(q, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.unesaBlue)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // ── Input ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    onSubmitted: _sendMessage,
                    decoration: InputDecoration(
                      hintText: 'Ketik pesan...',
                      hintStyle: const TextStyle(fontSize: 14),
                      filled: true,
                      fillColor: AppColors.bgLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(99),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_inputController.text),
                  child: Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(color: AppColors.unesaBlue, shape: BoxShape.circle),
                    child: const Icon(Icons.send, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
