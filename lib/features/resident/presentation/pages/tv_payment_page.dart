import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/feature_flags.dart';
import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_feature_unavailable_banner.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../core/widgets/mc_payment_method_tile.dart';
import '../../../../data/models/tv_smartcard.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';

class TvPaymentPage extends ConsumerWidget {
  const TvPaymentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final package = s.tvPackages.where((p) => p.code == s.tvSelectedPackageCode).firstOrNull;
    final amount = package?.amount ?? 0;
    final providerLabel = tvProviders.firstWhere((p) => p.$1 == s.tvProvider, orElse: () => ('', '')).$2;
    final hasSufficientBalance = s.walletBalance >= amount;
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
                _SummaryRow(label: 'Provider', value: providerLabel),
                SizedBox(height: context.rs(10)),
                _SummaryRow(label: 'Smartcard Number', value: s.tvSmartcardNumber),
                SizedBox(height: context.rs(10)),
                _SummaryRow(label: 'Bouquet', value: package?.name ?? ''),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: context.rs(10)),
                  child: Divider(height: 1, color: McColors.divider),
                ),
                _SummaryRow(label: 'Total Payable', value: formatNaira(amount), emphasize: true),
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
                if (!s.featureEnabled(FeatureFlagKeys.utilityPayments))
                  const McFeatureUnavailableBanner(
                    message: 'Your estate is not subscribed to this feature.',
                  ),
                if (s.utilityError.isNotEmpty) ...[
                  Text(s.utilityError, style: McTextStyles.body(fontSize: 13, color: McColors.danger)),
                  SizedBox(height: context.rs(12)),
                ],
                McButton(
                  label: 'Pay ${formatNaira(amount)}',
                  isLoading: s.utilityLoading,
                  onPressed: (s.utilityLoading ||
                          !s.featureEnabled(FeatureFlagKeys.utilityPayments) ||
                          (!isPaystack && !hasSufficientBalance))
                      ? null
                      : () => isPaystack
                          ? notifier.buyTv().then((ok) {
                              if (ok && context.mounted) context.go('/resident/tv/success');
                            })
                          : notifier.requestAuthorization('tv'),
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
