import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';

class PaymentPage extends ConsumerWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return Column(
      children: [
        const McGenericHeader(title: 'Payment'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: switch (s.paymentStep) {
              PaymentStep.idle => _Idle(
                  balanceLabel: s.pendingPaymentAmountLabel,
                  walletBalanceLabel: s.walletBalanceLabel,
                  hasSufficientWalletBalance:
                      s.walletBalance >= s.pendingPaymentAmount,
                  selectedMethod: s.paymentMethod,
                  onSelectMethod: notifier.selectPaymentMethod,
                  onConfirm: () => notifier.requestAuthorization(
                    s.pendingPaymentPurpose == 'LEVY' ? 'levy' : 'dues',
                  ),
                ),
              PaymentStep.processing => _Processing(
                  isWallet: s.paymentMethod == 'WALLET',
                  onCheckStatus: notifier.checkPendingPaymentStatus,
                ),
              PaymentStep.success => _Success(
                  amountLabel: s.pendingPaymentAmountLabel,
                  onViewReceipt: () => context.pushReplacement('/resident/receipt'),
                ),
            },
          ),
        ),
      ],
    );
  }
}

class _Idle extends StatelessWidget {
  const _Idle({
    required this.balanceLabel,
    required this.walletBalanceLabel,
    required this.hasSufficientWalletBalance,
    required this.selectedMethod,
    required this.onSelectMethod,
    required this.onConfirm,
  });

  final String balanceLabel;
  final String walletBalanceLabel;
  final bool hasSufficientWalletBalance;
  final String selectedMethod;
  final ValueChanged<String> onSelectMethod;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(boxShadow: McColors.cardShadow, color: McColors.surface, borderRadius: BorderRadius.circular(McRadii.card)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amount to pay', style: McTextStyles.body(fontSize: 13, color: McColors.bodyText)),
              const SizedBox(height: 6),
              Text(balanceLabel, style: McTextStyles.heading(fontSize: 24)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'PAY WITH',
          style: McTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: McColors.bodyText)
              .copyWith(letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        _PaymentMethodOption(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Wallet Balance',
          subtitle: hasSufficientWalletBalance
              ? 'Available: $walletBalanceLabel'
              : 'Insufficient balance — $walletBalanceLabel available',
          selected: selectedMethod == 'WALLET',
          enabled: hasSufficientWalletBalance,
          onTap: () => onSelectMethod('WALLET'),
        ),
        const SizedBox(height: 10),
        _PaymentMethodOption(
          icon: Icons.credit_card_rounded,
          title: 'Pay via Paystack',
          subtitle: 'Card, bank transfer or USSD',
          selected: selectedMethod == 'PAYSTACK',
          enabled: true,
          onTap: () => onSelectMethod('PAYSTACK'),
        ),
        const SizedBox(height: 20),
        McButton(label: 'Confirm Payment', onPressed: onConfirm),
      ],
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  const _PaymentMethodOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: McColors.surface,
            borderRadius: BorderRadius.circular(McRadii.md),
            border: Border.all(
              color: selected ? McColors.accent2 : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: context.rs(36),
                height: context.rs(36),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: McColors.accent2N(100), borderRadius: BorderRadius.circular(McRadii.sm)),
                child: Icon(icon, size: context.rs(18), color: McColors.accent2N(700)),
              ),
              SizedBox(width: context.rs(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: McTextStyles.body(fontSize: 12, color: McColors.bodyText),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.rs(8)),
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                size: context.rs(20),
                color: selected ? McColors.accent2 : McColors.bodyText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Processing extends StatelessWidget {
  const _Processing({required this.isWallet, required this.onCheckStatus});

  final bool isWallet;
  final VoidCallback onCheckStatus;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        SizedBox(
          width: context.rs(36),
          height: context.rs(36),
          child: const CircularProgressIndicator(strokeWidth: 3, color: McColors.accent),
        ),
        const SizedBox(height: 18),
        Text(
          isWallet ? 'Processing…' : 'Processing with Paystack…',
          style: McTextStyles.body(fontSize: 14, color: McColors.bodyText),
        ),
        const SizedBox(height: 6),
        Text(
          isWallet
              ? 'Deducting from your wallet balance.'
              : 'Complete the payment in your browser, then return here.',
          textAlign: TextAlign.center,
          style: McTextStyles.body(fontSize: 12.5, color: McColors.bodyText),
        ),
        if (!isWallet) ...[
          const SizedBox(height: 20),
          McButton(label: 'Check status', variant: ChButtonVariant.secondary, onPressed: onCheckStatus),
        ],
      ],
    );
  }
}

class _Success extends StatelessWidget {
  const _Success({required this.amountLabel, required this.onViewReceipt});

  final String amountLabel;
  final VoidCallback onViewReceipt;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 44),
        Container(
          width: context.rs(64),
          height: context.rs(64),
          decoration: const BoxDecoration(color: McColors.accent2, shape: BoxShape.circle),
          child: Icon(Icons.check, color: Colors.white, size: context.rs(30)),
        ),
        const SizedBox(height: 18),
        Text('Payment successful', style: McTextStyles.heading(fontSize: 18)),
        const SizedBox(height: 6),
        Text('$amountLabel paid in full', style: McTextStyles.body(fontSize: 13, color: McColors.bodyText)),
        const SizedBox(height: 22),
        McButton(label: 'View Receipt', variant: ChButtonVariant.secondary, onPressed: onViewReceipt),
      ],
    );
  }
}
