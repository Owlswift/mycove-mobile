import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../core/widgets/ch_underline_tabs.dart';
import '../../../../state/app_notifier.dart';
import '../widgets/poll_card.dart';

class PollsPage extends ConsumerStatefulWidget {
  const PollsPage({super.key});

  @override
  ConsumerState<PollsPage> createState() => _PollsPageState();
}

class _PollsPageState extends ConsumerState<PollsPage> {
  bool _showActive = true;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final active = s.polls.where((p) => p.closesIn != 'Closed').toList();
    final completed = s.polls.where((p) => p.closesIn == 'Closed').toList();
    final shown = _showActive ? active : completed;

    Future<void> vote(String pollId, String optionId) async {
      final error = await notifier.votePoll(pollId, optionId);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }

    return Column(
      children: [
        const ChGenericHeader(title: 'Polls'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ChUnderlineTabs(
            options: [
              ChUnderlineTabOption(label: 'Active (${active.length})', selected: _showActive, onSelect: () => setState(() => _showActive = true)),
              ChUnderlineTabOption(label: 'Completed', selected: !_showActive, onSelect: () => setState(() => _showActive = false)),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: notifier.refreshPolls,
            child: shown.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
                    children: [
                      Icon(Icons.poll_outlined, size: 44, color: ChColors.neutralN(400)),
                      const SizedBox(height: 12),
                      Text(
                        _showActive ? 'No active polls' : 'No completed polls yet',
                        textAlign: TextAlign.center,
                        style: ChTextStyles.body(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                    itemCount: shown.length,
                    itemBuilder: (context, i) {
                      final poll = shown[i];
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
