import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../state/app_notifier.dart';

class GuardResultPage extends ConsumerWidget {
  const GuardResultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final result = s.guardResult;
    final valid = result?.valid ?? false;
    final pass = result?.pass;
    final reason = result?.reason;

    final isUsed = reason == 'USED';
    final title = pass == null
        ? 'Code Not Recognized'
        : (valid
            ? 'Pass Valid'
            : (isUsed ? 'Pass Already Used' : 'Pass Expired'));
    final subtitle = pass != null
        ? '${pass.name} · ${pass.visitLabel}'
        : 'No matching visitor pass found.';
    final bg = valid ? ChColors.accent2 : ChColors.danger;
    final icon = valid ? Icons.check : Icons.close;

    // First time a code is scanned → show "Record Entry".
    // If the visitor is already checked in → show "Record Exit" instead.
    final checkedIn = pass?.checkedIn ?? false;

    void backToScanner() {
      notifier.resetGuardResult();
      context.go('/guard');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.card)),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                Text(title, style: ChTextStyles.heading(fontSize: 17)),
                const SizedBox(height: 4),
                Text(subtitle, style: ChTextStyles.body(fontSize: 13, color: ChColors.neutralN(600)), textAlign: TextAlign.center),
              ],
            ),
          ),
          if (valid && !checkedIn)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () async {
                  await notifier.recordEntry();
                  if (!context.mounted) return;
                  context.go('/guard');
                  notifier.resetGuardResult();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: ChColors.accent2, borderRadius: BorderRadius.circular(ChRadii.button)),
                  child: Text('Record Entry', style: ChTextStyles.heading(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          if (valid && checkedIn)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () async {
                  await notifier.recordExit();
                  if (!context.mounted) return;
                  context.go('/guard');
                  notifier.resetGuardResult();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: ChColors.accent2, borderRadius: BorderRadius.circular(ChRadii.button)),
                  child: Text('Record Exit', style: ChTextStyles.heading(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          GestureDetector(
            onTap: backToScanner,
            child: Text('← Back to scanner', style: ChTextStyles.body(fontSize: 13, color: ChColors.neutralN(600))),
          ),
        ],
      ),
    );
  }
}