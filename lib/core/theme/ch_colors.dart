import 'package:flutter/material.dart';

/// Palette ported from the Claude Design "Organic" design system
/// (ds-styles.css) used for the CommunityHub mockup.
class ChColors {
  ChColors._();

  static const Color bg = Color(0xfff5ead8);
  static const Color surface = Color(0xffebddc5);
  static const Color text = Color(0xff201e1d);
  static const Color accent = Color(0xffc67139);
  static const Color accent2 = Color(0xff7a8a5e);
  static const Color divider = Color(0x29201e1d); // text @ 16%
  static const Color danger = Color(0xffb3402c);

  static const List<Color> neutral = [
    Color(0xfff9f4ed), // 100
    Color(0xffeee7db), // 200
    Color(0xffdcd3c4), // 300
    Color(0xffc0b6a5), // 400
    Color(0xffa19786), // 500
    Color(0xff82796a), // 600
    Color(0xff645c50), // 700
    Color(0xff474238), // 800
    Color(0xff2e2b25), // 900
  ];

  static const List<Color> accentRamp = [
    Color(0xfffff2eb), // 100
    Color(0xffffe1d0), // 200
    Color(0xffffc6a5), // 300
    Color(0xfff6a06b), // 400
    Color(0xffd67f48), // 500
    Color(0xffb2622d), // 600
    Color(0xff8c491a), // 700
    Color(0xff643312), // 800
    Color(0xff402310), // 900
  ];

  static const List<Color> accent2Ramp = [
    Color(0xfff0fae1), // 100
    Color(0xffe1eecc), // 200
    Color(0xffccdbb2), // 300
    Color(0xffaebf92), // 400
    Color(0xff8fa073), // 500
    Color(0xff728157), // 600
    Color(0xff56633f), // 700
    Color(0xff3d472b), // 800
    Color(0xff272e1b), // 900
  ];

  static Color neutralN(int step) => neutral[(step ~/ 100) - 1];
  static Color accentN(int step) => accentRamp[(step ~/ 100) - 1];
  static Color accent2N(int step) => accent2Ramp[(step ~/ 100) - 1];
}
