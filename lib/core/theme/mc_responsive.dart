import 'package:flutter/material.dart';

/// Screen-size-aware scaling, referenced against the iPhone 17 Pro Max
/// (430×932 logical points) every screen in this app was designed and
/// visually verified against this session. Every other phone — from an
/// iPhone SE up to the largest Android phablets — scales relative to that
/// baseline instead of rendering the exact same pixel dimensions and
/// risking overflow on smaller screens or looking sparse on larger ones.
///
/// The clamp keeps scaling from going too far in either direction: text
/// and spacing shrink gracefully on small phones without becoming
/// illegibly small, and don't blow up unreasonably on larger ones.
class McResponsive {
  McResponsive._();

  static const double _baseWidth = 430;

  static double scaleOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return (width / _baseWidth).clamp(0.80, 1.08);
  }

  /// Scales a spacing/dimension value — padding, gaps, icon sizes, fixed
  /// widths/heights — for the current screen width. Font sizes don't need
  /// this: they're scaled globally instead (see [McTheme] wiring in
  /// `app.dart`), since `Text` widgets already respond to `MediaQuery`'s
  /// `textScaler` without every call site needing to opt in individually.
  static double space(BuildContext context, double value) =>
      value * scaleOf(context);
}

extension ChResponsiveX on BuildContext {
  /// The raw scale factor for this screen, e.g. for one-off calculations
  /// that don't fit [rs].
  double get rScale => McResponsive.scaleOf(this);

  /// Scales a single spacing/dimension value — shorthand for
  /// `McResponsive.space(context, value)`.
  double rs(double value) => McResponsive.space(this, value);
}
