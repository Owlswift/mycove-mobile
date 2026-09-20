import 'package:flutter/material.dart';

import '../theme/mc_colors.dart';
import '../theme/mc_responsive.dart';
import '../theme/mc_spacing.dart';
import '../theme/mc_text_styles.dart';

/// [outlined] is the white, bordered button (Cancel, Allow any day, Decline).
enum ChButtonVariant { primary, secondary, danger, outlined }

class McButton extends StatelessWidget {
  const McButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ChButtonVariant.primary,
    this.expand = true,
    this.isLoading = false,
    this.verticalPadding = 14,
    this.leading,
    this.selected = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ChButtonVariant variant;
  final bool expand;
  final bool isLoading;

  /// The onboarding screens' main buttons (Get Started, Continue) are 15–16 tall; forms use 14.
  final double verticalPadding;

  /// An icon shown before the label.
  final Widget? leading;

  /// For [ChButtonVariant.outlined]: shows the button as chosen (green border and text).
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final Color fill;
    final Color foreground;
    switch (variant) {
      case ChButtonVariant.primary:
        fill = McColors.accent2;
        foreground = Colors.white;
      case ChButtonVariant.secondary:
        fill = McColors.surfaceSunken;
        foreground = McColors.text;
      case ChButtonVariant.danger:
        fill = McColors.danger;
        foreground = Colors.white;
      case ChButtonVariant.outlined:
        fill = McColors.surface;
        foreground = selected ? McColors.accent2 : McColors.text;
    }

    final child = Container(
      width: expand ? double.infinity : null,
      padding: EdgeInsets.symmetric(vertical: context.rs(verticalPadding)),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(McRadii.button),
        border: variant == ChButtonVariant.outlined
            ? Border.all(color: selected ? McColors.accent2 : McColors.neutralN(300), width: selected ? 1.5 : 1)
            : null,
      ),
      child: isLoading
          ? SizedBox(
              height: context.rs(20),
              width: context.rs(20),
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(foreground)),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[leading!, SizedBox(width: context.rs(8))],
                Text(label, style: McTextStyles.body(fontSize: 15, fontWeight: FontWeight.w600, color: foreground)),
              ],
            ),
    );

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Opacity(opacity: onPressed == null ? 0.45 : 1, child: child),
    );
  }
}
