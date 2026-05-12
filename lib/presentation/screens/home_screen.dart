import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // WAJIB DITAMBAHKAN
import 'package:firebase_auth/firebase_auth.dart'; // Untuk fitur Logout
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

  // Instance Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _reportsStream;
  static const _categoryIcons = {
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

  @override
  void initState() {
    super.initState();
    // Menyalakan stream satu kali saja saat layar pertama kali dimuat
    _reportsStream = _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fungsi sederhana untuk mengubah tanggal Firestore menjadi teks (contoh: "2 jam lalu")
  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Baru saja';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inDays > 0) return '${diff.inDays} hari lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} menit lalu';
    return 'Baru saja';
  }

  @override
  Widget build(BuildContext context) {
    // Ambil nama user yang sedang login untuk Avatar
    // Prioritaskan displayName (dari Google Sign-In), fallback ke email
    final currentUser = FirebaseAuth.instance.currentUser;
    final userName = currentUser?.displayName ??
        currentUser?.email?.split('@')[0] ??
        'Mahasiswa';
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'M';
    final photoUrl = currentUser?.photoURL;

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
                      children: [
                        const Text(
                          'Lost & Found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Halo, $userName 👋',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await FirebaseAuth.instance.signOut();
                            if (mounted)
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/',
                                (route) => false,
                              );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.logout,
                                  size: 16,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Keluar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.unesaGold,
                          backgroundImage: photoUrl != null
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl == null
                              ? Text(
                                  initial,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.unesaBlue,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        size: 16,
                        color: AppColors.mutedText,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration.collapsed(
                            hintText: 'Cari barang hilang atau temuan...',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: AppColors.mutedText,
                            ),
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
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.mutedText,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Content Menggunakan StreamBuilder ──
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Mengambil data dari koleksi 'reports', diurutkan dari yang terbaru
              stream: _reportsStream,
              builder: (context, snapshot) {
                // 1. Loading State
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 2. Error State
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Terjadi kesalahan: ${snapshot.error}'),
                  );
                }

                // Ambil semua dokumen dari database
                final docs = snapshot.data?.docs ?? [];

                // Hitung Statistik Otomatis
                int lostCount = docs
                    .where((doc) => doc['isLost'] == true)
                    .length;
                int foundCount = docs
                    .where((doc) => doc['isLost'] == false)
                    .length;
                int resolvedCount = docs
                    .where((doc) => doc['status'] == 'Resolved')
                    .length;

                // Proses Filter & Pencarian
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final bool isLost = data['isLost'] ?? true;
                  final String statusString = isLost ? 'lost' : 'found';

                  final matchFilter =
                      _filter == 'all' || statusString == _filter;
                  final query = _searchController.text.toLowerCase();
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final category = (data['category'] ?? '')
                      .toString()
                      .toLowerCase();

                  final matchSearch =
                      query.isEmpty ||
                      title.contains(query) ||
                      category.contains(query);

                  return matchFilter && matchSearch;
                }).toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  children: [
                    _announcementBanner(
                      'Sistem Terhubung',
                      'Database Firebase aktif secara Real-time.',
                    ),
                    const SizedBox(height: 16),

                    // Quick actions (Tombol Lapor)
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
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      '/report-lost',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.danger,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.error_outline, size: 28),
                                        SizedBox(height: 4),
                                        Text(
                                          'Barang Hilang',
                                          style: TextStyle(fontSize: 14),
                                        ),
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
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      '/report-found',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.add_box_outlined, size: 28),
                                        SizedBox(height: 4),
                                        Text(
                                          'Barang Temuan',
                                          style: TextStyle(fontSize: 14),
                                        ),
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

                    // Statistics (Angka otomatis dari database)
                    const Text(
                      'Statistik',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.unesaBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: StatCardWidget(
                            icon: Icons.error_outline,
                            value: lostCount.toString(),
                            label: 'Barang Hilang',
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCardWidget(
                            icon: Icons.add_box_outlined,
                            value: foundCount.toString(),
                            label: 'Barang Temuan',
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCardWidget(
                            icon: Icons.trending_up,
                            value: resolvedCount.toString(),
                            label: 'Berhasil Kembali',
                            color: AppColors.unesaGold,
                          ),
                        ),
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
                          '${filteredDocs.length} item',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Menampilkan Data dari Firestore
                    if (filteredDocs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            Text('🔍', style: TextStyle(fontSize: 40)),
                            SizedBox(height: 12),
                            Text(
                              'Belum ada laporan',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...filteredDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final category = data['category'] ?? 'Lainnya';

return ItemCardWidget(
  title: data['title'] ?? 'Tanpa Nama',
  category: category,
  location: data['location'] ?? '-',
  timeAgo: _formatTimeAgo(data['createdAt'] as Timestamp?),
  status: (data['isLost'] ?? true) ? 'lost' : 'found',
  emoji: _categoryIcons[category] ?? '📦',
  imageBase64: data['imageBase64'], 
  
  // 👇 UBAH BAGIAN ONTAP MENJADI INI 👇
  onTap: () {
    Navigator.pushNamed(
      context, 
      '/match-details',
      arguments: {
        'title': data['title'],
        'category': data['category'],
        'description': data['description'],
        'location': data['location'],
        'date': data['date'],
        'imageBase64': data['imageBase64'],
        'status': (data['isLost'] ?? true) ? 'lost' : 'found',
        'reporterNim': data['reporterNim'],
      },
    );
  },
  
  // Data dummy matchScore bisa kita kosongkan dulu atau set default
  matchScore: null,
  hasMatch: false,
);
                      }),
                    const SizedBox(height: 16),
                  ],
                );
              },
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.unesaBlue,
                  ),
                ),
                Text(
                  body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
