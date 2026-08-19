import 'package:flutter/material.dart';

import '../theme/ch_colors.dart';
import '../theme/ch_responsive.dart';
import '../theme/ch_spacing.dart';
import '../theme/ch_text_styles.dart';

enum ChButtonVariant { primary, secondary, danger }

class ChButton extends StatelessWidget {
  const ChButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ChButtonVariant.primary,
    this.expand = true,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ChButtonVariant variant;
  final bool expand;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final Color fill;
    final Color foreground;
    switch (variant) {
      case ChButtonVariant.primary:
        fill = ChColors.accent2;
        foreground = Colors.white;
      case ChButtonVariant.secondary:
        fill = ChColors.surfaceSunken;
        foreground = ChColors.text;
      case ChButtonVariant.danger:
        fill = ChColors.danger;
        foreground = Colors.white;
    }

    final child = Container(
      width: expand ? double.infinity : null,
      padding: EdgeInsets.symmetric(vertical: context.rs(14)),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(ChRadii.button)),
      child: isLoading
          ? SizedBox(
              height: context.rs(20),
              width: context.rs(20),
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(foreground)),
            )
          : Text(label, style: ChTextStyles.body(fontSize: 15, fontWeight: FontWeight.w600, color: foreground)),
    );

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Opacity(opacity: onPressed == null ? 0.45 : 1, child: child),
    );
  }
}
