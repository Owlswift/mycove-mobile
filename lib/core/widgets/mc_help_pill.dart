import 'package:flutter/material.dart';

import '../theme/mc_colors.dart';
import '../theme/mc_responsive.dart';
import '../theme/mc_spacing.dart';
import '../theme/mc_text_styles.dart';

/// The "Need help?" pill used in the header row of the estate-code/login
/// screens.
class McHelpPill extends StatelessWidget {
  const McHelpPill({
    super.key,
    required this.onTap,
    this.color = McColors.text,
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
          color: McColors.surface,
          borderRadius: BorderRadius.circular(McRadii.button),
          border: Border.all(color: McColors.divider),
          boxShadow: McColors.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_outline_rounded, size: context.rs(20), color: color),
            SizedBox(width: context.rs(6)),
            Text(
              'Need help?',
              style: McTextStyles.body(
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
