import 'package:flutter/material.dart';

/// UNESA Lost & Found brand color palette.
class AppColors {
  AppColors._();

  // Primary UNESA branding
  static const Color unesaBlue = Color(0xFF003366);
  static const Color unesaDarkBlue = Color(0xFF002244);
  static const Color unesaGold = Color(0xFFFFB81C);
  static const Color unesaLightBlue = Color(0xFFE6F2FF);

  // Backgrounds
  static const Color bgLight = Color(0xFFF4F6FB);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF34C759);
  static const Color danger = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFFB81C);
  static const Color infoBadge = Color(0xFF007AFF);

  // Text
  static const Color mutedText = Color(0xFF6C757D);
  static const Color lightMuted = Color(0xFF9CA3AF);

  // Badge backgrounds
  static const Color lostBgLight = Color(0xFFFFE8E6);
  static const Color foundBgLight = Color(0xFFE8F9EE);
  static const Color goldBgLight = Color(0xFFFFF8E6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [unesaBlue, unesaDarkBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient primaryVerticalGradient = LinearGradient(
    colors: [unesaBlue, unesaDarkBlue],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
