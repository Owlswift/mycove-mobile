import 'package:flutter/material.dart';

import '../theme/ch_colors.dart';
import '../theme/ch_text_styles.dart';

class ChUnderlineTabOption {
  const ChUnderlineTabOption({required this.label, required this.onSelect, required this.selected});

  final String label;
  final VoidCallback onSelect;
  final bool selected;
}

/// Full-width segmented tab row — active tab gets bold text + a green
/// bottom border, inactive tabs are muted grey. Used by Visitor Pass
/// (Active/History), Polls (Active/Completed), Complaints (My Complaints/
/// All), and Projects (All/In Progress/Completed/Upcoming).
class ChUnderlineTabs extends StatelessWidget {
  const ChUnderlineTabs({super.key, required this.options});

  final List<ChUnderlineTabOption> options;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final option in options)
          Expanded(
            child: GestureDetector(
              onTap: option.onSelect,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: option.selected ? ChColors.accent2 : ChColors.divider, width: 2),
                  ),
                ),
                child: Text(
                  option.label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: ChTextStyles.body(
                    fontSize: 13.5,
                    fontWeight: option.selected ? FontWeight.w700 : FontWeight.w500,
                    color: option.selected ? ChColors.accent2 : ChColors.neutralN(600),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
