import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../data/models/notification_item.dart';
import '../../../../data/models/utility_purchase.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';

const _monthLabels = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
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
          .where(
            (p) =>
                p.createdAt.month == filterMonth &&
                p.createdAt.year == filterYear,
          )
          .toList();
    }
    final title = switch (type) {
      'ELECTRICITY' => 'Electricity History',
      'AIRTIME' => 'Airtime History',
      _ => 'Transactions',
    };

    return Column(
      children: [
        McGenericHeader(
          title: title,
          centerTitle: true,
          onBack: () {
            notifier.clearHistoryFilter();
            context.pop();
          },
        ),
        if (filterMonth != null && filterYear != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.rs(20),
              0,
              context.rs(20),
              context.rs(14),
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.rs(16)),
              decoration: BoxDecoration(
                color: McColors.accent2,
                borderRadius: BorderRadius.circular(McRadii.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total in ${_monthLabels[filterMonth - 1]}',
                    style: McTextStyles.body(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  SizedBox(height: context.rs(4)),
                  Text(
                    formatNaira(
                      purchases.fold<int>(0, (sum, p) => sum + p.amount),
                    ),
                    style: McTextStyles.heading(
                      fontSize: 26,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (type == null && filterMonth == null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.rs(20),
              0,
              context.rs(20),
              context.rs(14),
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.rs(16)),
              decoration: BoxDecoration(
                color: McColors.accent2,
                borderRadius: BorderRadius.circular(McRadii.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MyCove Balance',
                    style: McTextStyles.body(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  SizedBox(height: context.rs(4)),
                  Text(
                    s.walletBalanceLabel,
                    style: McTextStyles.heading(
                      fontSize: 26,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: notifier.refreshResident,
            child: purchases.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      context.rs(20),
                      context.rs(40),
                      context.rs(20),
                      context.rs(24),
                    ),
                    children: [
                      Center(
                        child: Text(
                          'No purchases yet.',
                          textAlign: TextAlign.center,
                          style: McTextStyles.body(
                            fontSize: 13.5,
                            color: McColors.bodyText,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      context.rs(20),
                      0,
                      context.rs(20),
                      context.rs(24),
                    ),
                    itemCount: purchases.length,
                    separatorBuilder: (_, _) =>
                        SizedBox(height: context.rs(10)),
                    itemBuilder: (_, i) => _HistoryTile(purchase: purchases[i]),
                  ),
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
        statusColor = McColors.accent2;
        statusLabel = 'Successful';
      case UtilityPurchaseStatus.failed:
        statusColor = McColors.danger;
        statusLabel = 'Failed';
      case UtilityPurchaseStatus.pending:
        statusColor = McColors.warning;
        statusLabel = 'Pending';
    }

    return GestureDetector(
      onTap: () =>
          context.push('/resident/utility-history/${purchase.id}/receipt'),
      child: Container(
      padding: EdgeInsets.all(context.rs(14)),
      decoration: BoxDecoration(
        color: McColors.surface,
        borderRadius: BorderRadius.circular(McRadii.md),
        boxShadow: McColors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatNaira(purchase.amount),
                  style: McTextStyles.body(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: McColors.text,
                  ),
                ),
                SizedBox(height: context.rs(3)),
                Text(
                  relativeTime(purchase.createdAt),
                  style: McTextStyles.body(
                    fontSize: 12,
                    color: McColors.bodyText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.rs(10),
              vertical: context.rs(5),
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(McRadii.pill),
            ),
            child: Text(
              statusLabel,
              style: McTextStyles.body(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
