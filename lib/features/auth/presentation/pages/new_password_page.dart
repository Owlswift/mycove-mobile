import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../core/widgets/ch_text_field.dart';
import '../../../../state/app_notifier.dart';

class NewPasswordPage extends ConsumerWidget {
  const NewPasswordPage({super.key});

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
              Text('Create new password', style: ChTextStyles.heading(fontSize: 22)),
              const SizedBox(height: 6),
              Text(
                "Choose a password you haven't used before.",
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
              ChButton(label: 'Reset Password', onPressed: s.isLoading ? null : notifier.submitNewPassword, isLoading: s.isLoading),
            ],
          ),
        ),
      ),
    );
  }
}
