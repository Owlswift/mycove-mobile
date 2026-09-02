import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
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
                Icon(Icons.check_circle_outline_rounded, size: 40, color: McColors.accent2N(400)),
                const SizedBox(height: 10),
                Text(
                  'No residents currently owe dues.',
                  textAlign: TextAlign.center,
                  style: McTextStyles.body(fontSize: 14, color: McColors.bodyText),
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Text(
                  '${owing.length} resident${owing.length == 1 ? '' : 's'} owing dues',
                  style: McTextStyles.body(fontSize: 12, fontWeight: FontWeight.w700, color: McColors.bodyText)
                      .copyWith(letterSpacing: 1),
                ),
                const SizedBox(height: 10),
                for (final r in owing)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(boxShadow: McColors.cardShadow, color: McColors.surface, borderRadius: BorderRadius.circular(McRadii.card)),
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
                                  Text(r.fullName, style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600)),
                                  if (r.house != null && r.house!.isNotEmpty)
                                    Text(r.house!, style: McTextStyles.body(fontSize: 12.5, color: McColors.bodyText)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: McColors.danger.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(McRadii.pill),
                              ),
                              child: Text(
                                '${r.monthsOwed} month${r.monthsOwed == 1 ? '' : 's'} owing',
                                style: McTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: McColors.danger),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Balance', style: McTextStyles.body(fontSize: 12.5, color: McColors.bodyText)),
                            Text(formatNaira(r.balance), style: McTextStyles.body(fontSize: 13, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Last paid', style: McTextStyles.body(fontSize: 12.5, color: McColors.bodyText)),
                            Text(
                              r.lastPaidAt != null ? DateFormat('MMM d, yyyy').format(r.lastPaidAt!) : 'Never',
                              style: McTextStyles.body(fontSize: 12.5, fontWeight: FontWeight.w600),
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
