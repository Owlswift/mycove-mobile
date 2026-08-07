import 'package:flutter/material.dart';

import '../theme/ch_colors.dart';
import '../theme/ch_spacing.dart';
import '../theme/ch_text_styles.dart';

enum ChButtonVariant { primary, secondary }

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
    final isPrimary = variant == ChButtonVariant.primary;
    final child = Container(
      width: expand ? double.infinity : null,
      padding: const EdgeInsets.symmetric(vertical: 13),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? const LinearGradient(
                colors: [ChColors.accent2, Color(0xff56633f)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPrimary ? null : ChColors.surface,
        borderRadius: BorderRadius.circular(ChRadii.pill),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(ChColors.bg),
              ),
            )
          : Text(
              label,
              style: ChTextStyles.heading(fontSize: 14, color: isPrimary ? ChColors.bg : ChColors.text),
            ),
    );

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Opacity(opacity: onPressed == null ? 0.45 : 1, child: child),
    );
  }
}
