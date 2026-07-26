import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../state/app_notifier.dart';

class GuardScanPage extends ConsumerWidget {
  const GuardScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(appStateProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          Container(
            height: 220,
            width: double.infinity,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(color: ChColors.neutralN(900), borderRadius: BorderRadius.circular(ChRadii.lg)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: ChColors.accentN(400), width: 2.5),
                    borderRadius: BorderRadius.circular(ChRadii.md),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Point camera at visitor QR code',
                  style: ChTextStyles.body(fontSize: 12.5, color: ChColors.neutralN(300)),
                ),
              ],
            ),
          ),
          ChButton(label: 'Simulate Scan', onPressed: () async {
            await notifier.simulateScan();
            if (context.mounted) context.push('/guard/result');
          }),
          const SizedBox(height: 12),
          ChButton(
            label: 'Enter Code Instead',
            variant: ChButtonVariant.secondary,
            onPressed: () => context.push('/guard/code'),
          ),
        ],
      ),
    );
  }
}
