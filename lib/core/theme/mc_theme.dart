import 'package:flutter/material.dart';

import 'mc_colors.dart';
import 'mc_spacing.dart';
import 'mc_text_styles.dart';

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
    );
  }
}
