import 'package:flutter/material.dart';

import '../../../../core/theme/mc_colors.dart';
import 'whatsapp_icon.dart';

/// The four icons the domestic staff screens use for the same four things,
/// so a number, days, hours and approval always look alike.
enum DomesticIcon { whatsapp, days, hours, approval, person }

class DomesticGlyph extends StatelessWidget {
  const DomesticGlyph(this.kind, {super.key, this.size = 22, this.color});

  final DomesticIcon kind;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? McColors.accent2;
    return switch (kind) {
      DomesticIcon.whatsapp => WhatsappIcon(size: size, color: c),
      DomesticIcon.days => Icon(
        Icons.calendar_today_outlined,
        size: size,
        color: c,
      ),
      DomesticIcon.hours => Icon(Icons.access_time, size: size, color: c),
      DomesticIcon.approval => Icon(
        Icons.shield_outlined,
        size: size,
        color: c,
      ),
      DomesticIcon.person => Icon(Icons.person_outline, size: size, color: c),
    };
  }
}

/// Soft green circle with a glyph in it — the row icon on the review and summary cards.
class DomesticIconCircle extends StatelessWidget {
  const DomesticIconCircle(this.kind, {super.key, this.size = 46});

  final DomesticIcon kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: McColors.accent2N(100),
        shape: BoxShape.circle,
      ),
      child: DomesticGlyph(kind, size: size * 0.5),
    );
  }
}
