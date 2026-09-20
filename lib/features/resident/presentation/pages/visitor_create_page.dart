import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_sheet.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../core/widgets/mc_text_field.dart';
import '../../../../state/app_notifier.dart';
import '../widgets/dues_outstanding_sheet.dart';

class VisitorCreatePage extends ConsumerWidget {
  const VisitorCreatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return Column(
      children: [
        const McGenericHeader(title: 'New Visitor Pass'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                McTextField(label: 'Visitor name', value: s.vfName, onChanged: notifier.onVfName, placeholder: 'Full name'),
                const SizedBox(height: 14),
                McTextField(
                  label: 'Phone number',
                  value: s.vfPhone,
                  onChanged: notifier.onVfPhone,
                  placeholder: '0800 000 0000',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                McTextField(
                  label: 'Vehicle plate (optional)',
                  value: s.vfPlate,
                  onChanged: notifier.onVfPlate,
                  placeholder: 'e.g. LND 442 KJ',
                ),
                const SizedBox(height: 20),
                if (s.vfError.isNotEmpty && !s.vfDuesBlocked && s.vfExtraTokenCode.isEmpty) ...[
                  Text(s.vfError, style: McTextStyles.body(fontSize: 13, color: McColors.danger)),
                  const SizedBox(height: 12),
                ],
                McButton(
                  label: 'Generate Pass',
                  onPressed: () async {
                    var id = await notifier.createVisitorPass();
                    if (!context.mounted) return;

                    // Past the day's free tokens the estate charges for each
                    // extra one from the wallet — ask before taking the money.
                    final charged = ref.read(appStateProvider);
                    if (id == null && charged.vfExtraTokenCode == 'EXTRA_TOKEN_CHARGE') {
                      final agree = await _confirmExtraToken(context, charged.vfError, charged.vfExtraTokenPrice);
                      if (agree != true || !context.mounted) return;
                      id = await notifier.createVisitorPass(acceptExtraCharge: true);
                      if (!context.mounted) return;
                    }
                    final stillCharged = ref.read(appStateProvider);
                    if (id == null && stillCharged.vfExtraTokenCode == 'EXTRA_TOKEN_INSUFFICIENT_FUNDS') {
                      final topUp = await _needWalletTopUp(context, stillCharged.vfError);
                      if (topUp == true && context.mounted) context.push('/resident/wallet');
                      return;
                    }

                    if (id != null) {
                      context.pushReplacement('/resident/visitor/$id');
                    } else {
                      // The estate blocks passes for residents owing too
                      // many months of dues — offer to take them to pay.
                      final blocked = ref.read(appStateProvider);
                      if (blocked.vfDuesBlocked) {
                        final pay = await showDuesOutstandingSheet(
                          context,
                          monthsOwed: blocked.vfDuesMonthsOwed,
                          balance: blocked.vfDuesBalance,
                        );
                        if (pay && context.mounted) context.go('/resident/dues');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Future<bool?> _confirmExtraToken(BuildContext context, String message, int price) {
  return showMcConfirmSheet(
    context,
    title: 'Extra visitor token',
    message: message,
    confirmLabel: 'Pay ₦$price and continue',
  );
}

Future<bool?> _needWalletTopUp(BuildContext context, String message) {
  return showMcConfirmSheet(
    context,
    title: 'Not enough in your wallet',
    message: message,
    confirmLabel: 'Top up wallet',
  );
}
