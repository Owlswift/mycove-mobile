import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';
import '../widgets/chairman_widgets.dart';

/// Estate projects with how far along they are and how their money is being
/// used — funds allocated by the finance secretary against what has been
/// spent on approved invoices.
class ChairmanProjectsPage extends ConsumerWidget {
  const ChairmanProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final treasury = s.chairman.treasury;

    return ChairmanList(
      onRefresh: notifier.refreshChairman,
      emptyIcon: Icons.apartment_outlined,
      emptyMessage: 'No projects yet.',
      children: [
        if (s.projects.isNotEmpty)
          ChairmanCard(
            child: Row(
              children: [
                Expanded(child: _Figure(label: 'Collected', value: formatNaira(treasury.totalCollected))),
                Expanded(child: _Figure(label: 'Allocated', value: formatNaira(treasury.totalAllocated))),
                Expanded(child: _Figure(label: 'Balance', value: formatNaira(treasury.treasuryBalance))),
              ],
            ),
          ),
        for (final p in s.projects)
          Builder(
            builder: (_) {
              final funds = treasury.fundsFor(p.id);
              return ChairmanCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(p.title, style: McTextStyles.body(fontSize: 14.5, fontWeight: FontWeight.w600)),
                        ),
                        StatusPill(p.status, color: p.isCompleted ? McColors.accent2 : McColors.warning),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (p.progress / 100).clamp(0, 1).toDouble(),
                        minHeight: 7,
                        backgroundColor: McColors.divider,
                        valueColor: const AlwaysStoppedAnimation(McColors.accent2),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${p.progress}% complete', style: McTextStyles.body(fontSize: 12, color: McColors.bodyText)),
                    if (funds != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _Figure(label: 'Allocated', value: formatNaira(funds.allocated))),
                          Expanded(child: _Figure(label: 'Spent', value: formatNaira(funds.spent))),
                          Expanded(child: _Figure(label: 'Remaining', value: formatNaira(funds.remaining))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Donated ${formatNaira(funds.donated)}  ·  Pledged ${formatNaira(funds.pledged)}',
                        style: McTextStyles.body(fontSize: 12, color: McColors.bodyText),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: McTextStyles.body(fontSize: 13.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: McTextStyles.body(fontSize: 11.5, color: McColors.bodyText)),
      ],
    );
  }
}
