import 'package:flutter/material.dart';

import '../theme/mc_colors.dart';
import '../theme/mc_text_styles.dart';

/// A text-only action in the app's own type (Inter), for links like "Edit",
/// "Review" or "Add a photo" — the stock Material TextButton uses the
/// platform font, which looks out of place next to the rest of the app.
class McTextButton extends StatelessWidget {
  const McTextButton({super.key, required this.label, required this.onPressed, this.color = McColors.accent2});

  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Text(label, style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }
}

/// One tappable row in a bottom sheet: an icon and a label in the app's type.
class McSheetOption extends StatelessWidget {
  const McSheetOption({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: McColors.text),
            const SizedBox(width: 14),
            Text(label, style: McTextStyles.body(fontSize: 15, fontWeight: FontWeight.w500, color: McColors.text)),
          ],
        ),
      ),
    );
  }
}
