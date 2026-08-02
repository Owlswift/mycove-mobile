import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../state/app_notifier.dart';
import '../widgets/poll_card.dart';

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
          child: RefreshIndicator(
            onRefresh: notifier.refreshPolls,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: s.polls.length,
              itemBuilder: (context, i) {
                final poll = s.polls[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: PollCard(poll: poll, onVote: (optionId) => vote(poll.id, optionId)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
