import 'package:flutter/material.dart';

/// Brand and semantic colors for VulnScan
class AppColors {
  /// Primary Brand Colors
  static const Color primary = Color(0xFF4F46E5); // Indigo brand
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF111827);

  /// Semantic Colors
  static const Color success = Color(0xFF10B981); // Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Blue

  /// Severity Colors (for vulnerabilities)
  static const Color severityCritical = Color(0xFFDC2626); // Bright red
  static const Color severityHigh = Color(0xFFEA580C); // Orange
  static const Color severityMedium = Color(0xFFFB923C); // Light orange
  static const Color severityLow = Color(0xFFFCD34D); // Yellow
  static const Color severityInfo = Color(0xFF0EA5E9); // Light blue

  /// Background Colors
  static const Color bgLight = Color(0xFFF6F7FB);
  static const Color bgLightSecondary = Color(0xFFF3F4F6);
  static const Color bgDark = Color(0xFF0F172A);
  static const Color bgDarkSecondary = Color(0xFF1E293B);

  /// Text Colors
  static const Color textLight = Color(0xFF1F2937);
  static const Color textLightSecondary = Color(0xFF6B7280);
  static const Color textDark = Color(0xFFF9FAFB);
  static const Color textDarkSecondary = Color(0xFFD1D5DB);

  /// Border Colors
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF374151);

  /// Surface Colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1F2937);
}

