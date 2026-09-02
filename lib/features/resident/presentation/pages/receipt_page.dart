import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/pdf/dues_receipt_pdf.dart';
import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../state/app_notifier.dart';

class ReceiptPage extends ConsumerWidget {
  const ReceiptPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final user = s.currentUser;
    final isLevy = s.pendingPaymentPurpose == 'LEVY';
    final methodLabel = s.paymentMethod == 'WALLET' ? 'Wallet' : 'Paystack';
    final reference = s.paymentReference ?? 'N/A';

    return Column(
      children: [
        McGenericHeader(
          title: 'Receipt',
          // The dues/levy "View Receipt" button reaches this page via
          // pushReplacement (there's no "processing" screen worth going
          // back to), which can leave this branch's Navigator with nothing
          // to pop to — an explicit destination sidesteps that entirely
          // rather than relying on maybePop().
          onBack: () => context.go('/resident/dues'),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(boxShadow: McColors.cardShadow, color: McColors.surface, borderRadius: BorderRadius.circular(McRadii.card)),
                  child: Column(
                    children: [
                      Text(isLevy ? 'Levy Payment Receipt' : 'Dues Payment Receipt', style: McTextStyles.heading(fontSize: 17)),
                      Text('Ref: $reference', style: McTextStyles.body(fontSize: 12, color: McColors.bodyText)),
                      const SizedBox(height: 18),
                      _row('Resident', user?.fullName ?? ''),
                      _row('House', user?.house ?? ''),
                      _row('Date', 'Today'),
                      _row('Method', methodLabel),
                      const Divider(height: 24),
                      _row('Total Paid', s.pendingPaymentAmountLabel, bold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                McButton(
                  label: 'Download PDF',
                  onPressed: () async {
                    await shareDuesReceiptPdf(
                      reference: reference,
                      purpose: s.pendingPaymentPurpose,
                      method: s.paymentMethod,
                      amount: s.pendingPaymentAmount,
                      residentName: user?.fullName ?? '',
                      house: user?.house ?? '',
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

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: McTextStyles.body(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: bold ? McColors.text : McColors.bodyText,
            ),
          ),
          Text(
            value,
            style: McTextStyles.body(
              fontSize: bold ? 15 : 13,
              fontWeight: FontWeight.w700,
              color: bold ? McColors.accent2N(700) : McColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
