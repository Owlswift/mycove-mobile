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

class UtilityHistoryPage extends ConsumerWidget {
  const UtilityHistoryPage({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchases = ref
        .watch(appStateProvider)
        .utilityPurchases
        .where((p) => p.type == type)
        .toList();
    final title = type == 'ELECTRICITY' ? 'Electricity History' : 'Airtime History';

    return Column(
      children: [
        ChGenericHeader(title: title, centerTitle: true, onBack: () => context.pop()),
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
