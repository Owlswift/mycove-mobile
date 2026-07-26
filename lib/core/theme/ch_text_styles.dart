import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ch_colors.dart';

/// Headings use Caprasimo, body text uses Figtree — matching the mockup's
/// --font-heading / --font-body tokens.
class ChTextStyles {
  ChTextStyles._();

  static TextStyle heading({double fontSize = 22, Color color = ChColors.text}) {
    return GoogleFonts.caprasimo(fontSize: fontSize, color: color, height: 1.12);
  }

  static TextStyle body({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w400,
    Color color = ChColors.text,
  }) {
    return GoogleFonts.figtree(fontSize: fontSize, fontWeight: fontWeight, color: color, height: 1.4);
  }
}
