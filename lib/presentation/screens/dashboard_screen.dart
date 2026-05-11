import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _period = 'week';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _reportsStream;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    // Mengunci aliran data agar tidak refresh saat pindah tab periode
    _reportsStream = _firestore.collection('reports').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: StreamBuilder<QuerySnapshot>(
        stream: _reportsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          // 1. HITUNG STATISTIK UTAMA (Pastikan nama variabel sama dengan yang dipanggil UI)
          int total = docs.length;
          int lostCount = docs.where((d) => d['isLost'] == true).length;
          int foundCount = docs.where((d) => d['isLost'] == false).length;
          int resolvedCount = docs
              .where((d) => d['status'] == 'Resolved')
              .length;

          // 2. LOGIKA AI MATCHED
          int matchedCount = docs.where((d) {
            if (d['isLost'] != true) return false;
            return docs.any(
              (other) =>
                  other['isLost'] == false &&
                  other['category'] == d['category'],
            );
          }).length;

          // 3. LOGIKA BARU: TREN HARIAN BERTUMPUK (Stacked Data)
          // Membuat List berisi Map untuk menyimpan 3 status per hari
          List<Map<String, int>> weeklyData = List.generate(
            7,
            (_) => {'lost': 0, 'found': 0, 'resolved': 0},
          );

          for (var doc in docs) {
            Timestamp? ts = doc['createdAt'] as Timestamp?;
            if (ts != null) {
              DateTime date = ts.toDate();
              int dayIndex = date.weekday - 1;

              // Klasifikasi berdasarkan status asli di database
              if (doc['status'] == 'Resolved') {
                weeklyData[dayIndex]['resolved'] =
                    weeklyData[dayIndex]['resolved']! + 1;
              } else if (doc['isLost'] == true) {
                weeklyData[dayIndex]['lost'] =
                    weeklyData[dayIndex]['lost']! + 1;
              } else {
                weeklyData[dayIndex]['found'] =
                    weeklyData[dayIndex]['found']! + 1;
              }
            }
          }

          // Setelah perhitungan selesai, baru tampilkan UI
          return Column(
            children: [
              // ── Header (Sesuai Gambar image_51d1ab.png) ──
              Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
                ),
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Dashboard Statistik',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Monitor tren & titik rawan kehilangan',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        _buildLiveBadge(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPeriodToggle(),
                  ],
                ),
              ),

              // ── Content ──
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // KPI Cards Grid (Sesuai Gambar image_51d1ab.png)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _kpiCard(
                          'Total Laporan',
                          '$total',
                          '$lostCount hilang · $foundCount temuan',
                          Icons.inventory_2,
                          AppColors.unesaBlue,
                          AppColors.unesaLightBlue,
                          true,
                        ),
                        _kpiCard(
                          'Berhasil Kembali',
                          '$resolvedCount',
                          'Rate ${total > 0 ? (resolvedCount / total * 100).toInt() : 0}%',
                          Icons.check_circle,
                          AppColors.success,
                          AppColors.foundBgLight,
                          true,
                        ),
                        _kpiCard(
                          'Masih Hilang',
                          '$lostCount',
                          '${lostCount - matchedCount} belum ada match', // Menghitung sisa yang benar-benar belum ketemu
                          Icons.error_outline,
                          AppColors.danger,
                          AppColors.lostBgLight,
                          false,
                        ),
                        _kpiCard(
                          'AI Matched',
                          '$matchedCount',
                          'Pasang cocok ditemukan',
                          Icons.trending_up,
                          AppColors.unesaGold,
                          AppColors.goldBgLight,
                          true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tren Laporan (Sesuai Gambar image_51cefd.png)
                    _chartCard(
                      'Tren Laporan',
                      Icons.bar_chart,
                      170,
                      _buildTrendChart(weeklyData), // Masukkan data di sini
                      legend: [
                        _legendDot(AppColors.danger, 'Hilang'),
                        _legendDot(AppColors.success, 'Temuan'),
                        _legendDot(AppColors.unesaGold, 'Kembali'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Status & Kategori Side by Side (Sesuai Gambar image_51cefd.png)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _chartCard(
                            'Status Barang',
                            null,
                            200,
                            _buildStatusDonut(resolvedCount, total),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _chartCard(
                            'Kategori Barang',
                            null,
                            200,
                            _buildCategoryBars(docs),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Titik Rawan Kehilangan (Sesuai Gambar image_51cedc.png)
                    _hotspotSection(docs),
                    const SizedBox(height: 16),

                    // Log Aktivitas Terkini (Sesuai Gambar image_51cebe.png)
                    _activityLogSection(docs),
                    const SizedBox(height: 16),

                    // Akurasi AI Matching (Sesuai Gambar image_51cebe.png)
                    _aiAccuracyCard(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              BottomNavBar(
                currentIndex: 1,
                onTap: (i) {
                  if (i == 0) Navigator.pushReplacementNamed(context, '/home');
                  if (i == 2) Navigator.pushNamed(context, '/chat');
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // --- UI HELPER METHODS (Disesuaikan Presisi dengan Gambar) ---

  Widget _buildLiveBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: const [
        Icon(Icons.show_chart, size: 16, color: AppColors.unesaGold),
        SizedBox(width: 4),
        Text('Live', style: TextStyle(fontSize: 12, color: Colors.white)),
      ],
    ),
  );

  Widget _buildPeriodToggle() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        _periodBtn('week', 'Minggu Ini'),
        _periodBtn('month', 'Bulanan'),
      ],
    ),
  );

  Widget _periodBtn(String v, String l) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _period = v),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: _period == v ? AppColors.unesaGold : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          l,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: _period == v ? FontWeight.w700 : FontWeight.w400,
            color: _period == v ? AppColors.unesaBlue : Colors.white70,
          ),
        ),
      ),
    ),
  );

  Widget _kpiCard(
    String label,
    String value,
    String sub,
    IconData icon,
    Color color,
    Color bg,
    bool up,
  ) => Container(
    padding: const EdgeInsets.all(12),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            Icon(
              up ? Icons.trending_up : Icons.trending_down,
              size: 14,
              color: up ? AppColors.success : AppColors.danger,
            ),
          ],
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
        ),
        Text(
          sub,
          style: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );

  Widget _chartCard(
    String title,
    IconData? icon,
    double height,
    Widget chart, {
    List<Widget>? legend,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppColors.unesaBlue),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.unesaBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(height: height, child: chart),
        if (legend != null) ...[
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: legend),
        ],
      ],
    ),
  );

  Widget _buildTrendChart(List<Map<String, int>> data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          // Mendeteksi kursor bergerak
          onHover: (event) {
            final double leftPadding = 30.0;
            final double chartWidth = constraints.maxWidth - leftPadding;

            // 👇 UBAH DARI .x MENJADI .dx DI SINI 👇
            final double xPos = event.localPosition.dx - leftPadding;

            if (xPos >= 0 && xPos <= chartWidth) {
              int index = (xPos / (chartWidth / (data.length - 1))).round();
              if (index != _hoveredIndex) {
                setState(() => _hoveredIndex = index);
              }
            }
          },
          onExit: (_) => setState(() => _hoveredIndex = null),
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  // Masukkan _hoveredIndex ke dalam painter
                  painter: TrendLinePainter(
                    data: data,
                    hoveredIndex: _hoveredIndex,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(
                  left: 30,
                ), // Sesuai padding kiri angka
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
                      .map(
                        (d) => Text(
                          d,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.mutedText,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusDonut(int resolved, int total) {
    int open = total - resolved;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: total > 0 ? resolved / total : 0,
                strokeWidth: 8,
                backgroundColor: AppColors.bgLight,
                valueColor: const AlwaysStoppedAnimation(AppColors.success),
              ),
            ),
            Text(
              '${total > 0 ? (resolved / total * 100).toInt() : 0}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _statusRow(AppColors.success, 'Kembali', resolved),
        _statusRow(AppColors.danger, 'Dicari', open),
        _statusRow(AppColors.unesaGold, 'Verifikasi', 2), // Dummy detail
        _statusRow(AppColors.infoBadge, 'Tidak Diklaim', 3), // Dummy detail
      ],
    );
  }

  Widget _statusRow(Color col, String l, int v) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: col, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            l,
            style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
          ),
        ),
        Text(
          '$v',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: col,
          ),
        ),
      ],
    ),
  );

  Widget _buildCategoryBars(List<QueryDocumentSnapshot> docs) {
    Map<String, int> counts = {};
    for (var d in docs) {
      counts[d['category'] ?? 'Lainnya'] =
          (counts[d['category'] ?? 'Lainnya'] ?? 0) + 1;
    }
    var sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      children: sorted
          .take(5)
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      e.key,
                      style: const TextStyle(fontSize: 9),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: e.value * 15.0,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Container(
                          width: 10,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _hotspotSection(List<QueryDocumentSnapshot> docs) {
    // Menghitung lokasi tersering dari database
    Map<String, int> locCounts = {};
    for (var d in docs) {
      locCounts[d['location'] ?? 'Lainnya'] =
          (locCounts[d['location'] ?? 'Lainnya'] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.location_on, size: 16, color: AppColors.unesaBlue),
              SizedBox(width: 8),
              Text(
                'Titik Rawan Kehilangan',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.unesaBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Zone Grid (Sesuai image_51cedc.png)
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.1,
            children: [
              _hotspotTile(
                'Gedung A',
                '18',
                AppColors.lostBgLight,
                AppColors.danger,
              ),
              _hotspotTile(
                'Perpustakaan',
                '14',
                AppColors.goldBgLight,
                AppColors.unesaGold,
              ),
              _hotspotTile(
                'Kantin',
                '12',
                AppColors.goldBgLight,
                AppColors.unesaGold,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // List Detail
          ...locCounts.entries
              .take(3)
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.danger,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.key,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(
                        '↑${e.value}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lostBgLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Rawan Tinggi',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.danger,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _hotspotTile(String z, String k, Color bg, Color txt) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: txt.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.location_on, size: 12, color: txt),
        Text(
          z,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: txt,
          ),
          maxLines: 1,
        ),
        Text(
          '$k kasus',
          style: TextStyle(fontSize: 9, color: txt.withOpacity(0.8)),
        ),
      ],
    ),
  );

  Widget _activityLogSection(List<QueryDocumentSnapshot> docs) {
    final recent = docs.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.history, size: 16, color: AppColors.unesaBlue),
              SizedBox(width: 8),
              Text(
                'Log Aktivitas Terkini',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.unesaBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recent
              .map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: d['isLost']
                              ? AppColors.danger
                              : AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Laporan baru (${d['isLost'] ? "hilang" : "temuan"})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              d['title'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Baru saja',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _aiAccuracyCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: AppColors.primaryGradient,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Akurasi AI Matching',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
                Text(
                  '87.4%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.unesaGold, width: 2),
              ),
              child: const Center(
                child: Text(
                  'A+',
                  style: TextStyle(
                    color: AppColors.unesaGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _aiBar('Kecocokan Visual', 91),
        const SizedBox(height: 8),
        _aiBar('Kecocokan Deskripsi', 84),
        const SizedBox(height: 8),
        _aiBar('Kecocokan Lokasi', 78),
      ],
    ),
  );

  Widget _aiBar(String l, int p) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          Text(
            '$p%',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.unesaGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: p / 100.0,
          minHeight: 6,
          backgroundColor: Colors.white10,
          valueColor: const AlwaysStoppedAnimation(AppColors.unesaGold),
        ),
      ),
    ],
  );

  Widget _legendDot(Color col, String l) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: col, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          l,
          style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
        ),
      ],
    ),
  );
}

