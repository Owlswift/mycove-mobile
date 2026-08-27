import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';

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
      color: McColors.surface,
      borderRadius: BorderRadius.circular(McRadii.card),
      boxShadow: McColors.cardShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: McTextStyles.body(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: McColors.bodyText,
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
      color: McColors.surfaceSunken,
      borderRadius: BorderRadius.circular(McRadii.md),
      border: Border.all(color: McColors.accent2N(300)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PREPAID TOKEN',
              style: McTextStyles.body(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: McColors.bodyText,
              ).copyWith(letterSpacing: 1),
            ),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: token));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Token copied.',
                        style: McTextStyles.body(
                            fontSize: 13, color: Colors.white)),
                  ),
                );
              },
              child: Icon(Icons.copy_rounded,
                  size: context.rs(18), color: McColors.accent2),
            ),
          ],
        ),
        SizedBox(height: context.rs(6)),
        SelectableText(
          token,
          style: McTextStyles.heading(fontSize: 19, color: McColors.accent2),
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
            style: McTextStyles.body(fontSize: 12.5, color: McColors.bodyText),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: McTextStyles.body(
              fontSize: 12.5,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: bold ? McColors.accent2N(700) : McColors.text,
            ),
          ),
        ),
      ],
    ),
  );
}