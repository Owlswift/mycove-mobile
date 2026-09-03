import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'mc_colors.dart';

/// Inter throughout, for both headings/titles and body text.
///
/// [heading]/[body] stay as the general-purpose, size-parameterized
/// entry points most call sites use; the named roles below (heroTitle
/// through [button]) are the fixed weight/size scale — use these directly
/// wherever a screen maps cleanly onto one of these roles.
class McTextStyles {
  McTextStyles._();

  static TextStyle heading({
    double fontSize = 22,
    Color color = McColors.titleText,
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
    Color color = McColors.bodyText,
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
    Color color = McColors.titleText,
    double fontSize = 36,
    double? height,
  }) => heading(
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    color: color,
    height: height,
  );
  static TextStyle screenTitle({Color color = McColors.titleText}) =>
      heading(fontSize: 30, fontWeight: FontWeight.w700, color: color);
  static TextStyle sectionTitle({Color color = McColors.titleText}) =>
      heading(fontSize: 22, fontWeight: FontWeight.w600, color: color);
  static TextStyle cardTitle({Color color = McColors.titleText}) =>
      heading(fontSize: 18, fontWeight: FontWeight.w600, color: color);
  static TextStyle caption({Color color = McColors.bodyText}) =>
      body(fontSize: 14, fontWeight: FontWeight.w400, color: color);
  static TextStyle small({Color color = McColors.bodyText}) =>
      body(fontSize: 12, fontWeight: FontWeight.w500, color: color);
  static TextStyle button({Color color = Colors.white}) =>
      body(fontSize: 16, fontWeight: FontWeight.w600, color: color);

  // ── Input fields ─────────────────────────────────────────────────────
  // One shared color/size/weight for every text field's typed value across
  // the app, and one for its placeholder — previously each field (login,
  // estate code, phone, password, complaint, amount entry...) set its own
  // slightly different fontSize/fontWeight/color inline, so a value could
  // look heavier or lighter depending on which screen you were on.
  static TextStyle inputValue({double fontSize = 15}) =>
      body(fontSize: fontSize, fontWeight: FontWeight.w500, color: McColors.neutralN(800));
  static TextStyle inputPlaceholder({double fontSize = 15}) =>
      body(fontSize: fontSize, fontWeight: FontWeight.w400, color: McColors.bodyText);
}
