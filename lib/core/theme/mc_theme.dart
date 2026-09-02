import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'mc_colors.dart';
import 'mc_spacing.dart';
import 'mc_text_styles.dart';

/// Most pages under the resident/guard shells are bare widget trees (a
/// `Column`, no `Scaffold` of their own) that rely on the shell's single
/// ambient `Scaffold` for their background. That's fine at rest, but mid
/// page-transition both the outgoing and incoming route are mounted and
/// painted at once — with neither carrying its own opaque backing, gaps in
/// either page's content (padding, spacing between cards, the space below
/// a short list) show the *other* page's content straight through, which
/// reads as a rendering glitch rather than a transition.
///
/// Fix: wrap `child` in an opaque background before handing off to the
/// real platform transition — [CupertinoPageTransitionsBuilder] /
/// [ZoomPageTransitionsBuilder] still drive the actual motion (native
/// feel, unchanged), this only stops one page's content from bleeding
/// through the other's empty space while they're both on screen.
class _OpaqueCupertinoTransitionsBuilder extends CupertinoPageTransitionsBuilder {
  const _OpaqueCupertinoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return super.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      ColoredBox(color: McColors.bg, child: child),
    );
  }
}

class _OpaqueZoomTransitionsBuilder extends ZoomPageTransitionsBuilder {
  const _OpaqueZoomTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return super.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      ColoredBox(color: McColors.bg, child: child),
    );
  }
}

class McTheme {
  McTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: McColors.accent2,
      brightness: Brightness.light,
      primary: McColors.accent2,
      secondary: McColors.accent,
      surface: McColors.bg,
      error: McColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: McColors.bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: McColors.text,
      ),
      cardTheme: CardThemeData(
        color: McColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(McRadii.card)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: McColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(McRadii.button),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(McRadii.button),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(McRadii.button),
          borderSide: const BorderSide(color: McColors.accent2, width: 1.5),
        ),
        hintStyle: McTextStyles.body(color: McColors.bodyText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: McColors.accent2,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(McRadii.button)),
          textStyle: McTextStyles.heading(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      textTheme: TextTheme(
        headlineMedium: McTextStyles.heading(fontSize: 28),
        headlineSmall: McTextStyles.heading(fontSize: 22),
        titleLarge: McTextStyles.heading(fontSize: 19),
        bodyLarge: McTextStyles.body(fontSize: 15),
        bodyMedium: McTextStyles.body(fontSize: 14),
        bodySmall: McTextStyles.body(fontSize: 12, color: McColors.bodyText),
      ),
      dividerTheme: const DividerThemeData(color: McColors.divider, thickness: 1),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: _OpaqueCupertinoTransitionsBuilder(),
          TargetPlatform.android: _OpaqueZoomTransitionsBuilder(),
        },
      ),
    );
  }
}
