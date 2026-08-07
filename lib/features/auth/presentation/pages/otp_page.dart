import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../core/widgets/ch_text_field.dart';
import '../../../../state/app_notifier.dart';

class OtpPage extends ConsumerWidget {
  const OtpPage({super.key});

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
              Text('Enter code', style: ChTextStyles.heading(fontSize: 22)),
              const SizedBox(height: 6),
              Text(
                s.devOtp != null
                    ? 'Sent to ${s.forgotPhone}. (No SMS provider wired up — demo code: ${s.devOtp}.)'
                    : 'Sent to ${s.forgotPhone}.',
                style: ChTextStyles.body(fontSize: 14, color: ChColors.neutralN(600)),
              ),
              const SizedBox(height: 22),
              ChTextField(
                value: s.otpCode,
                onChanged: notifier.onOtpChange,
                placeholder: '0000',
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                letterSpacing: 10,
                fontSize: 22,
              ),
              const SizedBox(height: 18),
              if (s.resetMsg.isNotEmpty) ...[
                Text(s.resetMsg, style: ChTextStyles.body(fontSize: 13, color: ChColors.danger)),
                const SizedBox(height: 12),
              ],
              ChButton(label: 'Verify Code', onPressed: s.isLoading ? null : notifier.verifyOtp, isLoading: s.isLoading),
            ],
          ),
        ),
      ),
    );
  }
}
