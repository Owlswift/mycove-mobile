import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../state/app_notifier.dart';

class PollsPage extends ConsumerWidget {
  const PollsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    Future<void> vote(String pollId, String optionId) async {
      final error = await notifier.votePoll(pollId, optionId);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }

    return Column(
      children: [
        const ChGenericHeader(title: 'Polls'),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: s.polls.length,
            itemBuilder: (context, i) {
              final poll = s.polls[i];

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.md)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(poll.question, style: ChTextStyles.body(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    for (final option in poll.options)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: poll.voted ? null : () => vote(poll.id, option.id),
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
            },
          ),
        ),
      ],
    );
  }
}
