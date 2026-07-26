import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../core/widgets/ch_text_field.dart';
import '../../../../state/app_notifier.dart';

class ForceResetPage extends ConsumerWidget {
  const ForceResetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: ChColors.accent2, borderRadius: BorderRadius.circular(ChRadii.md)),
              ),
              const SizedBox(height: 16),
              Text('Welcome, ${s.currentUser?.first ?? ''}', style: ChTextStyles.heading(fontSize: 22)),
              const SizedBox(height: 6),
              Text(
                'This is your first login. Set a permanent password to continue.',
                style: ChTextStyles.body(fontSize: 14, color: ChColors.neutralN(600)),
              ),
              const SizedBox(height: 22),
              ChTextField(
                value: s.newPass1,
                onChanged: notifier.onNewPass1,
                placeholder: 'New password',
                obscureText: true,
              ),
              const SizedBox(height: 12),
              ChTextField(
                value: s.newPass2,
                onChanged: notifier.onNewPass2,
                placeholder: 'Confirm password',
                obscureText: true,
              ),
              const SizedBox(height: 18),
              if (s.resetMsg.isNotEmpty) ...[
                Text(s.resetMsg, style: ChTextStyles.body(fontSize: 13, color: ChColors.danger)),
                const SizedBox(height: 12),
              ],
              ChButton(
                label: 'Set Password & Continue',
                onPressed: s.isLoading ? null : notifier.completeForceReset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
