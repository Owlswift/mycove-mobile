import 'package:flutter/material.dart';

import '../theme/mc_colors.dart';
import '../theme/mc_responsive.dart';
import '../theme/mc_spacing.dart';

/// The white rounded-square icon button (back arrow, etc.) used in the
/// header row of the estate-code/estate-found/login screens.
class McSquareIconButton extends StatelessWidget {
  const McSquareIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor = McColors.text,
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
          color: McColors.surface,
          borderRadius: BorderRadius.circular(McRadii.button),
          boxShadow: McColors.cardShadow,
        ),
        child: Icon(icon, size: context.rs(18), color: iconColor),
      ),
    );
  }
}
