import 'package:flutter/material.dart';

import '../theme/ch_colors.dart';
import '../theme/ch_spacing.dart';
import '../theme/ch_text_styles.dart';

class ChFilterChipOption {
  const ChFilterChipOption({required this.label, required this.onSelect, required this.selected});

  final String label;
  final VoidCallback onSelect;
  final bool selected;
}

/// Horizontally scrollable row of standalone filter chips — selected chip
/// fills solid green, unselected chips are outlined. Used by the Notices
/// category filter.
class ChFilterChips extends StatelessWidget {
  const ChFilterChips({super.key, required this.options});

  final List<ChFilterChipOption> options;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: option.onSelect,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: option.selected ? ChColors.accent2 : ChColors.surface,
                    borderRadius: BorderRadius.circular(ChRadii.pill),
                    border: option.selected ? null : Border.all(color: ChColors.divider),
                  ),
                  child: Text(
                    option.label,
                    style: ChTextStyles.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: option.selected ? Colors.white : ChColors.neutralN(700),
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
