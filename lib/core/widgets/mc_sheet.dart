import 'package:flutter/material.dart';

import '../theme/mc_colors.dart';
import '../theme/mc_responsive.dart';
import '../theme/mc_spacing.dart';
import '../theme/mc_text_styles.dart';
import 'mc_button.dart';

/// A confirmation that slides up from the bottom of the screen, rather than a
/// centred pop-up dialog. Resolves to true when the confirm button is tapped,
/// false for the secondary button, and null if the sheet is swiped away.
Future<bool?> showMcConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: McColors.surface,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(context.rs(24), 0, context.rs(24), context.rs(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: McTextStyles.heading(fontSize: 18)),
            SizedBox(height: context.rs(8)),
            Text(message, style: McTextStyles.body(fontSize: 14, color: McColors.text)),
            SizedBox(height: context.rs(20)),
            McButton(
              label: confirmLabel,
              variant: destructive ? ChButtonVariant.danger : ChButtonVariant.primary,
              onPressed: () => Navigator.of(sheetContext).pop(true),
            ),
            SizedBox(height: context.rs(10)),
            McButton(
              label: cancelLabel,
              variant: ChButtonVariant.secondary,
              onPressed: () => Navigator.of(sheetContext).pop(false),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Shared shape for the app's bottom sheets that hold a form or a picker.
Future<T?> showMcSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: McColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(McRadii.card)),
    ),
    builder: builder,
  );
}
