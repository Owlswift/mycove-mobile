import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ch_colors.dart';

/// Inter throughout, for both headings/titles and body text.
///
/// [heading]/[body] stay as the general-purpose, size-parameterized
/// entry points most call sites use; the named roles below (heroTitle
/// through [button]) are the fixed weight/size scale — use these directly
/// wherever a screen maps cleanly onto one of these roles.
class ChTextStyles {
  ChTextStyles._();

  static TextStyle heading({
    double fontSize = 22,
    Color color = ChColors.titleText,
    FontWeight fontWeight = FontWeight.w700,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height ?? 1.15,
      letterSpacing: -0.3,
    );
  }

  static TextStyle body({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w400,
    Color color = ChColors.bodyText,
    double? height,
    double letterSpacing = -0.1,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height ?? 1.4,
      letterSpacing: letterSpacing,
    );
  }

  // ── Named scale ──────────────────────────────────────────────────────
  static TextStyle heroTitle({
    Color color = ChColors.titleText,
    double fontSize = 36,
    double? height,
  }) => heading(
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    color: color,
    height: height,
  );
  static TextStyle screenTitle({Color color = ChColors.titleText}) =>
      heading(fontSize: 30, fontWeight: FontWeight.w700, color: color);
  static TextStyle sectionTitle({Color color = ChColors.titleText}) =>
      heading(fontSize: 22, fontWeight: FontWeight.w600, color: color);
  static TextStyle cardTitle({Color color = ChColors.titleText}) =>
      heading(fontSize: 18, fontWeight: FontWeight.w600, color: color);
  static TextStyle caption({Color color = ChColors.bodyText}) =>
      body(fontSize: 14, fontWeight: FontWeight.w400, color: color);
  static TextStyle small({Color color = ChColors.bodyText}) =>
      body(fontSize: 12, fontWeight: FontWeight.w500, color: color);
  static TextStyle button({Color color = Colors.white}) =>
      body(fontSize: 16, fontWeight: FontWeight.w600, color: color);
}
