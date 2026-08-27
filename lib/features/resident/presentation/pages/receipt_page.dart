import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../state/app_notifier.dart';

class ReceiptPage extends ConsumerWidget {
  const ReceiptPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);

    return Column(
      children: [
        const McGenericHeader(title: 'Receipt'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: McColors.surface, borderRadius: BorderRadius.circular(McRadii.card)),
              child: Column(
                children: [
                  Text('Payment Receipt', style: McTextStyles.heading(fontSize: 17)),
                  Text('Ref: ${s.receiptRef}', style: McTextStyles.body(fontSize: 12, color: McColors.bodyText)),
                  const SizedBox(height: 18),
                  _row('Resident', s.currentUser?.fullName ?? ''),
                  _row('House', s.currentUser?.house ?? ''),
                  _row('Date', 'Today'),
                  _row('Method', 'Paystack'),
                  const Divider(height: 24),
                  _row('Total Paid', s.receiptAmountLabel, bold: true),
                ],
              ),
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
