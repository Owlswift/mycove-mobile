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
        fillColor: ChColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ChRadii.sm),
          borderSide: BorderSide(color: ChColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ChRadii.sm),
          borderSide: BorderSide(color: ChColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ChRadii.sm),
          borderSide: const BorderSide(color: ChColors.accent),
        ),
        hintStyle: ChTextStyles.body(color: ChColors.neutralN(600)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ChColors.accent2,
          foregroundColor: ChColors.bg,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ChRadii.pill)),
          textStyle: ChTextStyles.heading(fontSize: 15, color: ChColors.bg),
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
