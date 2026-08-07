import 'package:flutter/material.dart';

/// Palette for CommunityHub's "Palm Court" look: a deep forest-green brand
/// color on a warm cream canvas with white cards, plus a muted gold accent
/// for secondary highlights (e.g. the dues card's "Pay Now" pill).
///
/// `accent2`/`accent` are kept as names (rather than renamed to e.g.
/// `primary`/`gold` everywhere) since they're referenced pervasively across
/// the app — `accent2` now carries the green brand role, `accent` the gold
/// role.
class ChColors {
  ChColors._();

  static const Color bg = Color(0xfff8f6f1);
  static const Color surface = Color(0xffffffff);
  static const Color surfaceSunken = Color(0xfff3f1eb);
  static const Color text = Color(0xff1c1e1a);
  static const Color accent = Color(0xffcc9c3e); // gold
  static const Color accent2 = Color(0xff1e4638); // deep green (brand primary)
  static const Color divider = Color(0xffe8e3d6);
  static const Color danger = Color(0xffc0392b);
  static const Color warning = Color(0xffd98c2b);

  static const List<Color> neutral = [
    Color(0xfffbfaf6), // 100
    Color(0xfff1eee4), // 200
    Color(0xffe3ded0), // 300
    Color(0xffcdc6b3), // 400
    Color(0xffaea695), // 500
    Color(0xff8c8574), // 600
    Color(0xff6b6558), // 700
    Color(0xff4a463c), // 800
    Color(0xff2c2a24), // 900
  ];

  // Gold ramp — `accent`.
  static const List<Color> accentRamp = [
    Color(0xfffdf7ea), // 100
    Color(0xfff8ecc9), // 200
    Color(0xfff0dca0), // 300
    Color(0xffe3c077), // 400
    Color(0xffd2a951), // 500
    Color(0xffcc9c3e), // 600
    Color(0xffa87c2c), // 700
    Color(0xff7a5a20), // 800
    Color(0xff4e3a15), // 900
  ];

  // Deep green ramp — `accent2` (brand primary).
  static const List<Color> accent2Ramp = [
    Color(0xffe9f1ec), // 100
    Color(0xffd1e3da), // 200
    Color(0xffa7cabb), // 300
    Color(0xff74a894), // 400
    Color(0xff477e69), // 500
    Color(0xff2c5c48), // 600
    Color(0xff1e4638), // 700
    Color(0xff15332a), // 800
    Color(0xff0d2019), // 900
  ];

  static Color neutralN(int step) => neutral[(step ~/ 100) - 1];
  static Color accentN(int step) => accentRamp[(step ~/ 100) - 1];
  static Color accent2N(int step) => accent2Ramp[(step ~/ 100) - 1];
}
