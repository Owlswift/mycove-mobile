import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../core/widgets/mc_payment_method_tile.dart';
import '../../../../state/app_notifier.dart';

const _networks = [
  ('mtn', 'MTN'),
  ('airtel', 'Airtel'),
  ('glo', 'Glo'),
  ('etisalat', '9mobile'),
];

const _quickAmounts = [100, 200, 500, 1000, 2000];

class BuyAirtimePage extends ConsumerStatefulWidget {
  const BuyAirtimePage({super.key});

  @override
  ConsumerState<BuyAirtimePage> createState() => _BuyAirtimePageState();
}

class _BuyAirtimePageState extends ConsumerState<BuyAirtimePage> {
  late final _amountController = TextEditingController(text: ref.read(appStateProvider).airtimeAmount);
  late final _phoneController = TextEditingController(text: ref.read(appStateProvider).airtimePhone);

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _setAmount(String value) {
    _amountController.text = value;
    ref.read(appStateProvider.notifier).onAirtimeAmount(value);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    // A follow-up spoken correction (e.g. "MTN 1000" after landing here
    // with everything blank) writes straight into AppState — these fields
    // aren't seeded again after initState, so keep them synced live.
    ref.listen<String>(appStateProvider.select((s) => s.airtimeAmount), (prev, next) {
      if (_amountController.text != next) _amountController.text = next;
    });
    ref.listen<String>(appStateProvider.select((s) => s.airtimePhone), (prev, next) {
      if (_phoneController.text != next) _phoneController.text = next;
    });

    return Column(
      children: [
        const McGenericHeader(title: 'Buy Airtime'),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              context.rs(20),
              0,
              context.rs(20),
              context.rs(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Network',
                  style: McTextStyles.body(fontSize: 12, color: McColors.bodyText),
                ),
                SizedBox(height: context.rs(8)),
                Wrap(
                  spacing: context.rs(8),
                  runSpacing: context.rs(8),
                  children: [
                    for (final (code, label) in _networks)
                      _Chip(
                        label: label,
                        selected: s.airtimeNetwork == code,
                        onTap: () => notifier.onAirtimeNetwork(code),
                      ),
                  ],
                ),
                SizedBox(height: context.rs(16)),
                Text(
                  'Phone Number',
                  style: McTextStyles.body(fontSize: 12, color: McColors.bodyText),
                ),
                SizedBox(height: context.rs(5)),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  onChanged: notifier.onAirtimePhone,
                  style: McTextStyles.inputValue(),
                  decoration: InputDecoration(
                    hintText: '08012345678',
                    hintStyle: McTextStyles.inputPlaceholder(),
                  ),
                ),
                SizedBox(height: context.rs(16)),
                Text(
                  'Amount',
                  style: McTextStyles.body(fontSize: 12, color: McColors.bodyText),
                ),
                SizedBox(height: context.rs(5)),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  onChanged: notifier.onAirtimeAmount,
                  style: McTextStyles.inputValue(),
                  decoration: InputDecoration(
                    hintText: '₦0',
                    hintStyle: McTextStyles.inputPlaceholder(),
                  ),
                ),
                SizedBox(height: context.rs(10)),
                Wrap(
                  spacing: context.rs(8),
                  runSpacing: context.rs(8),
                  children: [
                    for (final amount in _quickAmounts)
                      _Chip(
                        label: '₦$amount',
                        selected: s.airtimeAmount == amount.toString(),
                        onTap: () => _setAmount(amount.toString()),
                      ),
                  ],
                ),
                SizedBox(height: context.rs(18)),
                Text(
                  'Pay With',
                  style: McTextStyles.body(fontSize: 12, color: McColors.bodyText),
                ),
                SizedBox(height: context.rs(8)),
                McPaymentMethodTile(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Wallet Balance',
                  subtitle: s.walletBalanceLabel,
                  selected: s.utilityPaymentMethod == 'WALLET',
                  onTap: () => notifier.selectUtilityPaymentMethod('WALLET'),
                ),
                SizedBox(height: context.rs(10)),
                McPaymentMethodTile(
                  icon: Icons.credit_card_rounded,
                  label: 'Pay via Paystack',
                  subtitle: 'Card, bank transfer or USSD',
                  selected: s.utilityPaymentMethod == 'PAYSTACK',
                  onTap: () => notifier.selectUtilityPaymentMethod('PAYSTACK'),
                ),
                SizedBox(height: context.rs(18)),
                if (s.utilityError.isNotEmpty) ...[
                  Text(
                    s.utilityError,
                    style: McTextStyles.body(fontSize: 13, color: McColors.danger),
                  ),
                  SizedBox(height: context.rs(12)),
                ],
                McButton(
                  label: 'Buy Airtime',
                  isLoading: s.utilityLoading,
                  onPressed: s.utilityLoading
                      ? null
                      : () => s.utilityPaymentMethod == 'PAYSTACK'
                          ? notifier.buyAirtime().then((ok) {
                              if (ok && context.mounted) context.go('/resident/airtime/success');
                            })
                          : notifier.requestAuthorization('airtime'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.rs(14),
          vertical: context.rs(8),
        ),
        decoration: BoxDecoration(
          color: selected ? McColors.accent2 : null,
          border: selected ? null : Border.all(color: McColors.divider),
          borderRadius: BorderRadius.circular(McRadii.pill),
        ),
        child: Text(
          label,
          style: McTextStyles.body(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : McColors.text,
          ),
        ),
      ),
    );
  }
}
