import 'package:flutter/material.dart';

import '../theme/ch_colors.dart';
import '../theme/ch_text_styles.dart';

/// Back-chevron + title + optional trailing action, used by every
/// non-dashboard resident screen and the guard screens.
///
/// Two looks, matching the two header treatments in the mockups:
///  - default: bare back chevron, left-aligned title
///  - [chipStyle]: back/trailing rendered as bordered circular icon
///    buttons, title centered (Project Details, notice detail)
class ChGenericHeader extends StatelessWidget {
  const ChGenericHeader({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.trailing,
    this.chipStyle = false,
  });

  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool chipStyle;

  @override
  Widget build(BuildContext context) {
    if (chipStyle) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
        child: Row(
          children: [
            if (showBack)
              _HeaderChip(onTap: onBack ?? () => Navigator.of(context).maybePop(), child: const Icon(Icons.arrow_back, size: 18))
            else
              const SizedBox(width: 40),
            Expanded(
              child: Text(title, textAlign: TextAlign.center, style: ChTextStyles.heading(fontSize: 17)),
            ),
            trailing ?? const SizedBox(width: 40),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: Row(
        children: [
          if (showBack)
            GestureDetector(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              child: const SizedBox(
                width: 24,
                child: Icon(Icons.arrow_back, size: 20, color: ChColors.text),
              ),
            ),
          Expanded(child: Text(title, style: ChTextStyles.heading(fontSize: 19))),
          ?trailing,
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ChColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: ChColors.divider),
        ),
        child: IconTheme(data: const IconThemeData(color: ChColors.text), child: child),
      ),
    );
  }
}
