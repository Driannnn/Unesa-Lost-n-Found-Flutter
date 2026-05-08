import 'package:flutter/material.dart';
import '../widgets/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/item_card_widget.dart';
import '../widgets/stat_card_widget.dart';

/// Home screen with feed, stats, search, and filters.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _filter = 'all'; // all | lost | found
  final _searchController = TextEditingController();

  // Dummy data
  static const _categoryIcons = {
    'Dompet': '👛', 'Tas': '🎒', 'Kunci': '🔑', 'Handphone': '📱',
    'Laptop': '💻', 'Kacamata': '👓', 'Payung': '☂️', 'Alat Tulis': '✏️',
    'Dokumen': '📄', 'Lainnya': '📦',
  };

  final _items = const [
    {'id': 'l1', 'title': 'Dompet Coklat', 'category': 'Dompet', 'status': 'lost', 'location': 'Gedung A Lt. 2', 'time': '2 jam lalu', 'matchScore': 95, 'hasMatch': true, 'claim': 'pending'},
    {'id': 'l2', 'title': 'Laptop Asus VivoBook', 'category': 'Laptop', 'status': 'lost', 'location': 'Perpustakaan', 'time': '5 jam lalu', 'matchScore': 88, 'hasMatch': true, 'claim': 'pending'},
    {'id': 'l3', 'title': 'Kunci Motor Honda', 'category': 'Kunci', 'status': 'lost', 'location': 'Parkiran Motor', 'time': 'Kemarin', 'matchScore': 91, 'hasMatch': true, 'claim': 'approved'},
    {'id': 'l4', 'title': 'Kacamata Hitam', 'category': 'Kacamata', 'status': 'lost', 'location': 'Lapangan', 'time': 'Kemarin', 'matchScore': null, 'hasMatch': false, 'claim': null},
    {'id': 'f1', 'title': 'Dompet Kulit Coklat', 'category': 'Dompet', 'status': 'found', 'location': 'Gedung A Lt. 2', 'time': '3 jam lalu', 'matchScore': 95, 'hasMatch': true, 'claim': null},
    {'id': 'f5', 'title': 'Payung Biru', 'category': 'Payung', 'status': 'found', 'location': 'Kantin', 'time': '1 hari lalu', 'matchScore': null, 'hasMatch': false, 'claim': null},
    {'id': 'f6', 'title': 'Tas Ransel Hitam', 'category': 'Tas', 'status': 'found', 'location': 'Perpustakaan', 'time': '1 hari lalu', 'matchScore': null, 'hasMatch': false, 'claim': null},
  ];

  List<Map<String, dynamic>> get _filteredItems {
    return _items.where((item) {
      final matchFilter = _filter == 'all' || item['status'] == _filter;
      final query = _searchController.text.toLowerCase();
      final matchSearch = query.isEmpty ||
          (item['title'] as String).toLowerCase().contains(query) ||
          (item['category'] as String).toLowerCase().contains(query);
      return matchFilter && matchSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Lost & Found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Halo, Budi 👋',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.unesaGold,
                          child: const Text(
                            'B',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.unesaBlue,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.unesaBlue, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '2',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 16, color: AppColors.mutedText),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration.collapsed(
                            hintText: 'Cari barang hilang atau temuan...',
                            hintStyle: TextStyle(fontSize: 14, color: AppColors.mutedText),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          child: const Icon(Icons.close, size: 16, color: AppColors.mutedText),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              children: [
                // Announcement banners
                _announcementBanner('Penemuan Dompet di Perpustakaan',
                    'Pemilik dapat menghubungi pos keamanan...'),
                const SizedBox(height: 8),
                _announcementBanner('Zona Rawan Kehilangan: Kantin',
                    'Harap selalu menjaga barang bawaan...'),
                const SizedBox(height: 16),

                // Quick actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Laporkan Barang',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.unesaBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 80,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pushNamed(context, '/report-lost'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.error_outline, size: 28),
                                    SizedBox(height: 4),
                                    Text('Barang Hilang', style: TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 80,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pushNamed(context, '/report-found'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.add_box_outlined, size: 28),
                                    SizedBox(height: 4),
                                    Text('Barang Temuan', style: TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Statistics
                const Text(
                  'Statistik',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.unesaBlue),
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Expanded(child: StatCardWidget(icon: Icons.error_outline, value: '4', label: 'Barang Hilang', color: AppColors.danger)),
                    SizedBox(width: 12),
                    Expanded(child: StatCardWidget(icon: Icons.add_box_outlined, value: '6', label: 'Barang Temuan', color: AppColors.success)),
                    SizedBox(width: 12),
                    Expanded(child: StatCardWidget(icon: Icons.trending_up, value: '1', label: 'Berhasil Kembali', color: AppColors.unesaGold)),
                  ],
                ),
                const SizedBox(height: 20),

                // Filter tabs
                Row(
                  children: [
                    _filterChip('all', 'Semua'),
                    const SizedBox(width: 8),
                    _filterChip('lost', 'Hilang'),
                    const SizedBox(width: 8),
                    _filterChip('found', 'Temuan'),
                  ],
                ),
                const SizedBox(height: 16),

                // Feed header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _searchController.text.isNotEmpty
                          ? 'Hasil Pencarian "${_searchController.text}"'
                          : 'Laporan Terbaru',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.unesaBlue,
                      ),
                    ),
                    Text(
                      '${_filteredItems.length} item',
                      style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Items
                if (_filteredItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Text('🔍', style: TextStyle(fontSize: 40)),
                        SizedBox(height: 12),
                        Text('Tidak ada item ditemukan',
                            style: TextStyle(fontSize: 14, color: AppColors.mutedText)),
                      ],
                    ),
                  )
                else
                  ..._filteredItems.map((item) => ItemCardWidget(
                        title: item['title'] as String,
                        category: item['category'] as String,
                        location: item['location'] as String,
                        timeAgo: item['time'] as String,
                        status: item['status'] as String,
                        emoji: _categoryIcons[item['category'] as String],
                        matchScore: item['matchScore'] as int?,
                        hasMatch: item['hasMatch'] as bool,
                        claimStatus: item['claim'] as String?,
                        onTap: (item['hasMatch'] as bool)
                            ? () => Navigator.pushNamed(context, '/match-details')
                            : null,
                      )),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Bottom nav ──
          BottomNavBar(
            currentIndex: 0,
            onTap: (i) {
              if (i == 1) Navigator.pushReplacementNamed(context, '/dashboard');
              if (i == 2) Navigator.pushNamed(context, '/chat');
            },
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final isActive = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.unesaBlue : AppColors.bgLight,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? Colors.white : AppColors.mutedText,
          ),
        ),
      ),
    );
  }

  Widget _announcementBanner(String title, String body) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.goldBgLight,
        border: Border.all(color: AppColors.unesaGold.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications, size: 14, color: AppColors.unesaGold),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.unesaBlue,
                    )),
                Text(body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
