import 'package:flutter/material.dart';

import '../theme/mc_colors.dart';
import '../theme/mc_responsive.dart';
import '../theme/mc_text_styles.dart';

/// Back-chevron + title + optional trailing action, used by every
/// non-dashboard resident screen and the guard screens.
///
/// Three looks, matching the header treatments in the mockups:
///  - default ([centerTitle] true): bare back chevron, title centered on
///    the row via symmetric left/right spacers matching the trailing
///    icon's width — every inner page's title must be centered, not
///    left-aligned next to the chevron.
///  - [chipStyle]: back/trailing rendered as bordered circular icon
///    buttons, title centered (Project Details, notice detail)
///  - `centerTitle: false`: bare back chevron with a left-aligned title —
///    kept only for a caller that deliberately wants the old look; nothing
///    in the app currently opts into it.
class McGenericHeader extends StatelessWidget {
  const McGenericHeader({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.trailing,
    this.chipStyle = false,
    this.centerTitle = true,
  });

  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool chipStyle;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    if (chipStyle) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20, context.rs(6), 20, context.rs(14)),
        child: Row(
          children: [
            if (showBack)
              _HeaderChip(onTap: onBack ?? () => Navigator.of(context).maybePop(), child: Icon(Icons.arrow_back, size: context.rs(18)))
            else
              SizedBox(width: context.rs(40)),
            Expanded(
              child: Text(title, textAlign: TextAlign.center, style: McTextStyles.heading(fontSize: 17)),
            ),
            trailing ?? SizedBox(width: context.rs(40)),
          ],
        ),
      );
    }

    if (centerTitle) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20, context.rs(6), 20, context.rs(14)),
        child: Row(
          children: [
            SizedBox(
              width: context.rs(40),
              child: showBack
                  ? GestureDetector(
                      onTap: onBack ?? () => Navigator.of(context).maybePop(),
                      child: Icon(Icons.arrow_back, size: context.rs(20), color: McColors.text),
                    )
                  : null,
            ),
            Expanded(
              child: Text(title, textAlign: TextAlign.center, style: McTextStyles.heading(fontSize: 19)),
            ),
            SizedBox(width: context.rs(40), child: trailing),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(20, context.rs(6), 20, context.rs(14)),
      child: Row(
        children: [
          if (showBack)
            GestureDetector(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              child: SizedBox(
                width: context.rs(24),
                child: Icon(Icons.arrow_back, size: context.rs(20), color: McColors.text),
              ),
            ),
          Expanded(child: Text(title, style: McTextStyles.heading(fontSize: 19))),
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
        width: context.rs(40),
        height: context.rs(40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: McColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: McColors.divider),
        ),
        child: IconTheme(data: const IconThemeData(color: McColors.text), child: child),
      ),
    );
  }
}
