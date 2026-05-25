import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lostnfoundunesa5/data/service/database_service.dart';
import '../widgets/app_colors.dart';

/// Report screen for submitting lost or found items.
class ReportScreen extends StatefulWidget {
  final bool isLost;
  const ReportScreen({super.key, required this.isLost});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String? _category;
  String? _location;
  String _date = ''; // Akan diisi tanggal hari ini di initState

  // Inisialisasi Database Service
  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = false; // Mencegah user klik tombol berkali-kali

  XFile? _pickedImage;
  Uint8List? _webImage;
  String? _base64String;

  static const _categories = [
    'Dompet',
    'Tas',
    'Kunci',
    'Handphone',
    'Laptop',
    'Kacamata',
    'Payung',
    'Alat Tulis',
    'Dokumen',
    'Lainnya',
  ];

  static const _locations = [
    'Gedung A Lt. 1',
    'Gedung A Lt. 2',
    'Gedung A Lt. 3',
    'Gedung A Lt. 4',
    'Perpustakaan',
    'Kantin',
    'Lapangan',
    'Parkiran Motor',
    'Masjid Kampus',
    'Koridor',
    'Lainnya',
  ];

  // FUNGSI AMBIL, KOMPRES, DAN KONVERSI GAMBAR
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();

    // KOMPRESI OTOMATIS TERJADI DI SINI
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 50, // Kualitas dikurangi jadi 50%
      maxWidth: 800, // Lebar maksimal 800 pixel
      maxHeight: 800, // Tinggi maksimal 800 pixel
    );

    if (image != null) {
      // Membaca ukuran byte dari gambar yang sudah dikompres
      final bytes = await image.readAsBytes();

      // Mengubah byte gambar menjadi teks panjang (Base64)
      final base64Image = base64Encode(bytes);

      setState(() {
        _webImage = bytes; // Untuk ditampilkan di UI (Preview)
        _pickedImage = image; // Untuk status UI
        _base64String = base64Image; // Untuk dikirim ke database
      });
    }
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      _category != null &&
      _descController.text.trim().isNotEmpty &&
      _location != null &&
      !_isLoading; // Tombol disable saat loading

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final nim = user?.email?.split('@')[0] ?? 'Anonim';
      final displayName = user?.displayName ?? nim;

      await _dbService.submitReport(
        title: _nameController.text.trim(),
        description: _descController.text.trim(),
        category: _category!,
        location: _location!,
        date: _date,
        isLost: widget.isLost,
        reporterNim: nim,
        reporterName: displayName,
        imageBase64: _base64String, // Kirim teks Base64-nya ke database
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan Berhasil Terkirim!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Kembali ke Home Screen, bukan di-pop ke Login
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerColor = widget.isLost ? AppColors.danger : AppColors.success;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Header ──
          Container(
            color: headerColor,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: Row(
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isLost
                          ? 'Laporkan Barang Hilang'
                          : 'Laporkan Barang Temuan',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Isi form dengan lengkap',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // AI info bar
          Container(
            color: AppColors.unesaLightBlue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              children: const [
                Icon(Icons.auto_awesome, size: 16, color: AppColors.unesaBlue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI akan otomatis mencocokkan laporan Anda dengan database barang yang ada',
                    style: TextStyle(fontSize: 12, color: AppColors.unesaBlue),
                  ),
                ),
              ],
            ),
          ),

          // ── Form ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Photo upload Section
                _sectionCard([
                  const Text(
                    'Foto Barang',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 250, // Diperbesar agar preview terlihat jelas
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        width: 2,
                      ),
                      // Menampilkan gambar dari memori web
                      image: _webImage != null
                          ? DecorationImage(
                              image: MemoryImage(_webImage!),
                              fit: BoxFit.contain, // Mencegah gambar terpotong
                            )
                          : null,
                    ),
                    child: _webImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_search,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Belum ada foto terpilih',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt, size: 16),
                          label: const Text(
                            'Kamera',
                            style: TextStyle(fontSize: 14),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.upload, size: 16),
                          label: const Text(
                            'Galeri',
                            style: TextStyle(fontSize: 14),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ]),
                const SizedBox(height: 16),

                // Item details
                _sectionCard([
                  _label('Nama Barang *'),
                  const SizedBox(height: 6),
                  _textField(_nameController, 'Contoh: Dompet kulit coklat'),
                  const SizedBox(height: 16),
                  _label('Kategori *'),
                  const SizedBox(height: 6),
                  _dropdown(
                    _categories,
                    _category,
                    (v) => setState(() => _category = v),
                    'Pilih kategori',
                  ),
                  const SizedBox(height: 16),
                  _label('Deskripsi Detail *'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descController,
                    onChanged: (_) => setState(() {}),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Jelaskan ciri-ciri barang: warna, ukuran, merek, isi, dll',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: AppColors.mutedText,
                      ),
                      filled: true,
                      fillColor: AppColors.bgLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Semakin detail deskripsi, semakin akurat AI Matching',
                    style: TextStyle(fontSize: 12, color: AppColors.mutedText),
                  ),
                  const SizedBox(height: 16),
                  _label('Tanggal ${widget.isLost ? "Hilang" : "Ditemukan"} *'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.tryParse(_date) ?? DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                        helpText: 'Pilih Tanggal',
                        cancelText: 'Batal',
                        confirmText: 'Pilih',
                      );
                      if (picked != null) {
                        setState(() {
                          _date = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(_date, style: const TextStyle(fontSize: 14)),
                          const Spacer(),
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppColors.mutedText,
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // Location
                _sectionCard([
                  _label(
                    'Lokasi ${widget.isLost ? "Terakhir Dilihat" : "Penemuan"} *',
                  ),
                  const SizedBox(height: 12),
                  _dropdown(
                    _locations,
                    _location,
                    (v) => setState(() => _location = v),
                    'Pilih lokasi',
                  ),
                  const SizedBox(height: 12),
                  // Campus map placeholder
                  Container(
                    height: 144,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDBEAFE), Color(0xFFDCFCE7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 32,
                                color: AppColors.unesaBlue,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Peta Kampus UNESA Magetan',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.unesaBlue,
                                ),
                              ),
                              if (_location != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    '📍 $_location',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.unesaBlue,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 24),

                // Submit BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isValid ? _submitData : null,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check, size: 20),
                    label: Text(
                      _isLoading ? 'Mengirim...' : 'Kirim Laporan',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: headerColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: headerColor.withOpacity(0.5),
                      disabledForegroundColor: Colors.white70,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Laporan akan diverifikasi oleh tim keamanan dalam 1×24 jam',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.mutedText),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(List<Widget> children) {
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
        children: children,
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    );
  }

  Widget _textField(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.mutedText),
        filled: true,
        fillColor: AppColors.bgLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _dropdown(
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
    String hint,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.bgLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      hint: Text(
        hint,
        style: const TextStyle(fontSize: 14, color: AppColors.mutedText),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e, style: const TextStyle(fontSize: 14)),
            ),
          )
          .toList(),
    );
  }
}
