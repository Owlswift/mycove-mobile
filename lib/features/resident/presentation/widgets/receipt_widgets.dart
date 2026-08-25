import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';

/// Shared building blocks for utility purchase receipts (on-screen + used
/// alongside the PDF variant in core/pdf).

Widget receiptSection(
  BuildContext context,
  String title,
  List<Widget> rows,
) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(context.rs(16)),
    decoration: BoxDecoration(
      color: ChColors.surface,
      borderRadius: BorderRadius.circular(ChRadii.card),
      boxShadow: ChColors.cardShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ChTextStyles.body(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: ChColors.bodyText,
          ).copyWith(letterSpacing: 1),
        ),
        Divider(height: context.rs(18)),
        ...rows,
      ],
    ),
  );
}

Widget tokenCard(BuildContext context, String token) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(context.rs(16)),
    decoration: BoxDecoration(
      color: ChColors.surfaceSunken,
      borderRadius: BorderRadius.circular(ChRadii.md),
      border: Border.all(color: ChColors.accent2N(300)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PREPAID TOKEN',
              style: ChTextStyles.body(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: ChColors.bodyText,
              ).copyWith(letterSpacing: 1),
            ),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: token));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Token copied.',
                        style: ChTextStyles.body(
                            fontSize: 13, color: Colors.white)),
                  ),
                );
              },
              child: Icon(Icons.copy_rounded,
                  size: context.rs(18), color: ChColors.accent2),
            ),
          ],
        ),
        SizedBox(height: context.rs(6)),
        SelectableText(
          token,
          style: ChTextStyles.heading(fontSize: 19, color: ChColors.accent2),
        ),
      ],
    ),
  );
}

Widget receiptRow(
  BuildContext context,
  String label,
  String value, {
  bool bold = false,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: context.rs(5)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: context.rs(110),
          child: Text(
            label,
            style: ChTextStyles.body(fontSize: 12.5, color: ChColors.bodyText),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: ChTextStyles.body(
              fontSize: 12.5,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: bold ? ChColors.accent2N(700) : ChColors.text,
            ),
          ),
        ),
      ],
    ),
  );
}