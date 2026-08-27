import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
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
            height: context.rs(220),
            width: double.infinity,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(color: McColors.neutralN(900), borderRadius: BorderRadius.circular(McRadii.lg)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: context.rs(150),
                  height: context.rs(150),
                  decoration: BoxDecoration(
                    border: Border.all(color: McColors.accentN(400), width: 2.5),
                    borderRadius: BorderRadius.circular(McRadii.md),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Point camera at visitor QR code',
                  style: McTextStyles.body(fontSize: 12.5, color: McColors.neutralN(300)),
                ),
              ],
            ),
          ),
          McButton(label: 'Simulate Scan', onPressed: () async {
            final error = await notifier.simulateScan();
            if (!context.mounted) return;
            if (error != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
              return;
            }
            context.push('/guard/result');
          }),
          const SizedBox(height: 12),
          McButton(
            label: 'Enter Code Instead',
            variant: ChButtonVariant.secondary,
            onPressed: () => context.push('/guard/code'),
          ),
        ],
      ),
    );
  }
}
