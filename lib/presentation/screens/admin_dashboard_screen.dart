import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_colors.dart';
import 'dart:convert';
import '../../data/service/admin_service.dart';

/// Admin dashboard with Overview, Claims, and Announcements tabs.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _activeTab = 'overview';
  String _claimFilter = 'all';

  // 1. Tambahkan Instance Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AdminService _adminService = AdminService();

  // Data admin dinamis dari login
  String _adminName = 'Admin';
  String _adminRole = 'Satpam';
  bool _isInitialized = false;

  // Cache streams agar tidak di-recreate saat rebuild (fix Flutter Web bug)
  late final Stream<QuerySnapshot> _reportsStream;
  late final Stream<QuerySnapshot> _notifStream;
  late final Stream<QuerySnapshot> _announcementsStream;

  @override
  void initState() {
    super.initState();
    _reportsStream = _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots();
    _notifStream = _adminService.getUnreadNotificationsStream();
    _announcementsStream = _adminService.getAnnouncementsStream();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _adminName = args['adminName'] ?? 'Admin';
        _adminRole = args['adminRole'] ?? 'Satpam';
      }
      // Seed pengumuman default jika collection kosong
      _adminService.seedDefaultAnnouncements(_adminName);
      _isInitialized = true;
    }
  }

  static const _emojis = {
    'Dompet': '👛',
    'Laptop': '💻',
    'Kunci': '🔑',
    'Dokumen': '📄',
    'Lainnya': '📦',
  };
  
  static const _statusCfg = {
    'pending': {'label': 'Menunggu', 'color': 0xFFFFB81C, 'bg': 0xFFFFF8E6},
    'approved': {'label': 'Disetujui', 'color': 0xFF34C759, 'bg': 0xFFE8F9EE},
    'rejected': {'label': 'Ditolak', 'color': 0xFFFF3B30, 'bg': 0xFFFFE8E6},
    'on_hold': {'label': 'Ditahan', 'color': 0xFF007AFF, 'bg': 0xFFE6F2FF},
  };
  
  static const _annTypeCfg = {
    'info': {'label': 'Info', 'color': 0xFF007AFF, 'icon': Icons.info},
    'warning': {'label': 'Peringatan', 'color': 0xFFFF9500, 'icon': Icons.warning},
    'found': {'label': 'Barang Temuan', 'color': 0xFF34C759, 'icon': Icons.inventory_2},
    'event': {'label': 'Acara', 'color': 0xFF003366, 'icon': Icons.event},
  };

  // --- HELPER WAKTU ---
  String _timeAgo(DateTime d) {
    Duration diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${diff.inDays} hari lalu';
  }

  // --- ALGORITMA KECERDASAN AI ---
  Map<String, dynamic> _mapDocToClaim(QueryDocumentSnapshot doc, List<QueryDocumentSnapshot> allDocs) {
    final data = doc.data() as Map<String, dynamic>;
    final ts = data['createdAt'] as Timestamp?;
    final dt = ts?.toDate() ?? DateTime.now();

    String uiStatus = 'pending';
    if (data['status'] == 'Resolved') uiStatus = 'approved';
    if (data['status'] == 'Rejected') uiStatus = 'rejected';
    if (data['status'] == 'OnHold') uiStatus = 'on_hold';

    // AMAN DARI ERROR NUM TO INT:
    var savedScore = data['aiScore'] ?? data['score'] ?? data['matchScore'];
    int finalScore = 0;

    if (savedScore != null) {
      // Trik paksa ubah num ke int dengan aman
      finalScore = int.tryParse(savedScore.toString()) ?? 0;
    } else {
      bool isLost = data['isLost'] == true;
      int highestScore = 0;

      for (var other in allDocs) {
        if (other.id == doc.id) continue; 
        final otherData = other.data() as Map<String, dynamic>;
        
        if (otherData['isLost'] == isLost) continue; 
        
        int currentScore = 0;
        if (data['category'] == otherData['category']) currentScore += 60;
        if (data['location'] == otherData['location']) currentScore += 20;
        
        String t1 = (data['title'] ?? '').toString().toLowerCase();
        String t2 = (otherData['title'] ?? '').toString().toLowerCase();
        if (t1.isNotEmpty && t2.isNotEmpty) {
          List<String> words = t1.split(' ');
          for (String w in words) {
            if (w.length > 3 && t2.contains(w)) {
              currentScore += 15;
              break; 
            }
          }
        }
        if (currentScore > highestScore) highestScore = currentScore;
      }

      if (highestScore == 0) {
        int titleLen = data['title']?.toString().length ?? 0;
        finalScore = 12 + (titleLen % 20); 
      } else {
        finalScore = highestScore + (doc.id.hashCode % 5);
        if (finalScore > 99) finalScore = 99; 
      }
    }

    return {
      'id': doc.id,
      'title': data['title'] ?? 'Barang Tanpa Nama',
      'category': data['category'] ?? 'Lainnya',
      'reporter': data['reporterName'] ?? 'Mahasiswa',
      'nim': data['reporterNim'] ?? '-',
      'location': data['location'] ?? '-',
      'time': _timeAgo(dt),
      'score': finalScore, 
      'status': uiStatus,
      'desc': data['description'] ?? 'Tidak ada deskripsi',
      'imageBase64': data['image'] ?? data['imageBase64'] ?? '', 
    };
  }

  // Fungsi Action Tombol Satpam ke Firebase
  Future<void> _updateDbStatus(String id, String uiStatus) async {
    String dbStatus = 'Pending';
    if (uiStatus == 'approved') dbStatus = 'Resolved';
    if (uiStatus == 'rejected') dbStatus = 'Rejected';
    if (uiStatus == 'on_hold') dbStatus = 'OnHold';

    try {
      await _firestore.collection('reports').doc(id).update({
        'status': dbStatus,
      });

      // Buat notifikasi otomatis
      try {
        await _adminService.createNotification(
          title: 'Status Klaim Diubah',
          body: 'Klaim diubah menjadi $dbStatus oleh $_adminName',
          type: 'claim_update',
        );
      } catch (_) {}
    } catch (e) {
      print("Error updating status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: StreamBuilder<QuerySnapshot>(
        stream: _reportsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data!.docs;

          final dynamicClaims = allDocs
              .map((doc) => _mapDocToClaim(doc, allDocs))
              .toList();

          int pendingCount = dynamicClaims.where((c) => c['status'] == 'pending').length;
          int approvedCount = dynamicClaims.where((c) => c['status'] == 'approved').length;

          return Column(
            children: [
              // Header
              Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
                ),
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: const Center(child: Text('🎓', style: TextStyle(fontSize: 20))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _adminName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.shield, size: 16, color: AppColors.unesaGold),
                                ],
                              ),
                              Text(
                                '$_adminRole · PSDKU Magetan',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                              ),
                            ],
                          ),
                        ),
                        // Notification bell
                        StreamBuilder<QuerySnapshot>(
                          stream: _notifStream,
                          builder: (context, notifSnap) {
                            int unread = notifSnap.hasData ? _adminService.countUnread(notifSnap.data!) : 0;
                            return GestureDetector(
                              onTap: () => _showNotificationPanel(context),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.notifications, size: 18, color: Colors.white.withOpacity(0.8)),
                                  ),
                                  if (unread > 0)
                                    Positioned(
                                      top: -2, right: -2,
                                      child: Container(
                                        width: 16, height: 16,
                                        decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                                        alignment: Alignment.center,
                                        child: Text('$unread', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(context, '/'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.logout, size: 16, color: Colors.white.withOpacity(0.8)),
                                const SizedBox(width: 4),
                                Text('Keluar', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Tabs
                    Row(
                      children: [
                        _headerTab('overview', 'Ringkasan', Icons.shield, null),
                        _headerTab('claims', 'Klaim', Icons.inventory_2, pendingCount),
                        _headerTab('announcements', 'Pengumuman', Icons.campaign, null),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _activeTab == 'overview'
                    ? _overviewTab(dynamicClaims, pendingCount, approvedCount)
                    : _activeTab == 'claims'
                    ? _claimsTab(dynamicClaims, pendingCount, approvedCount)
                    : _announcementsTab(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _headerTab(String id, String label, IconData icon, int? badge) {
    final isActive = _activeTab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.bgLight : Colors.transparent,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 16, color: isActive ? AppColors.unesaBlue : Colors.white60),
                  if (badge != null && badge > 0)
                    Positioned(
                      top: -6, right: -8,
                      child: Container(
                        width: 16, height: 16,
                        decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text('$badge', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? AppColors.unesaBlue : Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Overview Tab ──
  Widget _overviewTab(List<Map<String, dynamic>> claimsList, int pCount, int aCount) {
    int hCount = claimsList.where((c) => c['status'] == 'on_hold').length;
    int rCount = claimsList.where((c) => c['status'] == 'rejected').length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.unesaBlue, Color(0xFF004488)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Selamat bertugas,', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
              Text('$_adminName 👮', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _miniStat('Klaim Pending', '$pCount', AppColors.unesaGold),
                  const SizedBox(width: 8),
                  _miniStat('Disetujui', '$aCount', AppColors.success),
                  const SizedBox(width: 8),
                  _miniStat('Pengumuman', '-', Colors.white),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: [
            _kpiTile('Total Laporan', '${claimsList.length}', Icons.inventory_2, AppColors.unesaBlue, AppColors.unesaLightBlue,
              onTap: () => setState(() { _activeTab = 'claims'; _claimFilter = 'all'; }),
            ),
            _kpiTile('Berhasil Kembali', '$aCount', Icons.trending_up, AppColors.success, AppColors.foundBgLight,
              onTap: () => setState(() { _activeTab = 'claims'; _claimFilter = 'approved'; }),
            ),
            _kpiTile('Klaim Ditahan', '$hCount', Icons.error_outline, AppColors.infoBadge, AppColors.unesaLightBlue,
              onTap: () => setState(() { _activeTab = 'claims'; _claimFilter = 'on_hold'; }),
            ),
            _kpiTile('Klaim Ditolak', '$rCount', Icons.cancel, AppColors.danger, AppColors.lostBgLight,
              onTap: () => setState(() { _activeTab = 'claims'; _claimFilter = 'rejected'; }),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (pCount > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Klaim Menunggu Tindakan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.unesaBlue)),
              GestureDetector(
                onTap: () => setState(() => _activeTab = 'claims'),
                child: const Text('Lihat Semua', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.unesaGold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...claimsList.where((c) => c['status'] == 'pending').take(2).map((c) => _claimCard(c)),
        ],
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _kpiTile(String label, String value, IconData icon, Color color, Color bg, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color),
                  ),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Claims Tab ──
  Widget _claimsTab(List<Map<String, dynamic>> claimsList, int pCount, int aCount) {
    int hCount = claimsList.where((c) => c['status'] == 'on_hold').length;
    int rCount = claimsList.where((c) => c['status'] == 'rejected').length;

    List<Map<String, dynamic>> filteredClaims = _claimFilter == 'all'
        ? claimsList
        : claimsList.where((c) => c['status'] == _claimFilter).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _chipBtn('all', 'Semua (${claimsList.length})'),
              _chipBtn('pending', 'Pending ($pCount)'),
              _chipBtn('approved', 'Disetujui ($aCount)'),
              _chipBtn('on_hold', 'Ditahan ($hCount)'),
              _chipBtn('rejected', 'Ditolak ($rCount)'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (filteredClaims.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Icon(Icons.inventory_2, size: 40, color: AppColors.lightMuted),
                SizedBox(height: 12),
                Text('Tidak ada klaim ditemukan', style: TextStyle(fontSize: 14, color: AppColors.mutedText)),
              ],
            ),
          )
        else
          ...filteredClaims.map((c) => _claimCard(c)),
      ],
    );
  }

  Widget _chipBtn(String value, String label) {
    final active = _claimFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _claimFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.unesaBlue : Colors.white,
            borderRadius: BorderRadius.circular(99),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? Colors.white : AppColors.mutedText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _claimCard(Map<String, dynamic> claim) {
    final s = _statusCfg[claim['status'] as String]!;
    final emoji = _emojis[claim['category'] as String] ?? '📦';
    
    // AMAN DARI ERROR NUM TO INT:
    int score = int.tryParse(claim['score'].toString()) ?? 0;
    
    final scoreColor = score >= 90 ? AppColors.success : score >= 70 ? AppColors.unesaGold : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: score / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: scoreColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.hardEdge,
                      alignment: Alignment.center,
                      child: _buildImageOrEmoji(claim['imageBase64'] as String?, emoji),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  claim['title'] as String,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Color(s['bg'] as int), borderRadius: BorderRadius.circular(99)),
                                child: Text(
                                  s['label'] as String,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(s['color'] as int)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person, size: 12, color: AppColors.mutedText),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${claim['reporter']} · ${claim['nim']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 12, color: AppColors.mutedText),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  claim['location'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(claim['time'] as String, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                              Text('AI $score%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scoreColor)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (claim['status'] == 'pending') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () => _updateDbStatus(claim['id'], 'approved'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success, foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: EdgeInsets.zero,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [Icon(Icons.check, size: 14), SizedBox(width: 4), Text('Setujui', style: TextStyle(fontSize: 12))],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () => _updateDbStatus(claim['id'], 'on_hold'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.unesaGold, foregroundColor: AppColors.unesaBlue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: EdgeInsets.zero,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [Icon(Icons.pause, size: 14), SizedBox(width: 4), Text('Tahan', style: TextStyle(fontSize: 12))],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () => _updateDbStatus(claim['id'], 'rejected'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger, foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: EdgeInsets.zero,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [Icon(Icons.close, size: 14), SizedBox(width: 4), Text('Tolak', style: TextStyle(fontSize: 12))],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (claim['status'] == 'approved' || claim['status'] == 'rejected')
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: Color(s['bg'] as int), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(claim['status'] == 'approved' ? Icons.check_circle : Icons.cancel, size: 14, color: Color(s['color'] as int)),
                        const SizedBox(width: 6),
                        Text('Klaim telah ${(s['label'] as String).toLowerCase()}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(s['color'] as int))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageOrEmoji(String? base64Str, String fallbackEmoji) {
    if (base64Str == null || base64Str.trim().isEmpty) {
      return Text(fallbackEmoji, style: const TextStyle(fontSize: 24));
    }
    try {
      String cleanBase64 = base64Str.contains(',') ? base64Str.split(',').last : base64Str;
      return Image.memory(
        base64Decode(cleanBase64),
        fit: BoxFit.cover,
        width: 64,
        height: 64,
        errorBuilder: (context, error, stackTrace) {
          return Text(fallbackEmoji, style: const TextStyle(fontSize: 24));
        },
      );
    } catch (e) {
      return Text(fallbackEmoji, style: const TextStyle(fontSize: 24));
    }
  }

  // ── Announcements Tab ──
  Widget _announcementsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _announcementsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        int activeCount = docs.where((d) => d['active'] == true).length;
        int pinnedCount = docs.where((d) => d['pinned'] == true).length;
        int inactiveCount = docs.where((d) => d['active'] != true).length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _annStat('Aktif', activeCount, AppColors.success),
                const SizedBox(width: 8),
                _annStat('Disematkan', pinnedCount, AppColors.unesaGold),
                const SizedBox(width: 8),
                _annStat('Nonaktif', inactiveCount, AppColors.lightMuted),
              ],
            ),
            const SizedBox(height: 12),
            // Tombol buat pengumuman baru
            GestureDetector(
              onTap: () => _showCreateAnnouncementDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.unesaLightBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.unesaBlue.withOpacity(0.2)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 16, color: AppColors.unesaBlue),
                    SizedBox(width: 6),
                    Text('Buat Pengumuman Baru', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.unesaBlue)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (docs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(Icons.campaign, size: 40, color: AppColors.lightMuted),
                    SizedBox(height: 12),
                    Text('Belum ada pengumuman', style: TextStyle(fontSize: 14, color: AppColors.mutedText)),
                  ],
                ),
              )
            else
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final ts = data['createdAt'] as Timestamp?;
                final dt = ts?.toDate() ?? DateTime.now();
                return _announcementCard({
                  'id': doc.id,
                  'title': data['title'] ?? '',
                  'body': data['body'] ?? '',
                  'type': data['type'] ?? 'info',
                  'author': data['author'] ?? 'Admin',
                  'date': _timeAgo(dt),
                  'pinned': data['pinned'] ?? false,
                  'active': data['active'] ?? true,
                });
              }),
          ],
        );
      },
    );
  }

  Widget _annStat(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Column(
          children: [
            Text('$value', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
          ],
        ),
      ),
    );
  }

  Widget _announcementCard(Map<String, dynamic> ann) {
    final cfg = _annTypeCfg[ann['type'] as String] ?? _annTypeCfg['info']!;
    final color = Color(cfg['color'] as int);
    final isActive = ann['active'] == true;
    final isPinned = ann['pinned'] == true;
    final docId = ann['id'] as String;

    return Opacity(
      opacity: isActive ? 1.0 : 0.55,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Column(
          children: [
            Container(height: 4, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(12)))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                        child: Icon(cfg['icon'] as IconData, size: 16, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (isPinned) ...[const Icon(Icons.push_pin, size: 12, color: AppColors.unesaGold), const SizedBox(width: 4)],
                                Expanded(child: Text(ann['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(ann['body'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                            const SizedBox(height: 4),
                            Text('oleh ${ann['author']} · ${ann['date']}', style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _adminService.togglePin(docId, isPinned),
                        child: _annAction(isPinned ? Icons.push_pin : Icons.push_pin_outlined, isPinned ? 'Unpin' : 'Pin', isPinned ? AppColors.unesaGold : AppColors.lightMuted, isPinned ? AppColors.goldBgLight : AppColors.bgLight),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _adminService.toggleActive(docId, isActive),
                        child: _annAction(Icons.visibility, isActive ? 'Nonaktifkan' : 'Aktifkan', isActive ? AppColors.lightMuted : AppColors.success, isActive ? AppColors.bgLight : AppColors.foundBgLight),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _annAction(IconData icon, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  // ── Dialog Buat Pengumuman ──
  void _showCreateAnnouncementDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String selectedType = 'info';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Buat Pengumuman', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Judul pengumuman', isDense: true)),
                const SizedBox(height: 12),
                TextField(controller: bodyCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Isi pengumuman', isDense: true)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(isDense: true, labelText: 'Tipe'),
                  items: const [
                    DropdownMenuItem(value: 'info', child: Text('Info')),
                    DropdownMenuItem(value: 'warning', child: Text('Peringatan')),
                    DropdownMenuItem(value: 'found', child: Text('Barang Temuan')),
                    DropdownMenuItem(value: 'event', child: Text('Acara')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                await _adminService.createAnnouncement(
                  title: titleCtrl.text.trim(),
                  body: bodyCtrl.text.trim(),
                  type: selectedType,
                  author: _adminName,
                );
                if (mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.unesaBlue, foregroundColor: Colors.white),
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Panel Notifikasi ──
  void _showNotificationPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Notifikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.unesaBlue)),
                  GestureDetector(
                    onTap: () async {
                      await _adminService.markAllNotificationsRead();
                    },
                    child: const Text('Tandai semua dibaca', style: TextStyle(fontSize: 12, color: AppColors.unesaGold, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _adminService.getNotificationsStream(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('Belum ada notifikasi', style: TextStyle(color: AppColors.mutedText)));
                  }
                  return ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final isRead = data['read'] == true;
                      final ts = data['createdAt'] as Timestamp?;
                      final dt = ts?.toDate() ?? DateTime.now();
                      final typeIcon = data['type'] == 'new_report' ? Icons.fiber_new : Icons.notifications;
                      return ListTile(
                        dense: true,
                        leading: Icon(typeIcon, size: 20, color: isRead ? AppColors.lightMuted : AppColors.unesaBlue),
                        title: Text(data['title'] ?? '', style: TextStyle(fontSize: 13, fontWeight: isRead ? FontWeight.w400 : FontWeight.w600)),
                        subtitle: Text(data['body'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                        trailing: Text(_timeAgo(dt), style: const TextStyle(fontSize: 10, color: AppColors.lightMuted)),
                        tileColor: isRead ? null : AppColors.unesaLightBlue.withOpacity(0.3),
                        onTap: () => _adminService.markNotificationRead(docs[i].id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}