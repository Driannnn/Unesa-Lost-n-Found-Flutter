import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets/app_colors.dart';
import '../../data/service/matching_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Screen untuk menampilkan detail barang dan status kecocokan AI
class MatchDetailsScreen extends StatefulWidget {
  const MatchDetailsScreen({super.key});

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  String _activeTab = 'details';

  // 2. VARIABEL STATE UNTUK AI
  bool _isInit = true;
  bool _isScanning = true;
  Map<String, dynamic>? _bestMatch;
  Map<String, dynamic> _currentReport = {};

  // 3. FUNGSI LIFECYCLE: Menangkap data dan memulai scan otomatis
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      // Ambil data "surat pengantar" dari HomeScreen
      _currentReport =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
          {};
      _scanForMatch(); // Mulai jalankan otak AI
      _isInit = false;
    }
  }

// 4. LOGIKA PEMANGGILAN OTAK AI
  Future<void> _scanForMatch() async {
    // Memberikan jeda 2 detik agar animasi "Memindai" terlihat keren
    await Future.delayed(const Duration(seconds: 2));

    // Memanggil algoritma di MatchingService yang sudah diperbarui
    final match = await MatchingService().findBestMatch(
      currentReportId: _currentReport['id'] ?? '', // <-- SEKARANG MENGIRIM ID ASLI
      isLost: _currentReport['status'] == 'lost',
      category: _currentReport['category'] ?? '',
      location: _currentReport['location'] ?? '',
      description: _currentReport['description'] ?? '',
      title: _currentReport['title'] ?? '', // <-- MENGIRIM JUDUL UNTUK DICOCOKKAN
    );

    // Update tampilan jika sudah selesai
    if (mounted) {
      setState(() {
        _bestMatch = match;
        _isScanning = false; // Matikan animasi loading
      });

      // SIMPAN SKOR KE FIREBASE AGAR ADMIN & MAHASISWA 100% SINKRON
      if (match != null && _currentReport['id'] != null && _currentReport['id'].toString().isNotEmpty) {
        try {
          FirebaseFirestore.instance
              .collection('reports')
              .doc(_currentReport['id'])
              .update({'score': match['matchScore']});
        } catch (e) {
          print('Gagal menyimpan skor AI ke Firebase: $e');
        }
      }
    }
  }

  String _getEmoji(String category) {
    const icons = {
      'Dompet': '👛',
      'Tas': '🎒',
      'Kunci': '🔑',
      'Handphone': '📱',
      'Laptop': '💻',
      'Kacamata': '👓',
      'Payung': '☂️',
      'Alat Tulis': '✏️',
      'Dokumen': '📄',
      'Lainnya': '📦',
    };
    return icons[category] ?? '📦';
  }

  @override
  Widget build(BuildContext context) {
    final title = _currentReport['title'] ?? 'Detail Barang';
    final category = _currentReport['category'] ?? 'Lainnya';
    final description = _currentReport['description'] ?? 'Tidak ada deskripsi.';
    final location = _currentReport['location'] ?? '-';
    final date = _currentReport['date'] ?? '-';
    final imageBase64 = _currentReport['imageBase64'];
    final status = _currentReport['status'] ?? 'lost';
    final reporterNim = _currentReport['reporterNim'] ?? 'Anonim';

    final isLost = status == 'lost';
    final badgeColor = isLost ? AppColors.danger : AppColors.success;
    final badgeText = isLost ? 'Barang Hilang' : 'Barang Temuan';
    final emoji = _getEmoji(category);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Header ──
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Detail Informasi Laporan',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 5. KOTAK STATUS AI YANG DINAMIS
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 16),
                    ],
                  ),
                  child: _buildHeroContent(),
                ),
              ],
            ),
          ),

          // ── Tabs ──
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _tabBtn('details', 'Detail Barang'),
                _tabBtn('comparison', 'Perbandingan AI'),
              ],
            ),
          ),

          // ── Content ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: _activeTab == 'details'
                  ? _detailsTab(
                      badgeText,
                      badgeColor,
                      title,
                      emoji,
                      category,
                      reporterNim,
                      date,
                      location,
                      description,
                      imageBase64,
                    )
                  : _comparisonTab(),
            ),
          ),

          // ── Bottom CTA (Hanya muncul jika ADA kecocokan) ──
          if (!_isScanning && _bestMatch != null)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/chat'),
                      icon: const Icon(Icons.chat_bubble, size: 20),
                      label: Text(
                        'Chat dengan ${_bestMatch!['reporterNim'] ?? 'Penemu'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.unesaBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Diskusikan lokasi dan waktu pertemuan',
                    style: TextStyle(fontSize: 12, color: AppColors.mutedText),
                  ),
                ],
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  // WIDGET HELPER: Mengatur tampilan Kotak Status AI
  Widget _buildHeroContent() {
    if (_isScanning) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.radar, size: 28, color: AppColors.unesaBlue),
              SizedBox(width: 12),
              Text(
                'Memindai...',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.unesaBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'AI sedang mencari kecocokan di database',
            style: TextStyle(fontSize: 12, color: AppColors.mutedText),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: const LinearProgressIndicator(
              minHeight: 6,
              backgroundColor: AppColors.bgLight,
              valueColor: AlwaysStoppedAnimation(AppColors.unesaBlue),
            ),
          ),
        ],
      );
    }

    if (_bestMatch == null) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.search_off, size: 28, color: AppColors.mutedText),
              SizedBox(width: 12),
              Text(
                'Belum Ada Match',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Sistem belum menemukan barang yang mirip di database.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.mutedText),
          ),
        ],
      );
    }

    int score = _bestMatch!['matchScore'] ?? 0;
    Color matchColor = score >= 90
        ? AppColors.success
        : score >= 70
        ? AppColors.unesaGold
        : AppColors.danger;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 28,
              color: AppColors.unesaGold,
            ),
            const SizedBox(width: 12),
            Text(
              '$score%',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: matchColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'AI Match Confidence',
          style: TextStyle(fontSize: 12, color: AppColors.mutedText),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: score / 100.0,
            minHeight: 10,
            backgroundColor: AppColors.bgLight,
            valueColor: AlwaysStoppedAnimation(matchColor),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '✨ Ditemukan kecocokan tinggi dengan laporan lain!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: matchColor,
          ),
        ),
      ],
    );
  }

  Widget _tabBtn(String id, String label) {
    final isActive = _activeTab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.unesaBlue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppColors.unesaBlue : AppColors.lightMuted,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _detailsTab(
    String badgeText,
    Color badgeColor,
    String title,
    String emoji,
    String category,
    String reporter,
    String date,
    String location,
    String description,
    String? imageBase64,
  ) {
    return [
      _itemCard(
        badgeText: badgeText,
        badgeColor: badgeColor,
        title: title,
        emoji: emoji,
        category: category,
        reporter: reporter,
        date: date,
        location: location,
        description: description,
        imageBase64: imageBase64,
      ),
    ];
  }

  // WIDGET HELPER: Mengatur Tab Perbandingan
  List<Widget> _comparisonTab() {
    if (_isScanning) {
      return [
        const Padding(
          padding: EdgeInsets.all(48.0),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.unesaBlue),
          ),
        ),
      ];
    }

    if (_bestMatch == null) {
      return [
        Container(
          padding: const EdgeInsets.all(32),
          alignment: Alignment.center,
          child: Column(
            children: const [
              Icon(Icons.search_off, size: 64, color: AppColors.lightMuted),
              SizedBox(height: 16),
              Text(
                'Tidak Ada Data Pembanding',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedText,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Belum ada laporan lawan yang cocok dengan kriteria barang ini di database.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.lightMuted),
              ),
            ],
          ),
        ),
      ];
    }

    // Jika menemukan kecocokan, tampilkan foto Side-by-Side
    final isLost = _currentReport['status'] == 'lost';
    final currentLabel = isLost ? 'Barang Anda' : 'Temuan Anda';
    final matchLabel = isLost ? 'Potensi Ditemukan' : 'Potensi Pemilik';

    final currentEmoji = _getEmoji(_currentReport['category'] ?? '');
    final matchEmoji = _getEmoji(_bestMatch!['category'] ?? '');

    return [
      _sectionCard('Perbandingan Visual', [
        Row(
          children: [
            Expanded(
              child: _imageColumn(
                currentLabel,
                currentEmoji,
                _currentReport['imageBase64'],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _imageColumn(
                matchLabel,
                matchEmoji,
                _bestMatch!['imageBase64'],
              ),
            ),
          ],
        ),
      ]),
      const SizedBox(height: 16),

      // Analisis AI Teks
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.unesaBlue.withOpacity(0.05),
              AppColors.unesaGold.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.unesaGold.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 24,
              color: AppColors.unesaGold,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analisis Kecocokan AI',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.unesaBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ditemukan kemiripan dengan laporan atas nama "${_bestMatch!['reporterNim'] ?? 'Anonim'}".\n\n'
                    '• Kategori: ${_bestMatch!['category']}\n'
                    '• Lokasi: ${_bestMatch!['location']}\n\n'
                    'Skor kecocokan mencapai ${_bestMatch!['matchScore']}%. Silakan gunakan fitur chat untuk verifikasi lebih lanjut.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _imageColumn(String label, String emoji, String? imageBase64) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
        ),
        const SizedBox(height: 8),
        Container(
          height: 128,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.bgLight,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: (imageBase64 != null && imageBase64.isNotEmpty)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(imageBase64),
                    height: 128,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Text(emoji, style: const TextStyle(fontSize: 48)),
                  ),
                )
              : Text(emoji, style: const TextStyle(fontSize: 48)),
        ),
      ],
    );
  }

  Widget _itemCard({
    required String badgeText,
    required Color badgeColor,
    required String title,
    required String emoji,
    required String category,
    required String reporter,
    required String date,
    required String location,
    required String description,
    required String? imageBase64,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: (imageBase64 != null && imageBase64.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(imageBase64),
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Text(emoji, style: const TextStyle(fontSize: 60)),
                    ),
                  )
                : Text(emoji, style: const TextStyle(fontSize: 60)),
          ),
          const SizedBox(height: 16),
          _metaRow(Icons.person, 'Dilaporkan oleh: $reporter'),
          const SizedBox(height: 8),
          _metaRow(Icons.calendar_today, date),
          const SizedBox(height: 8),
          _metaRow(Icons.location_on, location),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Deskripsi:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 14, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.mutedText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: AppColors.mutedText),
          ),
        ),
      ],
    );
  }
}
