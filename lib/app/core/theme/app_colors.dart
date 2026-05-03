import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand — derived from TCS Tech logo (green chevron primary, blue accent)
  static const Color primary = Color(0xFF16A34A); // green-600
  static const Color primaryDark = Color(0xFF15803D); // green-700
  static const Color accent = Color(0xFF2563EB); // blue-600 (logo blue chevron)
  static const Color warning = Color(0xFFF59E0B); // amber-500 (logo yellow text)

  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  static const Color error = Color(0xFFDC2626); // red-600 (logo red chevron)
  static const Color divider = Color(0xFFE2E8F0);
}
