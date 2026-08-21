import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../data/models/utility_meter.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';

const _transactionFee = 100;

class ElectricityPaymentPage extends ConsumerWidget {
  const ElectricityPaymentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final amount = int.tryParse(s.elecAmount.trim()) ?? 0;
    final total = amount + _transactionFee;

    return Column(
      children: [
        ChGenericHeader(
          title: 'Payment',
          centerTitle: true,
          onBack: () {
            notifier.clearUtilityError();
            context.pop();
          },
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment Summary', style: ChTextStyles.heading(fontSize: 16)),
                SizedBox(height: context.rs(14)),
                _SummaryRow(label: 'Provider', value: discoShortCode(s.discos, s.elecDiscoCode)),
                SizedBox(height: context.rs(10)),
                _SummaryRow(label: 'Meter Number', value: formatMeterNumber(s.elecMeterNumber)),
                SizedBox(height: context.rs(10)),
                _SummaryRow(label: 'Amount', value: formatNaira(amount)),
                SizedBox(height: context.rs(10)),
                _SummaryRow(label: 'Transaction Fee', value: formatNaira(_transactionFee)),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: context.rs(10)),
                  child: Divider(height: 1, color: ChColors.divider),
                ),
                _SummaryRow(label: 'Total Payable', value: formatNaira(total), emphasize: true),
                SizedBox(height: context.rs(24)),
                Text('Select Payment Method', style: ChTextStyles.heading(fontSize: 16)),
                SizedBox(height: context.rs(14)),
                const _PaymentMethodTile(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Wallet Balance',
                  selected: true,
                ),
                SizedBox(height: context.rs(10)),
                const _PaymentMethodTile(
                  icon: Icons.credit_card_rounded,
                  label: 'Card Payment',
                  comingSoon: true,
                ),
                SizedBox(height: context.rs(10)),
                const _PaymentMethodTile(
                  icon: Icons.account_balance_rounded,
                  label: 'Bank Transfer',
                  comingSoon: true,
                ),
                SizedBox(height: context.rs(24)),
                if (s.utilityError.isNotEmpty) ...[
                  Text(s.utilityError, style: ChTextStyles.body(fontSize: 13, color: ChColors.danger)),
                  SizedBox(height: context.rs(12)),
                ],
                ChButton(
                  label: 'Pay ${formatNaira(total)}',
                  isLoading: s.utilityLoading,
                  onPressed: s.utilityLoading
                      ? null
                      : () async {
                          final success = await notifier.buyElectricity();
                          if (success && context.mounted) {
                            context.push('/resident/electricity/success');
                          }
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: ChTextStyles.body(
            fontSize: emphasize ? 14 : 13,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
            color: emphasize ? ChColors.text : ChColors.bodyText,
          ),
        ),
        Text(
          value,
          style: ChTextStyles.body(
            fontSize: emphasize ? 14 : 13,
            fontWeight: FontWeight.w700,
            color: ChColors.text,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.icon,
    required this.label,
    this.selected = false,
    this.comingSoon = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: comingSoon ? 0.5 : 1,
      child: GestureDetector(
        onTap: comingSoon
            ? () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('This payment method is coming soon.')),
              )
            : null,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: context.rs(14), vertical: context.rs(12)),
          decoration: BoxDecoration(
            color: selected ? ChColors.accent2N(100) : ChColors.surface,
            borderRadius: BorderRadius.circular(ChRadii.md),
            border: Border.all(color: selected ? ChColors.accent2 : ChColors.divider),
          ),
          child: Row(
            children: [
              Icon(icon, color: ChColors.bodyText, size: context.rs(20)),
              SizedBox(width: context.rs(10)),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      label,
                      style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600, color: ChColors.text),
                    ),
                    if (comingSoon) ...[
                      SizedBox(width: context.rs(8)),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: context.rs(8), vertical: context.rs(3)),
                        decoration: BoxDecoration(
                          color: ChColors.surfaceSunken,
                          borderRadius: BorderRadius.circular(ChRadii.pill),
                        ),
                        child: Text(
                          'Coming soon',
                          style: ChTextStyles.body(fontSize: 10.5, fontWeight: FontWeight.w600, color: ChColors.bodyText),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? ChColors.accent2 : ChColors.divider,
                size: context.rs(20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
