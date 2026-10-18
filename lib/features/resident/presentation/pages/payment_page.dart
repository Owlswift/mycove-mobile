import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';

/// Formats the dues amount field live as "10,000" instead of raw digits —
/// keeps the cursor pinned to the end since the field is only ever edited
/// by typing/deleting the last digit, never by inserting into the middle.
class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final formatted = NumberFormat('#,##0').format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

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
                  amount: s.pendingPaymentAmount,
                  amountEditable: s.pendingPaymentAmountEditable,
                  onAmountChanged: notifier.setPendingPaymentAmount,
                  walletBalanceLabel: s.walletBalanceLabel,
                  hasSufficientWalletBalance:
                      s.walletBalance >= s.pendingPaymentAmount,
                  selectedMethod: s.paymentMethod,
                  onSelectMethod: notifier.selectPaymentMethod,
                  // A Paystack payment is authenticated by Paystack itself
                  // (card/bank/USSD), so it goes straight to checkout —
                  // same as wallet funding. Only paying from the resident's
                  // own stored wallet balance needs the local PIN/biometric
                  // gate, since that's spending money with nothing else to
                  // confirm the resident's identity.
                  onConfirm: () => s.paymentMethod == 'PAYSTACK'
                      ? notifier.confirmPayment()
                      : notifier.requestAuthorization(
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

class _Idle extends StatefulWidget {
  const _Idle({
    required this.amount,
    required this.amountEditable,
    required this.onAmountChanged,
    required this.walletBalanceLabel,
    required this.hasSufficientWalletBalance,
    required this.selectedMethod,
    required this.onSelectMethod,
    required this.onConfirm,
  });

  final int amount;
  final bool amountEditable;
  final ValueChanged<int> onAmountChanged;
  final String walletBalanceLabel;
  final bool hasSufficientWalletBalance;
  final String selectedMethod;
  final ValueChanged<String> onSelectMethod;
  final VoidCallback onConfirm;

  @override
  State<_Idle> createState() => _IdleState();
}

class _IdleState extends State<_Idle> {
  late final _amountController = TextEditingController(
    text: NumberFormat('#,##0').format(widget.amount),
  );
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (widget.amountEditable) {
      final digits = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
      final parsed = int.tryParse(digits);
      if (parsed == null || parsed <= 0) {
        setState(() => _error = 'Enter a valid amount.');
        return;
      }
      widget.onAmountChanged(parsed);
    }
    setState(() => _error = null);
    widget.onConfirm();
  }

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
              const SizedBox(height: 4),
              if (widget.amountEditable)
                IntrinsicWidth(
                  child: TextField(
                    controller: _amountController,
                    onChanged: (v) {
                      setState(() => _error = null);
                      // Pushed live (not just at confirm) so things that
                      // depend on the typed amount elsewhere on this
                      // screen — the wallet-balance option's
                      // enabled/disabled state — update as you type
                      // instead of only after the next rebuild.
                      final digits = v.replaceAll(RegExp(r'[^\d]'), '');
                      widget.onAmountChanged(int.tryParse(digits) ?? 0);
                    },
                    keyboardType: TextInputType.number,
                    inputFormatters: [_ThousandsFormatter()],
                    style: McTextStyles.heading(fontSize: 26),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      prefixText: '₦ ',
                      prefixStyle: McTextStyles.heading(fontSize: 26, color: McColors.bodyText),
                      hintText: '0',
                      hintStyle: McTextStyles.heading(fontSize: 26, color: McColors.bodyText),
                    ),
                  ),
                )
              else
                Text(formatNaira(widget.amount), style: McTextStyles.heading(fontSize: 24)),
              const SizedBox(height: 6),
              Container(height: 1.5, color: McColors.divider),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: McTextStyles.body(fontSize: 12.5, color: McColors.danger)),
              ],
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
          subtitle: widget.hasSufficientWalletBalance
              ? 'Available: ${widget.walletBalanceLabel}'
              : 'Insufficient balance — ${widget.walletBalanceLabel} available',
          selected: widget.selectedMethod == 'WALLET',
          enabled: widget.hasSufficientWalletBalance,
          onTap: () => widget.onSelectMethod('WALLET'),
        ),
        const SizedBox(height: 10),
        _PaymentMethodOption(
          icon: Icons.credit_card_rounded,
          title: 'Pay via Paystack',
          subtitle: 'Card, bank transfer or USSD',
          selected: widget.selectedMethod == 'PAYSTACK',
          enabled: true,
          onTap: () => widget.onSelectMethod('PAYSTACK'),
        ),
        const SizedBox(height: 20),
        McButton(label: 'Confirm Payment', onPressed: _confirm),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? McColors.accent2N(100) : McColors.surface,
            borderRadius: BorderRadius.circular(McRadii.md),
            boxShadow: selected ? null : McColors.cardShadow,
            border: Border.all(
              color: selected ? McColors.accent2 : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: context.rs(36),
                height: context.rs(36),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? McColors.accent2 : McColors.accent2N(100),
                  borderRadius: BorderRadius.circular(McRadii.sm),
                ),
                child: Icon(icon, size: context.rs(18), color: selected ? Colors.white : McColors.accent2N(700)),
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
                selected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                size: context.rs(20),
                color: selected ? McColors.accent2 : McColors.bodyText.withValues(alpha: 0.4),
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
