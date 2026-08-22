import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';

/// The security desk's view of who owes the estate dues — deliberately
/// scoped to that one obligation (not project donations/pledges, which
/// aren't something a guard is ever asked about at the gate).
class GuardDuesPage extends ConsumerWidget {
  const GuardDuesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final owing = s.owingResidents;

    return RefreshIndicator(
      onRefresh: notifier.refreshGuard,
      child: owing.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.28),
                Icon(Icons.check_circle_outline_rounded, size: 40, color: ChColors.accent2N(400)),
                const SizedBox(height: 10),
                Text(
                  'No residents currently owe dues.',
                  textAlign: TextAlign.center,
                  style: ChTextStyles.body(fontSize: 14, color: ChColors.bodyText),
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Text(
                  '${owing.length} resident${owing.length == 1 ? '' : 's'} owing dues',
                  style: ChTextStyles.body(fontSize: 12, fontWeight: FontWeight.w700, color: ChColors.bodyText)
                      .copyWith(letterSpacing: 1),
                ),
                const SizedBox(height: 10),
                for (final r in owing)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.card)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.fullName, style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600)),
                                  if (r.house != null && r.house!.isNotEmpty)
                                    Text(r.house!, style: ChTextStyles.body(fontSize: 12.5, color: ChColors.bodyText)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: ChColors.danger.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(ChRadii.pill),
                              ),
                              child: Text(
                                '${r.monthsOwed} month${r.monthsOwed == 1 ? '' : 's'} owing',
                                style: ChTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: ChColors.danger),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Balance', style: ChTextStyles.body(fontSize: 12.5, color: ChColors.bodyText)),
                            Text(formatNaira(r.balance), style: ChTextStyles.body(fontSize: 13, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Last paid', style: ChTextStyles.body(fontSize: 12.5, color: ChColors.bodyText)),
                            Text(
                              r.lastPaidAt != null ? DateFormat('MMM d, yyyy').format(r.lastPaidAt!) : 'Never',
                              style: ChTextStyles.body(fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
