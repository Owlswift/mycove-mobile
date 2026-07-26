import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../core/widgets/ch_text_field.dart';
import '../../../../state/app_notifier.dart';

class GuardCodePage extends ConsumerWidget {
  const GuardCodePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('6-digit fallback code', style: ChTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600, color: ChColors.neutralN(600))),
          const SizedBox(height: 8),
          ChTextField(
            value: s.guardCode,
            onChanged: notifier.onGuardCodeChange,
            placeholder: '000000',
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            letterSpacing: 6,
            fontSize: 22,
          ),
          const SizedBox(height: 16),
          ChButton(
            label: 'Validate',
            onPressed: () async {
              await notifier.submitGuardCode();
              if (context.mounted) context.push('/guard/result');
            },
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Text('← Back to scanner', style: ChTextStyles.body(fontSize: 13, color: ChColors.neutralN(600))),
            ),
          ),
        ],
      ),
    );
  }
}
