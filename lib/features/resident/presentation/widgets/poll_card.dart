import 'package:flutter/material.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../data/models/poll.dart';

/// A poll's question, live results, and (while open) tappable options to
/// vote or change a vote. Shared by the dashboard's featured poll and the
/// full Polls list so both vote the same way and agree on what "closed"
/// looks like.
class PollCard extends StatelessWidget {
  const PollCard({super.key, required this.poll, required this.onVote});

  final Poll poll;
  final void Function(String optionId) onVote;

  bool get _isClosed => poll.closesIn == 'Closed';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: McColors.surface, borderRadius: BorderRadius.circular(McRadii.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(poll.question, style: McTextStyles.body(fontSize: 15, fontWeight: FontWeight.w500, color: McColors.text)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: _isClosed ? McColors.neutralN(200) : McColors.accent2N(200),
                  borderRadius: BorderRadius.circular(McRadii.pill),
                ),
                child: Text(
                  poll.closesIn,
                  style: McTextStyles.body(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _isClosed ? McColors.text : McColors.accent2N(800),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final option in poll.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: _isClosed ? null : () => onVote(option.id),
                child: Stack(
                  children: [
                    Container(
                      height: context.rs(38),
                      decoration: BoxDecoration(
                        color: McColors.neutralN(200),
                        borderRadius: BorderRadius.circular(McRadii.pill),
                      ),
                    ),
                    if (poll.voted)
                      FractionallySizedBox(
                        widthFactor: option.pct / 100,
                        child: Container(
                          height: context.rs(38),
                          decoration: BoxDecoration(color: McColors.accent2N(200), borderRadius: BorderRadius.circular(McRadii.pill)),
                        ),
                      ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(option.label, style: McTextStyles.body(fontSize: 12, fontWeight: FontWeight.w500, color: McColors.text)),
                            if (poll.voted)
                              Text(
                                '${option.pct}%',
                                style: McTextStyles.body(fontSize: 12, fontWeight: FontWeight.w600, color: McColors.text),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (poll.selectedOptionId == option.id)
                      Positioned.fill(
                        child: Container(
                          height: context.rs(38),
                          decoration: BoxDecoration(
                            border: Border.all(color: McColors.accent2, width: 2),
                            borderRadius: BorderRadius.circular(McRadii.pill),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Text(
            poll.voteCountLabel,
            style: McTextStyles.body(fontSize: 12, color: McColors.text),
          ),
        ],
      ),
    );
  }
}
