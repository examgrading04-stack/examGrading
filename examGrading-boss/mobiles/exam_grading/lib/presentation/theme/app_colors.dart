import 'package:flutter/material.dart';

class AppColors {
  // Primary brand gradient (Blue)
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color secondary = Color(0xFF3B82F6);
  static const Color secondaryDark = Color(0xFF1D4ED8);
  
  static const List<Color> primaryGradient = [primary, secondary];
  
  // Backgrounds
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  
  // Texts
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  
  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  
  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);

  // Soft Backgrounds
  static const Color primarySoft = Color(0xFFDBEAFE);
  static const Color successSoft = Color(0xFFD1FAE5);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color errorSoft = Color(0xFFFEE2E2);
  static const Color infoSoft = Color(0xFFE0F2FE);
  
  // Box Shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.3),
      blurRadius: 15,
      offset: const Offset(0, 6),
    ),
  ];
}
