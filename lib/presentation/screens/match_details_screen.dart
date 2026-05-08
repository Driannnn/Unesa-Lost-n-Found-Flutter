import 'package:flutter/material.dart';
import '../widgets/app_colors.dart';

/// Match details screen showing AI match comparison.
class MatchDetailsScreen extends StatefulWidget {
  const MatchDetailsScreen({super.key});

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  String _activeTab = 'details';
  final int _matchPercentage = 95;

  @override
  Widget build(BuildContext context) {
    final matchColor = _matchPercentage >= 90
        ? AppColors.success
        : _matchPercentage >= 70
            ? AppColors.unesaGold
            : AppColors.danger;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Header ──
          Container(
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('AI Match Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text('Detail kecocokan barang', style: TextStyle(fontSize: 14, color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Match percentage hero
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16)],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome, size: 28, color: AppColors.unesaGold),
                          const SizedBox(width: 12),
                          Text(
                            '$_matchPercentage%',
                            style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: matchColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('AI Match Confidence', style: TextStyle(fontSize: 12, color: AppColors.mutedText)),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: _matchPercentage / 100.0,
                          minHeight: 10,
                          backgroundColor: AppColors.bgLight,
                          valueColor: AlwaysStoppedAnimation(matchColor),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '✨ Kemungkinan tinggi ini adalah barang Anda!',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: matchColor),
                      ),
                    ],
                  ),
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
                _tabBtn('comparison', 'Perbandingan'),
              ],
            ),
          ),

          // ── Content ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: _activeTab == 'details' ? _detailsTab() : _comparisonTab(),
            ),
          ),

          // ── Bottom CTA ──
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -2))],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/chat'),
                    icon: const Icon(Icons.chat_bubble, size: 20),
                    label: const Text('Hubungi Penemu via Chat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.unesaBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Chat anonim untuk koordinasi pengambilan barang',
                    style: TextStyle(fontSize: 12, color: AppColors.mutedText)),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
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
            border: Border(bottom: BorderSide(color: isActive ? AppColors.unesaBlue : Colors.transparent, width: 2)),
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

  List<Widget> _detailsTab() {
    return [
      _itemCard(
        badgeText: 'Barang Hilang',
        badgeColor: AppColors.danger,
        title: 'Dompet Coklat',
        emoji: '👛',
        category: 'Dompet',
        reporter: 'Budi Santoso',
        date: '2026-04-17',
        location: 'Gedung A Lt. 2',
        description: 'Dompet kulit coklat merk Fossil, berisi KTM, kartu ATM BRI, dan uang tunai Rp150.000',
      ),
      const SizedBox(height: 16),
      _itemCard(
        badgeText: 'Barang Temuan',
        badgeColor: AppColors.success,
        title: 'Dompet Kulit Coklat',
        emoji: '👛',
        category: 'Dompet',
        reporter: 'Satpam Gedung A',
        date: '3 jam lalu',
        location: 'Gedung A Lt. 2',
        description: 'Dompet kulit coklat dengan logo Fossil di depan, ada beberapa kartu di dalamnya',
      ),
    ];
  }

  List<Widget> _comparisonTab() {
    return [
      // Side by side
      _sectionCard('Perbandingan Visual', [
        Row(
          children: [
            Expanded(child: _imageColumn('Barang Hilang', '👛')),
            const SizedBox(width: 12),
            Expanded(child: _imageColumn('Barang Temuan', '👛')),
          ],
        ),
      ]),
      const SizedBox(height: 16),
      // Match factors
      _sectionCard('Faktor Kecocokan', [
        _matchFactor('Kategori', 100, 'Dompet'),
        const SizedBox(height: 16),
        _matchFactor('Lokasi', 100, 'Gedung A Lt. 2'),
        const SizedBox(height: 16),
        _matchFactor('Waktu', 88, 'Rentang yang dekat'),
        const SizedBox(height: 16),
        _matchFactor('Visual AI', 95, 'Sangat mirip'),
        const SizedBox(height: 16),
        _matchFactor('Deskripsi', 100, 'Kata kunci cocok'),
      ]),
      const SizedBox(height: 16),
      // AI Analysis
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.unesaBlue.withOpacity(0.05), AppColors.unesaGold.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.unesaGold.withOpacity(0.2), width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome, size: 24, color: AppColors.unesaGold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Analisis AI', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.unesaBlue)),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'Sistem AI menganalisis kesamaan visual, lokasi, waktu, dan deskripsi. Dengan tingkat kecocokan '),
                      TextSpan(text: '$_matchPercentage%', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.unesaBlue)),
                      const TextSpan(text: ', kami sangat yakin ini adalah barang yang Anda cari. Silakan hubungi penemu untuk verifikasi lebih lanjut.'),
                    ]),
                    style: const TextStyle(fontSize: 14, color: AppColors.mutedText),
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(99)),
                child: Text(badgeText, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity, height: 192,
            decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 60)),
          ),
          const SizedBox(height: 12),
          _metaRow(Icons.person, 'Dilaporkan oleh: $reporter'),
          const SizedBox(height: 8),
          _metaRow(Icons.calendar_today, date),
          const SizedBox(height: 8),
          _metaRow(Icons.location_on, location),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 4),
          const Text('Deskripsi:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 14, color: AppColors.mutedText)),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.mutedText),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14, color: AppColors.mutedText)),
      ],
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
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

  Widget _imageColumn(String label, String emoji) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
        const SizedBox(height: 8),
        Container(
          height: 128,
          decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 48)),
        ),
      ],
    );
  }

  Widget _matchFactor(String label, int score, String match) {
    final color = score >= 90 ? AppColors.success : score >= 70 ? AppColors.unesaGold : AppColors.danger;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            Text('$score%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(value: score / 100.0, minHeight: 6, backgroundColor: AppColors.bgLight, valueColor: AlwaysStoppedAnimation(color)),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.check_circle, size: 12, color: AppColors.success),
            const SizedBox(width: 4),
            Text(match, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
          ],
        ),
      ],
    );
  }
}