class TrendLinePainter extends CustomPainter {
  final List<Map<String, int>> data;
  final int? hoveredIndex;

  TrendLinePainter({required this.data, this.hoveredIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const double leftPadding = 30.0; // Ruang untuk angka di kiri
    final double width = size.width - leftPadding;
    final double height = size.height;
    final double stepX = width / (data.length - 1);

    // Skala Y (0, 3, 6, 9, 12 sesuai gambar Anda)
    const int maxVal = 12;

    // 1. Gambar Garis Bantu Horizontal & Angka Y-Axis
    final gridPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      double val = i * 3.0; // 0, 3, 6, 9, 12
      double y = height - (val / maxVal * height);

      // Garis putus-putus atau tipis
      canvas.drawLine(Offset(leftPadding, y), Offset(size.width, y), gridPaint);

      // Gambar Angka di sebelah kiri
      _drawText(canvas, Offset(0, y - 7), val.toInt().toString(), width: 25);
    }

    // Fungsi helper untuk menggambar garis data
    void drawSmoothLine(String key, Color color) {
      final path = Path();
      final fillPath = Path();

      double getY(int index) => height - (data[index][key]! / maxVal * height);

      path.moveTo(leftPadding, getY(0));
      fillPath.moveTo(leftPadding, height);
      fillPath.lineTo(leftPadding, getY(0));

      for (int i = 0; i < data.length - 1; i++) {
        double x1 = leftPadding + (i * stepX);
        double y1 = getY(i);
        double x2 = leftPadding + ((i + 1) * stepX);
        double y2 = getY(i + 1);

        double controlX = x1 + (x2 - x1) / 2;
        path.cubicTo(controlX, y1, controlX, y2, x2, y2);
        fillPath.cubicTo(controlX, y1, controlX, y2, x2, y2);
      }

      fillPath.lineTo(size.width, height);
      fillPath.close();

      canvas.drawPath(
        fillPath,
        Paint()
          ..color = color.withOpacity(0.1)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Render 3 Garis
    drawSmoothLine('lost', AppColors.danger);
    drawSmoothLine('found', AppColors.success);
    drawSmoothLine('resolved', AppColors.unesaGold);

    // 2. GAMBAR TOOLTIP (Jika ada bagian yang di-hover)
    if (hoveredIndex != null && hoveredIndex! < data.length) {
      final dayData = data[hoveredIndex!];
      double x = leftPadding + (hoveredIndex! * stepX);

      // Garis vertikal indikator
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, height),
        Paint()
          ..color = Colors.black12
          ..strokeWidth = 1,
      );

      // Gambar Kotak Info (Tooltip Card)
      final double cardW = 100;
      final double cardH = 85;
      double cardX = x + 10;
      double cardY = height / 4;

      // Geser tooltip ke kiri jika terlalu mepet kanan
      if (cardX + cardW > size.width) cardX = x - cardW - 10;

      // Shadow Kotak
      final RRect cardRect = RRect.fromLTRBR(
        cardX,
        cardY,
        cardX + cardW,
        cardY + cardH,
        const Radius.circular(8),
      );
      canvas.drawRRect(
        cardRect,
        Paint()
          ..color = Colors.black.withOpacity(0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Background Kotak Putih
      canvas.drawRRect(cardRect, Paint()..color = Colors.white);

      // Isi Teks Tooltip
      String dayName = [
        'Sen',
        'Sel',
        'Rab',
        'Kam',
        'Jum',
        'Sab',
        'Min',
      ][hoveredIndex!];
      _drawText(
        canvas,
        Offset(cardX + 10, cardY + 8),
        dayName,
        isBold: true,
        color: Colors.black87,
      );
      _drawText(
        canvas,
        Offset(cardX + 10, cardY + 28),
        'Hilang : ${dayData['lost']}',
        color: AppColors.danger,
      );
      _drawText(
        canvas,
        Offset(cardX + 10, cardY + 45),
        'Temuan : ${dayData['found']}',
        color: AppColors.success,
      );
      _drawText(
        canvas,
        Offset(cardX + 10, cardY + 62),
        'Kembali : ${dayData['resolved']}',
        color: AppColors.unesaGold,
      );

      // Titik di setiap persimpangan garis
      canvas.drawCircle(
        Offset(x, height - (dayData['lost']! / maxVal * height)),
        4,
        Paint()..color = AppColors.danger,
      );
      canvas.drawCircle(
        Offset(x, height - (dayData['found']! / maxVal * height)),
        4,
        Paint()..color = AppColors.success,
      );
      canvas.drawCircle(
        Offset(x, height - (dayData['resolved']! / maxVal * height)),
        4,
        Paint()..color = AppColors.unesaGold,
      );
    }
  }

  // Helper untuk menggambar teks di CustomPainter
  void _drawText(
    Canvas canvas,
    Offset offset,
    String text, {
    double size = 10,
    Color color = AppColors.mutedText,
    bool isBold = false,
    double? width,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: width ?? 100);
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant TrendLinePainter oldDelegate) =>
      oldDelegate.hoveredIndex != hoveredIndex;
}
