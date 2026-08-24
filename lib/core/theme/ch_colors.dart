import 'package:flutter/material.dart';

/// Palette for MyCove's "Palm Court" look: a deep forest-green brand
/// color on a warm cream canvas with white cards, plus a muted gold accent
/// for secondary highlights (e.g. the dues card's "Pay Now" pill).
///
/// `accent2`/`accent` are kept as names (rather than renamed to e.g.
/// `primary`/`gold` everywhere) since they're referenced pervasively across
/// the app — `accent2` now carries the green brand role, `accent` the gold
/// role.
class ChColors {
  ChColors._();

  static const Color bg = Color(0xfffaf7f3);
  static const Color surface = Color(0xffffffff);
  static const Color surfaceSunken = Color(0x2bd1d2db);

  /// Text/select field fill — a translucent overlay (design-provided:
  /// #d1d2db2b, RRGGBBAA) rather than a flat color, so it picks up warmth
  /// from [bg]/[surface] underneath instead of reading as a cool grey.
  static const Color inputFill = Color(0x2bd1d2db);

  /// Bg and surface are nearly identical, so cards rely on this — not
  /// color contrast — to read as lifted off the background.
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  static const Color text = Color(0xff1c1e1a);
  static const Color titleText = Color(
    0xff282b25,
  ); // headings — lighter than [text], reads less harshly at large/bold sizes
  static const Color bodyText = Color(
    0xff767b83,
  ); // default color for non-heading text — see ChTextStyles.body
  static const Color accent = Color(0xffcc9c3e); // gold
  static const Color accent2 = Color(0xff0e4a2a); // deep green (brand primary)
  static const Color divider = Color(0xffe8e3d6);
  static const Color danger = Color(0xffc0392b);
  static const Color warning = Color(0xffd98c2b);

  static const List<Color> neutral = [
    Color(0xfffbfaf6), // 100
    Color(0xfff1eee4), // 200
    Color(0xffe3ded0), // 300
    Color(0xffcdc6b3), // 400
    Color(0xffaea695), // 500
    Color(0xff848793), // 600
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

  // Deep green ramp — `accent2` (brand primary). 700 is the primary itself;
  // 100-600 are progressively lighter tints (mixed toward white), 800-900
  // progressively darker shades (mixed toward black).
  static const List<Color> accent2Ramp = [
    Color(0xffe7edea), // 100
    Color(0xffcad7d0), // 200
    Color(0xffa3baae), // 300
    Color(0xff7a9b8a), // 400
    Color(0xff517d66), // 500
    Color(0xff2b6044), // 600
    Color(0xff0e4a2a), // 700
    Color(0xff0b3820), // 800
    Color(0xff072515), // 900
  ];

  static Color neutralN(int step) => neutral[(step ~/ 100) - 1];
  static Color accentN(int step) => accentRamp[(step ~/ 100) - 1];
  static Color accent2N(int step) => accent2Ramp[(step ~/ 100) - 1];
}
