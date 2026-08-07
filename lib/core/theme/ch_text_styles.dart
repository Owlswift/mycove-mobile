import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ch_colors.dart';

/// Inter, top to bottom — free, proven cross-platform (unlike SF Pro, which
/// Apple's font license restricts to Apple-platform software and can't
/// legally ship in an Android build), and the pragmatic pick over
/// Fontshare-only faces like General Sans that would need font files
/// manually bundled as assets.
///
/// [heading]/[body] stay as the general-purpose, size-parameterized
/// entry points most call sites use; the named roles below (heroTitle
/// through [button]) are the fixed weight/size scale — use these directly
/// wherever a screen maps cleanly onto one of these roles.
class ChTextStyles {
  ChTextStyles._();

  static TextStyle heading({
    double fontSize = 22,
    Color color = ChColors.text,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: color, height: 1.15, letterSpacing: -0.3);
  }

  static TextStyle body({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w400,
    Color color = ChColors.text,
  }) {
    return GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: color, height: 1.4);
  }

  // ── Named scale ──────────────────────────────────────────────────────
  static TextStyle heroTitle({Color color = ChColors.text, double fontSize = 36}) =>
      heading(fontSize: fontSize, fontWeight: FontWeight.w700, color: color);
  static TextStyle screenTitle({Color color = ChColors.text}) => heading(fontSize: 30, fontWeight: FontWeight.w700, color: color);
  static TextStyle sectionTitle({Color color = ChColors.text}) => heading(fontSize: 22, fontWeight: FontWeight.w600, color: color);
  static TextStyle cardTitle({Color color = ChColors.text}) => heading(fontSize: 18, fontWeight: FontWeight.w600, color: color);
  static TextStyle caption({Color color = ChColors.text}) => body(fontSize: 14, fontWeight: FontWeight.w400, color: color);
  static TextStyle small({Color color = ChColors.text}) => body(fontSize: 12, fontWeight: FontWeight.w500, color: color);
  static TextStyle button({Color color = Colors.white}) => body(fontSize: 17, fontWeight: FontWeight.w600, color: color);
}
