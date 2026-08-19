import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_generic_header.dart';
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

    Future<void> pay(String levyId) async {
      final error = await notifier.payLevy(levyId);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }

    return Column(
      children: [
        const ChGenericHeader(title: 'Dues & Payments', showBack: false),
        Expanded(
          child: RefreshIndicator(
            onRefresh: notifier.refreshResident,
            child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ChRadii.card),
                  gradient: LinearGradient(
                    colors: [ChColors.accent2, ChColors.accent2N(900)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Text('Outstanding balance', style: ChTextStyles.body(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                    const SizedBox(height: 6),
                    Text(s.duesBalanceLabel, style: ChTextStyles.heading(fontSize: 30, color: Colors.white)),
                    const SizedBox(height: 16),
                    if (hasBalance)
                      GestureDetector(
                        onTap: () {
                          notifier.resetPayment();
                          context.push('/resident/payment');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                          decoration: BoxDecoration(color: ChColors.accent, borderRadius: BorderRadius.circular(ChRadii.button)),
                          child: Text(
                            'Pay Now',
                            style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w700, color: ChColors.accentN(900)),
                          ),
                        ),
                      )
                    else
                      Text(
                        '✓ Fully paid up',
                        style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'PAYMENT HISTORY',
                style: ChTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: ChColors.bodyText)
                    .copyWith(letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              for (final h in s.duesHistory)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: ChColors.divider))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.desc,
                              overflow: TextOverflow.ellipsis,
                              style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            Text(h.date, style: ChTextStyles.body(fontSize: 12, color: ChColors.bodyText)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${h.type == DuesEntryType.payment ? '+ ' : '- '}${formatNaira(h.amount)}',
                        style: ChTextStyles.body(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: h.type == DuesEntryType.payment ? ChColors.accent2N(700) : ChColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              Text(
                'LEVIES',
                style: ChTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: ChColors.bodyText)
                    .copyWith(letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              for (final lv in s.levies)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.card)),
                  child: Row(
                    children: [
                      Container(
                        width: context.rs(32),
                        height: context.rs(32),
                        decoration: const BoxDecoration(color: ChColors.surfaceSunken, shape: BoxShape.circle),
                        child: Icon(Icons.payments_outlined, size: context.rs(15), color: ChColors.text),
                      ),
                      SizedBox(width: context.rs(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lv.label, style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text(
                              'Due ${lv.dueDate} · ${formatNaira(lv.amount)}',
                              style: ChTextStyles.body(fontSize: 12, color: ChColors.bodyText),
                            ),
                          ],
                        ),
                      ),
                      if (lv.status == LevyStatus.unpaid)
                        GestureDetector(
                          onTap: () => pay(lv.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: ChColors.accent2, borderRadius: BorderRadius.circular(ChRadii.pill)),
                            child: Text(
                              'Pay',
                              style: ChTextStyles.body(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        )
                      else
                        Text(
                          'Paid',
                          style: ChTextStyles.body(fontSize: 12, fontWeight: FontWeight.w700, color: ChColors.accent2N(700)),
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
