import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../data/models/dues_entry.dart';
import '../../../../data/models/levy.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';

class DuesPage extends ConsumerWidget {
  const DuesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final hasBalance = s.duesBalance > 0;
    final duesLiable = s.currentUser?.duesLiable ?? true;

    Future<void> pay(String levyId) async {
      final error = await notifier.payLevy(levyId);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error, style: TextStyle(color: McColors.text))));
      }
    }

    return Column(
      children: [
        const McGenericHeader(title: 'Dues & Payments', showBack: false),
        Expanded(
          child: RefreshIndicator(
            onRefresh: notifier.refreshResident,
            child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              if (!duesLiable) ...[
                _NotLiableBanner(invitedByName: s.currentUser?.invitedByName),
                const SizedBox(height: 14),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(McRadii.card),
                  gradient: LinearGradient(
                    colors: [McColors.accent2, McColors.accent2N(900)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      duesLiable ? 'Outstanding balance' : 'Household outstanding balance',
                      style: McTextStyles.body(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 6),
                    Text(s.duesBalanceLabel, style: McTextStyles.heading(fontSize: 30, color: Colors.white)),
                    const SizedBox(height: 16),
                    if (hasBalance && duesLiable)
                      GestureDetector(
                        onTap: () {
                          notifier.resetPayment();
                          context.push('/resident/payment');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                          decoration: BoxDecoration(color: McColors.accent, borderRadius: BorderRadius.circular(McRadii.button)),
                          child: Text(
                            'Pay Now',
                            style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w700, color: McColors.accentN(900)),
                          ),
                        ),
                      )
                    else if (!hasBalance)
                      Text(
                        '✓ Fully paid up',
                        style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'PAYMENT HISTORY',
                style: McTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: McColors.bodyText)
                    .copyWith(letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              for (final h in s.duesHistory)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: McColors.divider))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                                        Text(
                              h.desc,
                              overflow: TextOverflow.ellipsis,
                              style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600, color: McColors.text),
                            ),
                            Text(h.date, style: McTextStyles.body(fontSize: 12, color: McColors.bodyText)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${h.type == DuesEntryType.payment ? '+ ' : '- '}${formatNaira(h.amount)}',
                        style: McTextStyles.body(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: h.type == DuesEntryType.payment ? McColors.accent2N(700) : McColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              Text(
                'LEVIES',
                style: McTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: McColors.bodyText)
                    .copyWith(letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              for (final lv in s.levies)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: McColors.surface, borderRadius: BorderRadius.circular(McRadii.card)),
                  child: Row(
                    children: [
                      Container(
                        width: context.rs(32),
                        height: context.rs(32),
                        decoration: const BoxDecoration(color: McColors.surfaceSunken, shape: BoxShape.circle),
                        child: Icon(Icons.payments_outlined, size: context.rs(15), color: McColors.text),
                      ),
                      SizedBox(width: context.rs(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lv.label, style: McTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600, color: McColors.text)),
                            Text(
                              'Due ${lv.dueDate} · ${formatNaira(lv.amount)}',
                              style: McTextStyles.body(fontSize: 12, color: McColors.text),
                            ),
                          ],
                        ),
                      ),
                      if (lv.status == LevyStatus.unpaid)
                        if (duesLiable)
                          GestureDetector(
                            onTap: () => pay(lv.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(color: McColors.accent2, borderRadius: BorderRadius.circular(McRadii.pill)),
                              child: Text(
                                'Pay',
                                style: McTextStyles.body(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ),
                          )
                        else
                          Text(
                            'Owed',
                            style: McTextStyles.body(fontSize: 12, fontWeight: FontWeight.w700, color: McColors.danger),
                          )
                      else
                        Text(
                          'Paid',
                          style: McTextStyles.body(fontSize: 12, fontWeight: FontWeight.w700, color: McColors.accent2N(700)),
                        ),
                    ],
                  ),
                ),
            ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Shown above the balance/history/levies sections for a resident who
/// joined via a household invitation — they aren't personally charged (see
/// User.duesLiable), but can still see the household's actual dues/levy
/// standing below; they just can't pay it themselves from here.
class _NotLiableBanner extends StatelessWidget {
  const _NotLiableBanner({required this.invitedByName});

  final String? invitedByName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: McColors.surface,
        borderRadius: BorderRadius.circular(McRadii.card),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: McColors.accent2),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              invitedByName != null
                  ? "You're not billed for dues or levies — this is $invitedByName's household standing, for your information."
                  : "You're not billed for dues or levies — this is your household's standing, for your information.",
              style: McTextStyles.body(fontSize: 12.5, color: McColors.bodyText, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
