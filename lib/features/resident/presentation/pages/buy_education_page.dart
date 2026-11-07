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

class BuyEducationPage extends ConsumerStatefulWidget {
  const BuyEducationPage({super.key});

  @override
  ConsumerState<BuyEducationPage> createState() => _BuyEducationPageState();
}

class _BuyEducationPageState extends ConsumerState<BuyEducationPage> {
  late final _phoneController = TextEditingController(text: ref.read(appStateProvider).educationPhone);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(appStateProvider).educationVariations.isEmpty) {
        ref.read(appStateProvider.notifier).loadEducationVariations();
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final variation = s.educationVariations
        .where((v) => v.code == s.educationSelectedCode)
        .firstOrNull;
    final total = (variation?.amount ?? 0) * s.educationQuantity;

    return Column(
      children: [
        McGenericHeader(
          title: 'WAEC Result Checker',
          centerTitle: true,
          onBack: () {
            notifier.clearUtilityError();
            context.pop();
          },
          trailing: const UtilityHistoryButton(type: 'EDUCATION'),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buy a WASSCE/GCE result checker PIN.',
                  style: McTextStyles.body(fontSize: 13, color: McColors.bodyText),
                ),
                SizedBox(height: context.rs(18)),
                if (s.utilityLoading && s.educationVariations.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: context.rs(20)),
                    child: const Center(child: CircularProgressIndicator(color: McColors.accent2)),
                  )
                else if (variation != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(context.rs(14)),
                    decoration: BoxDecoration(
                      color: McColors.surfaceSunken,
                      borderRadius: BorderRadius.circular(McRadii.md),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.school_rounded, color: McColors.accent2, size: context.rs(28)),
                        SizedBox(width: context.rs(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                variation.name,
                                style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w700, color: McColors.text),
                              ),
                              Text(
                                '${formatNaira(variation.amount)} per PIN',
                                style: McTextStyles.body(fontSize: 12, color: McColors.bodyText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: context.rs(20)),
                Text(
                  'Number of PINs',
                  style: McTextStyles.body(fontSize: 12, color: McColors.bodyText),
                ),
                SizedBox(height: context.rs(8)),
                Row(
                  children: [
                    _StepperButton(
                      icon: Icons.remove_rounded,
                      onTap: () => notifier.onEducationQuantity(s.educationQuantity - 1),
                    ),
                    SizedBox(width: context.rs(16)),
                    Text('${s.educationQuantity}', style: McTextStyles.heading(fontSize: 20)),
                    SizedBox(width: context.rs(16)),
                    _StepperButton(
                      icon: Icons.add_rounded,
                      onTap: () => notifier.onEducationQuantity(s.educationQuantity + 1),
                    ),
                  ],
                ),
                SizedBox(height: context.rs(18)),
                Text(
                  'Phone Number',
                  style: McTextStyles.body(fontSize: 12, color: McColors.bodyText),
                ),
                SizedBox(height: context.rs(5)),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  onChanged: notifier.onEducationPhone,
                  style: McTextStyles.inputValue(),
                  decoration: InputDecoration(
                    hintText: '08012345678',
                    hintStyle: McTextStyles.inputPlaceholder(),
                  ),
                ),
                SizedBox(height: context.rs(18)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Payable', style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w700, color: McColors.text)),
                    Text(formatNaira(total), style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w700, color: McColors.text)),
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
                  label: 'Buy PIN${s.educationQuantity > 1 ? 's' : ''}',
                  isLoading: s.utilityLoading,
                  onPressed: s.utilityLoading || !s.featureEnabled(FeatureFlagKeys.utilityPayments)
                      ? null
                      : () => s.utilityPaymentMethod == 'PAYSTACK'
                          ? notifier.buyEducation().then((ok) {
                              if (ok && context.mounted) context.go('/resident/education/success');
                            })
                          : notifier.requestAuthorization('education'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(McRadii.pill),
      child: Container(
        width: context.rs(36),
        height: context.rs(36),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: McColors.accent2N(100),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: McColors.accent2, size: context.rs(18)),
      ),
    );
  }
}
