import 'package:flutter/material.dart';

import '../theme/mc_colors.dart';
import '../theme/mc_responsive.dart';
import '../theme/mc_spacing.dart';
import '../theme/mc_text_styles.dart';

class McPillTabOption {
  const McPillTabOption({required this.label, required this.onSelect, required this.selected});

  final String label;
  final VoidCallback onSelect;
  final bool selected;
}

/// The segmented pill toggle reused for Resident/Guard login, visitor-pass
/// validity, and complaint category selection.
class McPillTabs extends StatelessWidget {
  const McPillTabs({super.key, required this.options});

  final List<McPillTabOption> options;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: McColors.divider),
        borderRadius: BorderRadius.circular(McRadii.pill),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < options.length; i++)
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    border: i > 0 ? Border(left: BorderSide(color: McColors.divider)) : null,
                    color: options[i].selected ? McColors.accent2 : null,
                  ),
                  child: GestureDetector(
                    onTap: options[i].onSelect,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.rs(12),
                        vertical: context.rs(8),
                      ),
                      child: Text(
                        options[i].label,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: McTextStyles.body(
                          fontSize: 13,
                          fontWeight: options[i].selected ? FontWeight.w600 : FontWeight.w400,
                          color: options[i].selected ? Colors.white : McColors.bodyText,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
