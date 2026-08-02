import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
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
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.card)),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: ChColors.accentN(100), shape: BoxShape.circle),
                      child: Icon(Icons.receipt_long_outlined, size: 20, color: ChColors.accentN(800)),
                    ),
                    const SizedBox(height: 10),
                    Text('Outstanding balance', style: ChTextStyles.body(fontSize: 13, color: ChColors.neutralN(600))),
                    const SizedBox(height: 6),
                    Text(s.duesBalanceLabel, style: ChTextStyles.heading(fontSize: 28)),
                    const SizedBox(height: 14),
                    if (hasBalance)
                      ChButton(
                        label: 'Pay Now',
                        onPressed: () {
                          notifier.resetPayment();
                          context.push('/resident/payment');
                        },
                      )
                    else
                      Text(
                        '✓ Fully paid up',
                        style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600, color: ChColors.accent2N(700)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'PAYMENT HISTORY',
                style: ChTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: ChColors.neutralN(600))
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
                            Text(h.date, style: ChTextStyles.body(fontSize: 12, color: ChColors.neutralN(600))),
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
                style: ChTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: ChColors.neutralN(600))
                    .copyWith(letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              for (final lv in s.levies)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.md)),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: ChColors.neutralN(200), shape: BoxShape.circle),
                        child: const Icon(Icons.payments_outlined, size: 15, color: ChColors.text),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lv.label, style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text(
                              'Due ${lv.dueDate} · ${formatNaira(lv.amount)}',
                              style: ChTextStyles.body(fontSize: 12, color: ChColors.neutralN(600)),
                            ),
                          ],
                        ),
                      ),
                      if (lv.status == LevyStatus.unpaid)
                        GestureDetector(
                          onTap: () => pay(lv.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [ChColors.accent2, Color(0xff56633f)]),
                              borderRadius: BorderRadius.circular(ChRadii.pill),
                            ),
                            child: Text(
                              'Pay',
                              style: ChTextStyles.body(fontSize: 12.5, fontWeight: FontWeight.w600, color: ChColors.bg),
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
