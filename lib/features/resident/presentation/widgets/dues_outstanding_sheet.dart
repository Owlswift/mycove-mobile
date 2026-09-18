import 'package:flutter/material.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../state/app_state.dart';

/// Shown when the estate's policy blocks a resident from generating a
/// visitor pass because they owe too many months of dues. Resolves to true
/// if they chose to pay, so the caller can route them to the dues screen.
Future<bool> showDuesOutstandingSheet(
  BuildContext context, {
  required int monthsOwed,
  required int balance,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DuesOutstandingSheet(monthsOwed: monthsOwed, balance: balance),
  );
  return result ?? false;
}

class _DuesOutstandingSheet extends StatelessWidget {
  const _DuesOutstandingSheet({required this.monthsOwed, required this.balance});

  final int monthsOwed;
  final int balance;

  @override
  Widget build(BuildContext context) {
    // The amounts come from the server's refusal; if they were missing for
    // any reason the summary card is simply left out rather than showing ₦0.
    final showSummary = balance > 0 && monthsOwed > 0;

    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(context.rs(24), context.rs(24), context.rs(24), context.rs(20)),
        decoration: BoxDecoration(
          color: McColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(McRadii.card)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: McColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
            SizedBox(height: context.rs(22)),
            Container(
              width: context.rs(64),
              height: context.rs(64),
              decoration: BoxDecoration(
                color: McColors.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_outline_rounded, size: context.rs(30), color: McColors.warning),
            ),
            SizedBox(height: context.rs(16)),
            Text(
              'Visitor passes are on hold',
              style: McTextStyles.heading(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.rs(8)),
            Text(
              'Your estate requires your dues to be up to date before you can generate visitor passes.',
              style: McTextStyles.body(fontSize: 14, color: McColors.bodyText, height: 1.4),
              textAlign: TextAlign.center,
            ),
            if (showSummary) ...[
              SizedBox(height: context.rs(20)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.rs(16), vertical: context.rs(14)),
                decoration: BoxDecoration(
                  color: McColors.surface,
                  borderRadius: BorderRadius.circular(McRadii.card),
                  border: Border.all(color: McColors.divider),
                ),
                child: Column(
                  children: [
                    _SummaryRow(label: 'Outstanding balance', value: formatNaira(balance), emphasize: true),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: context.rs(10)),
                      child: Divider(height: 1, color: McColors.divider),
                    ),
                    _SummaryRow(label: 'Months overdue', value: monthsOwed == 1 ? '1 month' : '$monthsOwed months'),
                  ],
                ),
              ),
            ],
            SizedBox(height: context.rs(22)),
            McButton(label: 'Pay Dues', onPressed: () => Navigator.pop(context, true)),
            SizedBox(height: context.rs(4)),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Not now', style: McTextStyles.body(fontSize: 14, color: McColors.bodyText)),
            ),
          ],
        ),
      ),
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
        Text(label, style: McTextStyles.body(fontSize: 13.5, color: McColors.bodyText)),
        Text(
          value,
          style: McTextStyles.body(
            fontSize: emphasize ? 17 : 14,
            fontWeight: FontWeight.w700,
            color: emphasize ? McColors.danger : McColors.text,
          ),
        ),
      ],
    );
  }
}
