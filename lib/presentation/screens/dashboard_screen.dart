import 'package:flutter/material.dart';
import '../widgets/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';

/// Dashboard screen with statistics, charts, hotspots, and activity log.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _period = 'week';

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
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Dashboard Statistik',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                        SizedBox(height: 2),
                        Text('Monitor tren & titik rawan kehilangan',
                            style: TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                    Container(
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
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Period toggle
                Container(
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
                ),
              ],
            ),
          ),

          // ── Content ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // KPI cards
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _kpiCard('Total Laporan', '11', '4 hilang · 6 temuan', Icons.inventory_2, AppColors.unesaBlue, AppColors.unesaLightBlue, true),
                    _kpiCard('Berhasil Kembali', '1', 'Rate 25%', Icons.check_circle, AppColors.success, AppColors.foundBgLight, true),
                    _kpiCard('Masih Hilang', '3', '2 pending klaim', Icons.error_outline, AppColors.danger, AppColors.lostBgLight, false),
                    _kpiCard('AI Matched', '3', 'Pasang cocok ditemukan', Icons.trending_up, AppColors.unesaGold, AppColors.goldBgLight, true),
                  ],
                ),
                const SizedBox(height: 16),

                // Trend chart placeholder
                _chartCard(
                  'Tren Laporan',
                  Icons.bar_chart,
                  170,
                  _buildTrendChart(),
                  legend: [
                    _legendDot(AppColors.danger, 'Hilang'),
                    _legendDot(AppColors.success, 'Temuan'),
                    _legendDot(AppColors.unesaGold, 'Kembali'),
                  ],
                ),
                const SizedBox(height: 16),

                // Status + Category side by side
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _chartCard('Status Barang', null, 180, _buildStatusDonut())),
                    const SizedBox(width: 12),
                    Expanded(child: _chartCard('Kategori Barang', null, 180, _buildCategoryBars())),
                  ],
                ),
                const SizedBox(height: 16),

                // Hotspot map
                _hotspotSection(),
                const SizedBox(height: 16),

                // Activity log
                _activityLogSection(),
                const SizedBox(height: 16),

                // AI accuracy card
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
      ),
    );
  }

  Widget _periodBtn(String value, String label) {
    final isActive = _period == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _period = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? AppColors.unesaGold : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              color: isActive ? AppColors.unesaBlue : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _kpiCard(String label, String value, String sub, IconData icon, Color color, Color bg, bool up) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 16, color: color),
              ),
              Icon(up ? Icons.trending_up : Icons.trending_down, size: 14, color: up ? AppColors.success : AppColors.danger),
            ],
          ),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
          Text(sub, style: TextStyle(fontSize: 12, color: color.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _chartCard(String title, IconData? icon, double height, Widget chart, {List<Widget>? legend}) {
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
              if (icon != null) ...[Icon(icon, size: 16, color: AppColors.unesaBlue), const SizedBox(width: 8)],
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.unesaBlue)),
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
  }

  Widget _buildTrendChart() {
    final data = _period == 'week'
        ? [5, 8, 4, 10, 6, 3, 2]
        : [22, 30, 18, 26];
    final maxVal = data.reduce((a, b) => a > b ? a : b).toDouble();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((v) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: (v / maxVal) * 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.danger, Color(0xFFFF8A80)],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _period == 'week' ? ['S', 'S', 'R', 'K', 'J', 'S', 'M'][data.indexOf(v)] : 'Mg${data.indexOf(v) + 1}',
                  style: const TextStyle(fontSize: 10, color: AppColors.mutedText),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusDonut() {
    final segments = [
      {'label': 'Kembali', 'value': 1, 'color': AppColors.success},
      {'label': 'Dicari', 'value': 2, 'color': AppColors.danger},
      {'label': 'Verifikasi', 'value': 2, 'color': AppColors.unesaGold},
      {'label': 'Tidak Diklaim', 'value': 3, 'color': AppColors.infoBadge},
    ];
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.bgLight, width: 12),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.success, width: 6),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...segments.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: s['color'] as Color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(s['label'] as String, style: const TextStyle(fontSize: 12, color: AppColors.mutedText), overflow: TextOverflow.ellipsis)),
                  Text('${s['value']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: s['color'] as Color)),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildCategoryBars() {
    final cats = [
      {'name': 'Dompet', 'lost': 2, 'found': 2},
      {'name': 'Laptop', 'lost': 1, 'found': 1},
      {'name': 'Kunci', 'lost': 1, 'found': 1},
      {'name': 'Dokumen', 'lost': 1, 'found': 1},
      {'name': 'Payung', 'lost': 0, 'found': 1},
    ];
    return Column(
      children: cats.map((c) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(width: 52, child: Text(c['name'] as String, style: const TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis)),
              Expanded(
                child: Row(
                  children: [
                    Container(width: (c['lost'] as int) * 16.0, height: 6, decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 2),
                    Container(width: (c['found'] as int) * 16.0, height: 6, decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(3))),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _hotspotSection() {
    final hotspots = [
      {'zone': 'Gedung A (Kelas)', 'lost': 18, 'found': 12, 'risk': 'high'},
      {'zone': 'Perpustakaan', 'lost': 14, 'found': 16, 'risk': 'medium'},
      {'zone': 'Kantin Utama', 'lost': 12, 'found': 10, 'risk': 'medium'},
      {'zone': 'Lapangan', 'lost': 10, 'found': 7, 'risk': 'medium'},
      {'zone': 'Gedung B (Lab)', 'lost': 8, 'found': 9, 'risk': 'low'},
      {'zone': 'Parkiran Motor', 'lost': 9, 'found': 4, 'risk': 'high'},
    ];
    final riskStyle = {
      'high': {'bg': AppColors.lostBgLight, 'text': AppColors.danger, 'label': 'Rawan Tinggi'},
      'medium': {'bg': AppColors.goldBgLight, 'text': AppColors.unesaGold, 'label': 'Rawan Sedang'},
      'low': {'bg': AppColors.foundBgLight, 'text': AppColors.success, 'label': 'Rawan Rendah'},
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.location_on, size: 16, color: AppColors.unesaBlue),
              SizedBox(width: 8),
              Text('Titik Rawan Kehilangan', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.unesaBlue)),
            ],
          ),
          const SizedBox(height: 12),
          // Zone grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.unesaLightBlue, borderRadius: BorderRadius.circular(16)),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.2,
              children: hotspots.map((h) {
                final style = riskStyle[h['risk']]!;
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: style['bg'] as Color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (style['text'] as Color).withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 12, color: style['text'] as Color),
                      const SizedBox(height: 2),
                      Text(h['zone'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: style['text'] as Color), maxLines: 2, overflow: TextOverflow.ellipsis),
                      Text('${h['lost']} kasus', style: TextStyle(fontSize: 10, color: (style['text'] as Color).withOpacity(0.8))),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Table
          ...hotspots.asMap().entries.map((e) {
            final i = e.key;
            final h = e.value;
            final style = riskStyle[h['risk']]!;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: const Color(0xFFF0F0F0), width: i < hotspots.length - 1 ? 1 : 0))),
              child: Row(
                children: [
                  SizedBox(width: 20, child: Text('${i + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedText))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(h['zone'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                  Text('↑${h['lost']}', style: const TextStyle(fontSize: 12, color: AppColors.danger)),
                  const SizedBox(width: 8),
                  Text('↓${h['found']}', style: const TextStyle(fontSize: 12, color: AppColors.success)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: style['bg'] as Color, borderRadius: BorderRadius.circular(99)),
                    child: Text(style['label'] as String, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: style['text'] as Color)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _activityLogSection() {
    final activities = [
      {'action': 'Laporan baru (hilang)', 'item': 'Dompet Coklat', 'time': '2 jam lalu', 'color': AppColors.danger},
      {'action': 'Match AI 95%', 'item': 'Dompet Kulit Coklat', 'time': '3 jam lalu', 'color': AppColors.infoBadge},
      {'action': 'Laporan baru (hilang)', 'item': 'Laptop Asus VivoBook', 'time': '5 jam lalu', 'color': AppColors.danger},
      {'action': 'Barang dikembalikan', 'item': 'Kunci Motor Honda', 'time': 'Kemarin', 'color': AppColors.success},
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.show_chart, size: 16, color: AppColors.unesaBlue),
            SizedBox(width: 8),
            Text('Log Aktivitas Terkini', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.unesaBlue)),
          ]),
          const SizedBox(height: 12),
          ...activities.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(color: a['color'] as Color, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a['action'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          Text(a['item'] as String, style: const TextStyle(fontSize: 12, color: AppColors.mutedText), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Text(a['time'] as String, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _aiAccuracyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Akurasi AI Matching', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
                  const Text('87.4%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.unesaGold.withOpacity(0.3), width: 4),
                ),
                child: const Center(
                  child: Text('A+', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.unesaGold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _aiBar('Kecocokan Visual', 91),
          const SizedBox(height: 8),
          _aiBar('Kecocokan Deskripsi', 84),
          const SizedBox(height: 8),
          _aiBar('Kecocokan Lokasi', 78),
        ],
      ),
    );
  }

  Widget _aiBar(String label, int pct) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
            Text('$pct%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.unesaGold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: pct / 100.0,
            minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation(AppColors.unesaGold),
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
        ],
      ),
    );
  }
}
