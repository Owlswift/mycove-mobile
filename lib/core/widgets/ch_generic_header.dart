import 'package:flutter/material.dart';

import '../theme/ch_colors.dart';
import '../theme/ch_text_styles.dart';

/// Back-chevron + title + optional trailing action, used by every
/// non-dashboard resident screen and the guard screens.
class ChGenericHeader extends StatelessWidget {
  const ChGenericHeader({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.trailing,
  });

  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: Row(
        children: [
          if (showBack)
            GestureDetector(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              child: const SizedBox(
                width: 24,
                child: Text('‹', style: TextStyle(fontSize: 22, color: ChColors.text)),
              ),
            ),
          Expanded(child: Text(title, style: ChTextStyles.heading(fontSize: 19))),
          ?trailing,
        ],
      ),
    );
  }
}
