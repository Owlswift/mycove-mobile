import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../core/widgets/mc_payment_method_tile.dart';
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
    final isPaystack = s.utilityPaymentMethod == 'PAYSTACK';

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
                McPaymentMethodTile(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Wallet Balance',
                  subtitle: hasSufficientBalance ? s.walletBalanceLabel : '${s.walletBalanceLabel} · Insufficient',
                  selected: !isPaystack,
                  enabled: hasSufficientBalance,
                  onTap: () => notifier.selectUtilityPaymentMethod('WALLET'),
                ),
                SizedBox(height: context.rs(10)),
                McPaymentMethodTile(
                  icon: Icons.credit_card_rounded,
                  label: 'Pay via Paystack',
                  subtitle: 'Card, bank transfer or USSD',
                  selected: isPaystack,
                  onTap: () => notifier.selectUtilityPaymentMethod('PAYSTACK'),
                ),
                SizedBox(height: context.rs(24)),
                if (s.utilityError.isNotEmpty) ...[
                  Text(s.utilityError, style: McTextStyles.body(fontSize: 13, color: McColors.danger)),
                  SizedBox(height: context.rs(12)),
                ],
                McButton(
                  label: 'Pay ${formatNaira(total)}',
                  isLoading: s.utilityLoading,
                  onPressed: (s.utilityLoading || (!isPaystack && !hasSufficientBalance))
                      ? null
                      : () => isPaystack
                          ? notifier.buyElectricity().then((ok) {
                              if (ok && context.mounted) context.go('/resident/electricity/success');
                            })
                          : notifier.requestAuthorization('electricity'),
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

