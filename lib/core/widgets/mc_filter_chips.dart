import 'package:flutter/material.dart';

import '../theme/mc_colors.dart';
import '../theme/mc_responsive.dart';
import '../theme/mc_spacing.dart';
import '../theme/mc_text_styles.dart';

class McFilterChipOption {
  const McFilterChipOption({required this.label, required this.onSelect, required this.selected});

  final String label;
  final VoidCallback onSelect;
  final bool selected;
}

/// Horizontally scrollable row of standalone filter chips — selected chip
/// fills solid green, unselected chips are outlined. Used by the Notices
/// category filter.
class McFilterChips extends StatelessWidget {
  const McFilterChips({super.key, required this.options});

  final List<McFilterChipOption> options;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options)
            Padding(
              padding: EdgeInsets.only(right: context.rs(8)),
              child: GestureDetector(
                onTap: option.onSelect,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.rs(16),
                    vertical: context.rs(9),
                  ),
                  decoration: BoxDecoration(
                    color: option.selected ? McColors.accent2 : McColors.surface,
                    borderRadius: BorderRadius.circular(McRadii.pill),
                    border: option.selected ? null : Border.all(color: McColors.divider),
                  ),
                  child: Text(
                    option.label,
                    style: McTextStyles.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: option.selected ? Colors.white : McColors.bodyText,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
