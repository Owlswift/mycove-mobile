import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../data/models/notification_item.dart';
import '../../../../data/models/utility_purchase.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';

const _monthLabels = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class UtilityHistoryPage extends ConsumerWidget {
  const UtilityHistoryPage({super.key, this.type});

  /// 'ELECTRICITY' | 'AIRTIME' | null. Null means "all types" — used by the
  /// voice assistant's CHECK_BALANCE/TRANSACTION_HISTORY intents, which
  /// land here with a wallet-balance header rather than a single-type list.
  final String? type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    var purchases = type == null
        ? s.utilityPurchases
        : s.utilityPurchases.where((p) => p.type == type).toList();
    final filterMonth = s.historyFilterMonth;
    final filterYear = s.historyFilterYear;
    if (filterMonth != null && filterYear != null) {
      purchases = purchases
          .where((p) => p.createdAt.month == filterMonth && p.createdAt.year == filterYear)
          .toList();
    }
    final title = switch (type) {
      'ELECTRICITY' => 'Electricity History',
      'AIRTIME' => 'Airtime History',
      _ => 'Transactions',
    };

    return Column(
      children: [
        ChGenericHeader(
          title: title,
          centerTitle: true,
          onBack: () {
            notifier.clearHistoryFilter();
            context.pop();
          },
        ),
        if (filterMonth != null && filterYear != null)
          Padding(
            padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(14)),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.rs(16)),
              decoration: BoxDecoration(
                color: ChColors.accent2,
                borderRadius: BorderRadius.circular(ChRadii.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total in ${_monthLabels[filterMonth - 1]}',
                    style: ChTextStyles.body(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  SizedBox(height: context.rs(4)),
                  Text(
                    formatNaira(purchases.fold<int>(0, (sum, p) => sum + p.amount)),
                    style: ChTextStyles.heading(fontSize: 26, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        if (type == null && filterMonth == null)
          Padding(
            padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(14)),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.rs(16)),
              decoration: BoxDecoration(
                color: ChColors.accent2,
                borderRadius: BorderRadius.circular(ChRadii.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CommunityHub Balance',
                    style: ChTextStyles.body(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  SizedBox(height: context.rs(4)),
                  Text(
                    s.walletBalanceLabel,
                    style: ChTextStyles.heading(fontSize: 26, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: purchases.isEmpty
              ? Center(
                  child: Text(
                    'No purchases yet.',
                    style: ChTextStyles.body(fontSize: 13.5, color: ChColors.bodyText),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    context.rs(20),
                    0,
                    context.rs(20),
                    context.rs(24),
                  ),
                  itemCount: purchases.length,
                  separatorBuilder: (_, _) => SizedBox(height: context.rs(10)),
                  itemBuilder: (_, i) => _HistoryTile(purchase: purchases[i]),
                ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.purchase});

  final UtilityPurchase purchase;

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String statusLabel;
    switch (purchase.status) {
      case UtilityPurchaseStatus.successful:
        statusColor = ChColors.accent2;
        statusLabel = 'Successful';
      case UtilityPurchaseStatus.failed:
        statusColor = ChColors.danger;
        statusLabel = 'Failed';
      case UtilityPurchaseStatus.pending:
        statusColor = ChColors.warning;
        statusLabel = 'Pending';
    }

    return Container(
      padding: EdgeInsets.all(context.rs(14)),
      decoration: BoxDecoration(
        color: ChColors.surface,
        borderRadius: BorderRadius.circular(ChRadii.md),
        boxShadow: ChColors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatNaira(purchase.amount),
                  style: ChTextStyles.body(fontSize: 14.5, fontWeight: FontWeight.w700, color: ChColors.text),
                ),
                SizedBox(height: context.rs(3)),
                Text(
                  relativeTime(purchase.createdAt),
                  style: ChTextStyles.body(fontSize: 12, color: ChColors.bodyText),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.rs(10), vertical: context.rs(5)),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(ChRadii.pill),
            ),
            child: Text(
              statusLabel,
              style: ChTextStyles.body(fontSize: 11.5, fontWeight: FontWeight.w700, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
