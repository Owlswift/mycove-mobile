import 'package:flutter/material.dart';

import '../theme/ch_colors.dart';
import '../theme/ch_responsive.dart';
import '../theme/ch_spacing.dart';
import '../theme/ch_text_styles.dart';

/// The "Need help?" pill used in the header row of the estate-code/login
/// screens.
class ChHelpPill extends StatelessWidget {
  const ChHelpPill({
    super.key,
    required this.onTap,
    this.color = ChColors.text,
  });

  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: context.rs(44),
        padding: EdgeInsets.symmetric(horizontal: context.rs(16)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ChColors.surface,
          borderRadius: BorderRadius.circular(ChRadii.button),
          border: Border.all(color: ChColors.divider),
          boxShadow: ChColors.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_outline_rounded, size: context.rs(20), color: color),
            SizedBox(width: context.rs(6)),
            Text(
              'Need help?',
              style: ChTextStyles.body(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
