import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/feature_flags.dart';
import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_feature_unavailable_banner.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../core/widgets/mc_payment_method_tile.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';
import '../widgets/utility_wizard_stepper.dart';

const _networks = [
  ('mtn', 'MTN'),
  ('airtel', 'Airtel'),
  ('glo', 'Glo'),
  ('etisalat', '9mobile'),
];

class BuyDataPage extends ConsumerStatefulWidget {
  const BuyDataPage({super.key});

  @override
  ConsumerState<BuyDataPage> createState() => _BuyDataPageState();
}

class _BuyDataPageState extends ConsumerState<BuyDataPage> {
  late final _phoneController = TextEditingController(text: ref.read(appStateProvider).dataPhone);

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return Column(
      children: [
        McGenericHeader(
          title: 'Buy Data',
          centerTitle: true,
          onBack: () {
            notifier.clearUtilityError();
            context.pop();
          },
          trailing: const UtilityHistoryButton(type: 'DATA'),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(24)),
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
                        selected: s.dataNetwork == code,
                        onTap: () => notifier.onDataNetwork(code),
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
                  onChanged: notifier.onDataPhone,
                  style: McTextStyles.inputValue(),
                  decoration: InputDecoration(
                    hintText: '08012345678',
                    hintStyle: McTextStyles.inputPlaceholder(),
                  ),
                ),
                if (s.dataNetwork.isNotEmpty) ...[
                  SizedBox(height: context.rs(18)),
                  Text(
                    'Select a Plan',
                    style: McTextStyles.body(fontSize: 12, color: McColors.bodyText),
                  ),
                  SizedBox(height: context.rs(8)),
                  if (s.utilityLoading && s.dataPlans.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: context.rs(20)),
                      child: const Center(child: CircularProgressIndicator(color: McColors.accent2)),
                    )
                  else if (s.dataPlans.isEmpty)
                    Text(
                      'No plans available right now.',
                      style: McTextStyles.body(fontSize: 13, color: McColors.bodyText),
                    )
                  else
                    Column(
                      children: [
                        for (final plan in s.dataPlans)
                          Padding(
                            padding: EdgeInsets.only(bottom: context.rs(8)),
                            child: _PlanTile(
                              name: plan.name,
                              price: formatNaira(plan.amount),
                              selected: s.dataSelectedPlanCode == plan.code,
                              onTap: () => notifier.selectDataPlan(plan.code),
                            ),
                          ),
                      ],
                    ),
                ],
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
                if (!s.featureEnabled(FeatureFlagKeys.utilityPayments))
                  const McFeatureUnavailableBanner(
                    message: 'Your estate is not subscribed to this feature.',
                  ),
                if (s.utilityError.isNotEmpty) ...[
                  Text(
                    s.utilityError,
                    style: McTextStyles.body(fontSize: 13, color: McColors.danger),
                  ),
                  SizedBox(height: context.rs(12)),
                ],
                McButton(
                  label: 'Buy Data',
                  isLoading: s.utilityLoading,
                  onPressed: s.utilityLoading || !s.featureEnabled(FeatureFlagKeys.utilityPayments)
                      ? null
                      : () => s.utilityPaymentMethod == 'PAYSTACK'
                          ? notifier.buyData().then((ok) {
                              if (ok && context.mounted) context.go('/resident/data/success');
                            })
                          : notifier.requestAuthorization('data'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.name,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(McRadii.md),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: context.rs(14), vertical: context.rs(12)),
        decoration: BoxDecoration(
          color: selected ? McColors.accent2N(100) : McColors.surfaceSunken,
          borderRadius: BorderRadius.circular(McRadii.md),
          border: Border.all(color: selected ? McColors.accent2 : Colors.transparent),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: McTextStyles.body(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: McColors.text,
                ),
              ),
            ),
            Text(
              price,
              style: McTextStyles.body(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: selected ? McColors.accent2 : McColors.text,
              ),
            ),
          ],
        ),
      ),
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
