import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../core/widgets/ch_text_field.dart';
import '../../../../state/app_notifier.dart';

class ForgotPasswordPage extends ConsumerWidget {
  const ForgotPasswordPage({super.key});

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
              GestureDetector(
                onTap: notifier.backToLogin,
                child: Text('← Back', style: ChTextStyles.body(fontSize: 14, color: ChColors.neutralN(600))),
              ),
              const SizedBox(height: 20),
              Text('Reset password', style: ChTextStyles.heading(fontSize: 22)),
              const SizedBox(height: 6),
              Text(
                "We'll send a one-time code to your registered phone number.",
                style: ChTextStyles.body(fontSize: 14, color: ChColors.neutralN(600)),
              ),
              const SizedBox(height: 22),
              ChTextField(
                label: 'Phone number',
                value: s.forgotPhone,
                onChanged: notifier.onForgotPhoneChange,
                placeholder: '0803 555 0142',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 18),
              ChButton(label: 'Send Code', onPressed: s.isLoading ? null : notifier.sendOtp, isLoading: s.isLoading),
            ],
          ),
        ),
      ),
    );
  }
}
