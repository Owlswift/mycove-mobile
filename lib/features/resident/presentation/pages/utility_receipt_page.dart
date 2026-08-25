import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/pdf/utility_receipt_pdf.dart';
import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../data/models/utility_purchase.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';
import '../widgets/receipt_widgets.dart';

/// Receipt for a single utility purchase — reachable from history tiles and
/// the post-purchase success screen. Shows the prepaid token (copyable) and
/// offers PDF download/share via the share sheet.
class UtilityReceiptPage extends ConsumerWidget {
  const UtilityReceiptPage({super.key, required this.purchaseId});

  final String purchaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final user = s.currentUser;

    // Buy actions prepend the fresh purchase into this list immediately, so
    // anything navigable here is always found.
    final matches = s.utilityPurchases.where((p) => p.id == purchaseId).toList();
    final purchase = matches.isNotEmpty
        ? matches.first
        : (s.lastUtilityPurchase?.id == purchaseId ? s.lastUtilityPurchase : null);

    if (purchase == null) {
      return Column(
        children: [
          const ChGenericHeader(title: 'Receipt'),
          Expanded(
            child: Center(
              child: Text('Receipt not found.',
                  style: ChTextStyles.body(fontSize: 13.5)),
            ),
          ),
        ],
      );
    }

    final isElectricity = purchase.type == 'ELECTRICITY';
    final (statusLabel, statusColor) = switch (purchase.status) {
      UtilityPurchaseStatus.successful => ('Successful', ChColors.accent2),
      UtilityPurchaseStatus.failed => ('Failed', ChColors.danger),
      UtilityPurchaseStatus.pending => ('Pending', ChColors.warning),
    };

    final detailRows = [
      if (isElectricity) ...[
        if (purchase.meter != null) ...[
          receiptRow(context, 'DISCO', purchase.meter!.discoName),
          receiptRow(context, 'Meter number', purchase.meter!.meterNumber),
          receiptRow(context, 'Meter type',
              purchase.meter!.meterType.replaceAll('_', ' ').toUpperCase()),
        ],
        if ((purchase.phone ?? '').isNotEmpty)
          receiptRow(context, 'Contact phone', purchase.phone!),
      ] else ...[
        if ((purchase.network ?? '').isNotEmpty)
          receiptRow(context, 'Network', purchase.network!.toUpperCase()),
        receiptRow(context, 'Recipient', purchase.phone ?? ''),
      ],
      receiptRow(context, 'Amount paid', formatNaira(purchase.amount), bold: true),
      if ((purchase.provider ?? '').isNotEmpty)
        receiptRow(context, 'Vend provider', purchase.provider!),
    ];

    return Column(
      children: [
        const ChGenericHeader(title: 'Receipt'),
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), 24),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(context.rs(18)),
                  decoration: BoxDecoration(
                    color: ChColors.surface,
                    borderRadius: BorderRadius.circular(ChRadii.card),
                    boxShadow: ChColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('MyCove',
                            style: ChTextStyles.heading(fontSize: 18)),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: context.rs(10),
                              vertical: context.rs(4)),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(ChRadii.pill),
                          ),
                          child: Text(statusLabel,
                              style: ChTextStyles.body(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor)),
                        ),
                      ]),
                      SizedBox(height: context.rs(2)),
                      Text(
                        isElectricity
                            ? 'Electricity Purchase Receipt'
                            : 'Airtime Purchase Receipt',
                        style: ChTextStyles.body(
                            fontSize: 12, color: ChColors.bodyText),
                      ),
                      Divider(height: context.rs(22)),
                      receiptRow(context, 'Reference', purchase.id),
                      receiptRow(
                          context,
                          'Date',
                          DateFormat('d MMM yyyy · HH:mm')
                              .format(purchase.createdAt.toLocal())),
                      if ((purchase.failureReason ?? '').isNotEmpty)
                        receiptRow(context, 'Failure reason',
                            purchase.failureReason!),
                    ],
                  ),
                ),
                SizedBox(height: context.rs(14)),
                receiptSection(context, 'CUSTOMER', [
                  receiptRow(context, 'Name', user?.fullName ?? ''),
                  if ((user?.house ?? '').isNotEmpty)
                    receiptRow(context, 'House', user!.house!),
                ]),
                SizedBox(height: context.rs(14)),
                receiptSection(context, 'TRANSACTION DETAILS', detailRows),
                if ((purchase.token ?? '').isNotEmpty) ...[
                  SizedBox(height: context.rs(14)),
                  tokenCard(context, purchase.token!),
                ],
                SizedBox(height: context.rs(20)),
                ChButton(
                  label: 'Download PDF',
                  onPressed: () async {
                    await shareUtilityReceiptPdf(
                      purchase: purchase,
                      residentName: user?.fullName ?? '',
                      house: user?.house ?? '',
                      phone: purchase.phone ?? user?.phone,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}