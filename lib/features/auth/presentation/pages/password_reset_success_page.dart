import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../state/app_notifier.dart';

/// Terminal step of the forgot-password flow, shown once
/// [AppNotifier.submitNewPassword] succeeds. "Back to Login" is the only
/// way out — there's nothing left to confirm or retry here.
class PasswordResetSuccessPage extends ConsumerWidget {
  const PasswordResetSuccessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(appStateProvider.notifier);

    return Scaffold(
      backgroundColor: ChColors.bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.rs(28)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _SuccessIllustration(),
              Text(
                'Password Reset Successful!',
                textAlign: TextAlign.center,
                style: ChTextStyles.heading(fontSize: 24, color: ChColors.accent2),
              ),
              SizedBox(height: context.rs(8)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.rs(46)),
                child: Text(
                  'Your password has been updated successfully.',
                  textAlign: TextAlign.center,
                  style: ChTextStyles.body(fontSize: 14, color: ChColors.text),
                ),
              ),
              SizedBox(height: context.rs(32)),
              ChButton(label: 'Back to Login', onPressed: notifier.backToLogin),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessIllustration extends StatelessWidget {
  const _SuccessIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.95,
        child: AspectRatio(
          aspectRatio: 1173 / 1341,
          child: Image.asset('assets/images/password_reset_success_illustration.png', fit: BoxFit.contain),
        ),
      ),
    );
  }
}
