import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../core/widgets/ch_generic_header.dart';
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
        const ChGenericHeader(title: 'Payment'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: switch (s.paymentStep) {
              PaymentStep.idle => _Idle(balanceLabel: s.duesBalanceLabel, onConfirm: notifier.confirmPayment),
              PaymentStep.processing => const _Processing(),
              PaymentStep.success => _Success(
                  amountLabel: s.duesBalanceLabelPre,
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
  const _Idle({required this.balanceLabel, required this.onConfirm});

  final String balanceLabel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.card)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amount to pay', style: ChTextStyles.body(fontSize: 13, color: ChColors.neutralN(600))),
              const SizedBox(height: 6),
              Text(balanceLabel, style: ChTextStyles.heading(fontSize: 24)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'PAY WITH',
          style: ChTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: ChColors.neutralN(600))
              .copyWith(letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.md)),
          child: Row(
            children: [
              Container(width: 28, height: 28, decoration: BoxDecoration(color: ChColors.accent2, borderRadius: BorderRadius.circular(ChRadii.sm))),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Paystack — card/bank/USSD',
                  overflow: TextOverflow.ellipsis,
                  style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ChButton(label: 'Confirm Payment', onPressed: onConfirm),
      ],
    );
  }
}

class _Processing extends StatelessWidget {
  const _Processing();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        const SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(strokeWidth: 3, color: ChColors.accent),
        ),
        const SizedBox(height: 18),
        Text('Processing with Paystack…', style: ChTextStyles.body(fontSize: 14, color: ChColors.neutralN(600))),
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
          width: 64,
          height: 64,
          decoration: const BoxDecoration(color: ChColors.accent2, shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 18),
        Text('Payment successful', style: ChTextStyles.heading(fontSize: 18)),
        const SizedBox(height: 6),
        Text('$amountLabel paid in full', style: ChTextStyles.body(fontSize: 13, color: ChColors.neutralN(600))),
        const SizedBox(height: 22),
        ChButton(label: 'View Receipt', variant: ChButtonVariant.secondary, onPressed: onViewReceipt),
      ],
    );
  }
}
