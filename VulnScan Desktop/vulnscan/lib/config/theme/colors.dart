import 'package:flutter/material.dart';

/// GitHub-dark + Cybersecurity color palette for VulnScan
class AppColors {
  // ── Canvas / Backgrounds ──────────────────────────────────────
  /// True GitHub canvas — deepest background
  static const Color bgCanvas = Color(0xFF0d1117);

  /// GitHub primary surface (cards, panels)
  static const Color bgPrimary = Color(0xFF161b22);

  /// GitHub elevated surface (inputs, secondary panels)
  static const Color bgSecondary = Color(0xFF21262d);

  /// Hover / selection surface
  static const Color bgHover = Color(0xFF30363d);

  // ── Borders ───────────────────────────────────────────────────
  /// Default border color
  static const Color borderDefault = Color(0xFF30363d);

  /// Muted border (subtle)
  static const Color borderMuted = Color(0xFF21262d);

  /// Active/focused border (GitHub blue)
  static const Color borderActive = Color(0xFF388bfd);

  // ── Accent ───────────────────────────────────────────────────
  /// Cyber green — primary call-to-action accent
  static const Color accentGreen = Color(0xFF39d353);

  /// Cyber green dim — for hover states
  static const Color accentGreenDim = Color(0xFF2ea043);

  /// GitHub blue — secondary accent, links, focus
  static const Color accentBlue = Color(0xFF388bfd);

  /// GitHub blue dim
  static const Color accentBlueDim = Color(0xFF1f6feb);

  /// Purple — enterprise/premium
  static const Color accentPurple = Color(0xFFbc8cff);

  // ── Text ──────────────────────────────────────────────────────
  /// Primary text
  static const Color textPrimary = Color(0xFFe6edf3);

  /// Secondary / muted text
  static const Color textSecondary = Color(0xFF8b949e);

  /// Subtle text (disabled, placeholders)
  static const Color textSubtle = Color(0xFF6e7681);

  /// Code / monospace highlight color
  static const Color textCode = Color(0xFF79c0ff);

  // ── Severity (Vulnerability) ──────────────────────────────────
  static const Color severityCritical = Color(0xFFff4444);
  static const Color severityHigh = Color(0xFFff8c00);
  static const Color severityMedium = Color(0xFFffd33d);
  static const Color severityLow = Color(0xFF2ea043);
  static const Color severityInfo = Color(0xFF388bfd);

  // ── Semantic ──────────────────────────────────────────────────
  static const Color success = Color(0xFF2ea043);
  static const Color warning = Color(0xFFd29922);
  static const Color error = Color(0xFFf85149);
  static const Color info = Color(0xFF388bfd);

  // ── Legacy aliases (for backward compat with existing screens) ─
  static const Color primary = accentGreen;
  static const Color primaryLight = accentGreenDim;
  static const Color primaryDark = Color(0xFF196c2e);

  static const Color bgLight = Color(0xFFf6f8fa);
  static const Color bgLightSecondary = Color(0xFFedeff2);
  static const Color bgDark = bgCanvas;
  static const Color bgDarkSecondary = bgPrimary;

  static const Color textLight = Color(0xFF1f2328);
  static const Color textLightSecondary = Color(0xFF656d76);
  static const Color textDark = textPrimary;
  static const Color textDarkSecondary = textSecondary;

  static const Color borderLight = Color(0xFFd0d7de);
  static const Color borderDark = borderDefault;

  static const Color surfaceLight = Color(0xFFffffff);
  static const Color surfaceDark = bgPrimary;
}
