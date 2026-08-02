import 'package:flutter/material.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
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
      decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.md)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(poll.question, style: ChTextStyles.body(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: _isClosed ? ChColors.neutralN(200) : ChColors.accent2N(200),
                  borderRadius: BorderRadius.circular(ChRadii.pill),
                ),
                child: Text(
                  poll.closesIn,
                  style: ChTextStyles.body(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _isClosed ? ChColors.neutralN(700) : ChColors.accent2N(800),
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
                      height: 38,
                      decoration: BoxDecoration(
                        color: ChColors.neutralN(200),
                        borderRadius: BorderRadius.circular(ChRadii.pill),
                      ),
                    ),
                    if (poll.voted)
                      FractionallySizedBox(
                        widthFactor: option.pct / 100,
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(color: ChColors.accentN(200), borderRadius: BorderRadius.circular(ChRadii.pill)),
                        ),
                      ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(option.label, style: ChTextStyles.body(fontSize: 13.5, fontWeight: FontWeight.w600)),
                            if (poll.voted)
                              Text(
                                '${option.pct}%',
                                style: ChTextStyles.body(fontSize: 13.5, fontWeight: FontWeight.w600),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (poll.selectedOptionId == option.id)
                      Positioned.fill(
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            border: Border.all(color: ChColors.accent, width: 2),
                            borderRadius: BorderRadius.circular(ChRadii.pill),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Text(
            poll.voteCountLabel,
            style: ChTextStyles.body(fontSize: 12, color: ChColors.neutralN(600)),
          ),
        ],
      ),
    );
  }
}
