import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_generic_header.dart';
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
    final hasSufficientBalance = s.walletBalance >= total;

    return Column(
      children: [
        McGenericHeader(
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
                Text('Payment Summary', style: McTextStyles.heading(fontSize: 16)),
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
                  child: Divider(height: 1, color: McColors.divider),
                ),
                _SummaryRow(label: 'Total Payable', value: formatNaira(total), emphasize: true),
                SizedBox(height: context.rs(24)),
                Text('Select Payment Method', style: McTextStyles.heading(fontSize: 16)),
                SizedBox(height: context.rs(14)),
                _PaymentMethodTile(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Wallet Balance',
                  subtitle: s.walletBalanceLabel,
                  selected: true,
                  insufficientBalance: !hasSufficientBalance,
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
                if (!hasSufficientBalance) ...[
                  Text(
                    'Your wallet balance is too low for this purchase.',
                    style: McTextStyles.body(fontSize: 13, color: McColors.danger),
                  ),
                  SizedBox(height: context.rs(12)),
                ],
                if (s.utilityError.isNotEmpty) ...[
                  Text(s.utilityError, style: McTextStyles.body(fontSize: 13, color: McColors.danger)),
                  SizedBox(height: context.rs(12)),
                ],
                McButton(
                  label: 'Pay ${formatNaira(total)}',
                  isLoading: s.utilityLoading,
                  onPressed: (s.utilityLoading || !hasSufficientBalance)
                      ? null
                      : () => notifier.requestAuthorization('electricity'),
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
          style: McTextStyles.body(
            fontSize: emphasize ? 14 : 13,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
            color: emphasize ? McColors.text : McColors.bodyText,
          ),
        ),
        Text(
          value,
          style: McTextStyles.body(
            fontSize: emphasize ? 14 : 13,
            fontWeight: FontWeight.w700,
            color: McColors.text,
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
    this.subtitle,
    this.selected = false,
    this.comingSoon = false,
    this.insufficientBalance = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final bool comingSoon;
  final bool insufficientBalance;

  @override
  Widget build(BuildContext context) {
    final accentColor = insufficientBalance ? McColors.danger : McColors.accent2;
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
            color: selected ? accentColor.withValues(alpha: 0.08) : McColors.surface,
            borderRadius: BorderRadius.circular(McRadii.md),
            border: Border.all(color: selected ? accentColor : McColors.divider),
          ),
          child: Row(
            children: [
              Icon(icon, color: McColors.bodyText, size: context.rs(20)),
              SizedBox(width: context.rs(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600, color: McColors.text),
                        ),
                        if (comingSoon) ...[
                          SizedBox(width: context.rs(8)),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: context.rs(8), vertical: context.rs(3)),
                            decoration: BoxDecoration(
                              color: McColors.surfaceSunken,
                              borderRadius: BorderRadius.circular(McRadii.pill),
                            ),
                            child: Text(
                              'Coming soon',
                              style: McTextStyles.body(fontSize: 10.5, fontWeight: FontWeight.w600, color: McColors.bodyText),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: context.rs(2)),
                      Text(
                        insufficientBalance ? '$subtitle · Insufficient' : subtitle!,
                        style: McTextStyles.body(
                          fontSize: 12,
                          color: insufficientBalance ? McColors.danger : McColors.bodyText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? accentColor : McColors.divider,
                size: context.rs(20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
