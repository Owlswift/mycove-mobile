import 'package:flutter/material.dart';

import '../theme/ch_colors.dart';
import '../theme/ch_responsive.dart';
import '../theme/ch_spacing.dart';

/// The white rounded-square icon button (back arrow, etc.) used in the
/// header row of the estate-code/estate-found/login screens.
class ChSquareIconButton extends StatelessWidget {
  const ChSquareIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor = ChColors.text,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: context.rs(44),
        height: context.rs(44),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ChColors.surface,
          borderRadius: BorderRadius.circular(ChRadii.button),
          boxShadow: ChColors.cardShadow,
        ),
        child: Icon(icon, size: context.rs(18), color: iconColor),
      ),
    );
  }
}
