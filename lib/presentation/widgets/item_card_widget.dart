import 'dart:convert'; // WAJIB DITAMBAHKAN untuk menerjemahkan Base64
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Reusable item card for the Home feed – shows lost/found items.
class ItemCardWidget extends StatelessWidget {
  final String title;
  final String category;
  final String location;
  final String timeAgo;
  final String status; // "lost" or "found"
  final String? emoji;
  final int? matchScore;
  final bool hasMatch;
  final String? claimStatus;
  final VoidCallback? onTap;
  
  // 1. TAMBAHKAN VARIABEL BARU UNTUK MENERIMA FOTO BASE64
  final String? imageBase64; 

  const ItemCardWidget({
    super.key,
    required this.title,
    required this.category,
    required this.location,
    required this.timeAgo,
    required this.status,
    this.emoji,
    this.matchScore,
    this.hasMatch = false,
    this.claimStatus,
    this.onTap,
    this.imageBase64, // 2. Daftarkan variabelnya di sini
  });

  @override
  Widget build(BuildContext context) {
    final isLost = status == 'lost';
    final badgeColor = isLost ? AppColors.danger : AppColors.success;
    final badgeBg = isLost ? AppColors.lostBgLight : AppColors.foundBgLight;
    final badgeText = isLost ? 'Hilang' : 'Temuan';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image / emoji placeholder
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  // 3. LOGIKA CERDAS: Jika ada foto, tampilkan foto. Jika tidak, tampilkan emoji.
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: (imageBase64 != null && imageBase64!.isNotEmpty)
                        ? Image.memory(
                            base64Decode(imageBase64!), // Mengubah teks kembali menjadi gambar
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover, // Gambar memenuhi kotak tanpa gepeng
                            // Jika terjadi error saat memuat gambar, kembalikan ke icon kardus
                            errorBuilder: (context, error, stackTrace) => Text(
                              emoji ?? '📦',
                              style: const TextStyle(fontSize: 30),
                            ),
                          )
                        : Text(
                            emoji ?? '📦',
                            style: const TextStyle(fontSize: 30),
                          ),
                  ),
                ),
                if (matchScore != null)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: matchScore! >= 90 ? AppColors.success : AppColors.unesaGold,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: Text(
                        '$matchScore%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: AppColors.mutedText),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time, size: 12, color: AppColors.mutedText),
                      const SizedBox(width: 4),
                      Text(
                        timeAgo,
                        style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                      ),
                    ],
                  ),
                  if (hasMatch)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        '✨ AI menemukan kecocokan • Tap untuk lihat',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  if (claimStatus == 'approved')
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        '✅ Klaim disetujui',
                        style: TextStyle(
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
    );
  }
}