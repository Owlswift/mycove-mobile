import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';
import '../widgets/chairman_widgets.dart';

/// The chairman's landing tab: how dues collection is going, the headline
/// numbers across the estate, and who is behind on payment.
class ChairmanOverviewPage extends ConsumerWidget {
  const ChairmanOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final data = s.chairman;
    final dues = data.dues;
    final owing = dues.owing;
    final insideNow = s.accessLog.where((e) => e.exit == null).length;

    return ChairmanList(
      onRefresh: notifier.refreshChairman,
      emptyMessage: 'Loading the estate overview…',
      children: !data.loaded
          ? const []
          : [
              ChairmanCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dues collected', style: McTextStyles.body(fontSize: 13, color: McColors.bodyText)),
                    const SizedBox(height: 4),
                    Text(formatNaira(dues.collected), style: McTextStyles.heading(fontSize: 28)),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: dues.collectionRate,
                        minHeight: 8,
                        backgroundColor: McColors.divider,
                        valueColor: const AlwaysStoppedAnimation(McColors.accent2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(dues.collectionRate * 100).round()}% of ${formatNaira(dues.expected)} billed',
                          style: McTextStyles.body(fontSize: 12.5, color: McColors.bodyText),
                        ),
                        Text(
                          '${formatNaira(dues.outstanding)} outstanding',
                          style: McTextStyles.body(fontSize: 12.5, fontWeight: FontWeight.w600, color: McColors.danger),
                        ),
                      ],
                    ),
                    if (dues.monthlyAmount == null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'No monthly dues rate has been set yet, so nothing is being billed.',
                        style: McTextStyles.body(fontSize: 12, color: McColors.warning),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _Stat(label: 'Open complaints', value: '${data.openComplaints}')),
                  const SizedBox(width: 10),
                  Expanded(child: _Stat(label: 'Visitors inside', value: '$insideNow')),
                  const SizedBox(width: 10),
                  Expanded(child: _Stat(label: 'Treasury', value: formatNaira(data.treasury.treasuryBalance))),
                ],
              ),
              const SizedBox(height: 10),
              SectionLabel('Owing dues (${owing.length})'),
              if (owing.isEmpty)
                ChairmanCard(
                  child: Text(
                    'Every resident is up to date.',
                    style: McTextStyles.body(fontSize: 14, color: McColors.bodyText),
                  ),
                )
              else
                for (final r in owing)
                  ChairmanCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.fullName, style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600)),
                              if (r.house != null && r.house!.isNotEmpty)
                                Text(r.house!, style: McTextStyles.body(fontSize: 12.5, color: McColors.bodyText)),
                            ],
                          ),
                        ),
                        Text(
                          formatNaira(r.duesBalance),
                          style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w700, color: McColors.danger),
                        ),
                      ],
                    ),
                  ),
            ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ChairmanCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: McTextStyles.heading(fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(label, style: McTextStyles.body(fontSize: 11.5, color: McColors.bodyText)),
        ],
      ),
    );
  }
}
