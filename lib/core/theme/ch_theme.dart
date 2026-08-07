import 'package:flutter/material.dart';

import 'ch_colors.dart';
import 'ch_spacing.dart';
import 'ch_text_styles.dart';

class ChTheme {
  ChTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: ChColors.accent2,
      brightness: Brightness.light,
      primary: ChColors.accent2,
      secondary: ChColors.accent,
      surface: ChColors.bg,
      error: ChColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ChColors.bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: ChColors.text,
      ),
      cardTheme: CardThemeData(
        color: ChColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ChRadii.card)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ChColors.surfaceSunken,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ChRadii.button),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ChRadii.button),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ChRadii.button),
          borderSide: const BorderSide(color: ChColors.accent2, width: 1.5),
        ),
        hintStyle: ChTextStyles.body(color: ChColors.neutralN(600)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ChColors.accent2,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ChRadii.button)),
          textStyle: ChTextStyles.heading(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      textTheme: TextTheme(
        headlineMedium: ChTextStyles.heading(fontSize: 28),
        headlineSmall: ChTextStyles.heading(fontSize: 22),
        titleLarge: ChTextStyles.heading(fontSize: 19),
        bodyLarge: ChTextStyles.body(fontSize: 15),
        bodyMedium: ChTextStyles.body(fontSize: 14),
        bodySmall: ChTextStyles.body(fontSize: 12, color: ChColors.neutralN(600)),
      ),
      dividerTheme: const DividerThemeData(color: ChColors.divider, thickness: 1),
    );
  }
}
