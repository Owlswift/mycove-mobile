import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../core/widgets/mc_text_field.dart';
import '../../../../data/models/wallet_transaction.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';

/// Reached from a tap on the dashboard's Utilities section, or handed off
/// to directly from a voice query about the wallet balance, transaction
/// history, or how to fund it (see AppNotifier._answerReadOnlyVoiceIntent /
/// _answerFundWallet) — all three land here since they're the same screen.
class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(appStateProvider.notifier).loadWalletTransactions(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return Column(
      children: [
        const McGenericHeader(title: 'Wallet'),
        Expanded(
          child: RefreshIndicator(
            onRefresh: notifier.loadWalletTransactions,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(context.rs(20)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(McRadii.card),
                      gradient: LinearGradient(
                        colors: [McColors.accent2, McColors.accent2N(900)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wallet Balance',
                          style: McTextStyles.body(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                        ),
                        SizedBox(height: context.rs(6)),
                        Text(s.walletBalanceLabel, style: McTextStyles.heading(fontSize: 30, color: Colors.white)),
                        SizedBox(height: context.rs(16)),
                        GestureDetector(
                          onTap: () => _showFundSheet(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: context.rs(20), vertical: context.rs(11)),
                            decoration: BoxDecoration(color: McColors.accent, borderRadius: BorderRadius.circular(McRadii.button)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_circle_outline_rounded, size: context.rs(17), color: McColors.accentN(900)),
                                SizedBox(width: context.rs(6)),
                                Text(
                                  'Fund Wallet',
                                  style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w700, color: McColors.accentN(900)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.rs(20)),
                  Text(
                    'TRANSACTION HISTORY',
                    style: McTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: McColors.bodyText)
                        .copyWith(letterSpacing: 1),
                  ),
                  SizedBox(height: context.rs(10)),
                  if (s.walletTransactionsLoading && s.walletTransactions.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: context.rs(40)),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: McColors.accent2)),
                    )
                  else if (s.walletTransactions.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(context.rs(18)),
                      decoration: BoxDecoration(
                        boxShadow: McColors.cardShadow,
                        color: McColors.surface,
                        borderRadius: BorderRadius.circular(McRadii.card),
                      ),
                      child: Text(
                        'No wallet activity yet.',
                        style: McTextStyles.body(fontSize: 13, color: McColors.bodyText),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        boxShadow: McColors.cardShadow,
                        color: McColors.surface,
                        borderRadius: BorderRadius.circular(McRadii.card),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < s.walletTransactions.length; i++)
                            _TransactionRow(
                              transaction: s.walletTransactions[i],
                              showBorder: i != s.walletTransactions.length - 1,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void _showFundSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: McColors.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(McRadii.card))),
    builder: (sheetContext) => const _FundWalletSheet(),
  );
}

class _FundWalletSheet extends ConsumerStatefulWidget {
  const _FundWalletSheet();

  @override
  ConsumerState<_FundWalletSheet> createState() => _FundWalletSheetState();
}

class _FundWalletSheetState extends ConsumerState<_FundWalletSheet> {
  String _amount = '';
  String _error = '';

  Future<void> _confirm() async {
    final parsed = int.tryParse(_amount.trim());
    if (parsed == null || parsed <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }
    setState(() => _error = '');
    final notifier = ref.read(appStateProvider.notifier);
    await notifier.fundWallet(parsed);
    if (!mounted) return;
    final step = ref.read(appStateProvider).walletTopUpStep;
    if (step == WalletTopUpStep.idle && notifier.walletTopUpError.isEmpty) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wallet funded successfully.', style: McTextStyles.body(fontSize: 13, color: Colors.white))),
      );
    } else {
      setState(() => _error = notifier.walletTopUpError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final isProcessing = s.walletTopUpStep == WalletTopUpStep.processing;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fund Wallet', style: McTextStyles.heading(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            'You\'ll be taken to Paystack to complete the payment.',
            style: McTextStyles.body(fontSize: 12.5, color: McColors.bodyText),
          ),
          const SizedBox(height: 16),
          McTextField(
            label: 'Amount (₦)',
            value: _amount,
            onChanged: (v) => setState(() => _amount = v),
            keyboardType: TextInputType.number,
            placeholder: 'e.g. 5000',
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_error, style: McTextStyles.body(fontSize: 12.5, color: McColors.danger)),
          ],
          const SizedBox(height: 18),
          McButton(
            label: isProcessing ? 'Processing…' : 'Fund with Paystack',
            onPressed: isProcessing ? null : _confirm,
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction, required this.showBorder});

  final WalletTransaction transaction;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final label = switch (transaction.type) {
      WalletTransactionType.topup => 'Wallet Top-Up',
      WalletTransactionType.refund => 'Refund',
      WalletTransactionType.purchaseDebit => transaction.description ?? 'Purchase',
    };
    final amountLabel = '${transaction.isCredit ? '' : '-'}${NumberFormat('#,##0').format(transaction.amount)}';
    final amountColor = transaction.isCredit ? McColors.accent2N(700) : McColors.text;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.rs(16), vertical: context.rs(14)),
      decoration: BoxDecoration(
        border: showBorder ? const Border(bottom: BorderSide(color: McColors.divider)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: McTextStyles.body(fontSize: 13.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  DateFormat('d MMM yyyy · HH:mm').format(transaction.createdAt.toLocal()),
                  style: McTextStyles.body(fontSize: 11.5, color: McColors.bodyText),
                ),
              ],
            ),
          ),
          Text(
            '₦$amountLabel',
            style: McTextStyles.body(fontSize: 13.5, fontWeight: FontWeight.w700, color: amountColor),
          ),
        ],
      ),
    );
  }
}
