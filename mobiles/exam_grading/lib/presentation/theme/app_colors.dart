import 'package:flutter/material.dart';

class AppColors {
  // Premium brand palette (Blue & Green Academic)
  static const Color primary = Color(0xFF035DD3); // Google Workspace Blue
  static const Color primaryDark = Color(0xFF005BBF); // Darker Blue
  static const Color secondary = Color(0xFF189448); // Forest Green
  static const Color secondaryDark = Color(0xFF187742); // Dark Forest Green

  static const List<Color> primaryGradient = [primary, primaryDark];

  // Backgrounds
  static const Color background = Color(0xFFFAFAF9);
  static const Color surface = Color(0xFFFFFFFF);

  // Texts
  static const Color textPrimary = Color(0xFF18181B);
  static const Color textSecondary = Color(0xFF52525B);
  static const Color textMuted = Color(0xFF71717A);

  // Borders & Dividers
  static const Color border = Color(0xFFE4E4E7);

  // Semantic
  static const Color success = Color(0xFF166534); // Forest Green
  static const Color successDark = Color(0xFF14532D);
  static const List<Color> successGradient = [success, successDark];

  static const Color warning = Color(0xFFD97706);
  static const Color warningDark = Color(0xFFB45309);
  static const List<Color> warningGradient = [warning, warningDark];

  static const Color error = Color(0xFFDC2626);
  
  static const Color info = Color(0xFF2563EB);
  static const Color infoDark = Color(0xFF1D4ED8);
  static const List<Color> infoGradient = [info, infoDark];

  // Soft Backgrounds
  static const Color primarySoft = Color(0xFFE2E8F0); // Light Slate
  static const Color successSoft = Color(0xFFD1FAE5);
  static const Color warningSoft = Color(0xFFFFEDD5);
  static const Color errorSoft = Color(0xFFFEE2E2);
  static const Color infoSoft = Color(0xFFDBEAFE);

  // Box Shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.22),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get successShadow => [
    BoxShadow(
      color: success.withValues(alpha: 0.22),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get warningShadow => [
    BoxShadow(
      color: warning.withValues(alpha: 0.22),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get infoShadow => [
    BoxShadow(
      color: info.withValues(alpha: 0.22),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
}
