class ChSpacing {
  ChSpacing._();

  static const double s1 = 4.4;
  static const double s2 = 8.8;
  static const double s3 = 13.2;
  static const double s4 = 17.6;
  static const double s6 = 26.4;
  static const double s8 = 35.2;
}

class ChRadii {
  ChRadii._();

  static const double sm = 8;
  static const double md = 16;
  static const double lg = 28;

  /// The mockup's ".rounded frame" override: cards/dialogs get rounder,
  /// buttons/tags/inputs go fully pill-shaped.
  static const double card = lg * 1.15;
  static const double pill = 999;
}
