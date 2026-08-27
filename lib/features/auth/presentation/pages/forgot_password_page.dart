import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_phone_field.dart';
import '../../../../core/widgets/mc_square_icon_button.dart';
import '../../../../state/app_notifier.dart';

class ForgotPasswordPage extends ConsumerWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return Scaffold(
      backgroundColor: McColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(context.rs(20), context.rs(12), context.rs(20), context.rs(28)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              McSquareIconButton(icon: Icons.arrow_back, onTap: notifier.backToLogin),
              const _ResetIllustration(),
              SizedBox(height: context.rs(12)),
              Center(
                child: Text(
                  'Reset Your Password',
                  textAlign: TextAlign.center,
                  style: McTextStyles.heading(fontSize: 24, color: McColors.accent2),
                ),
              ),
              SizedBox(height: context.rs(8)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.rs(24)),
                child: Text(
                  "Enter your registered phone number and we'll send you a verification code.",
                  textAlign: TextAlign.center,
                  style: McTextStyles.body(fontSize: 13.5, color: McColors.text, height: 1.5),
                ),
              ),
              SizedBox(height: context.rs(24)),
              Text(
                'Phone Number',
                style: McTextStyles.body(fontSize: 13, fontWeight: FontWeight.w500, color: McColors.text),
              ),
              SizedBox(height: context.rs(6)),
              McPhoneField(value: s.forgotPhone, onChanged: notifier.onForgotPhoneChange),
              if (s.resetMsg.isNotEmpty) ...[
                SizedBox(height: context.rs(12)),
                Text(s.resetMsg, style: McTextStyles.body(fontSize: 13, color: McColors.danger)),
              ],
              SizedBox(height: context.rs(22)),
              McButton(
                label: 'Send Verification Code',
                onPressed: s.isLoading ? null : notifier.sendOtp,
                isLoading: s.isLoading,
              ),
              SizedBox(height: context.rs(20)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_outlined, size: context.rs(24), color: McColors.accent2N(700)),
                  SizedBox(width: context.rs(8)),
                  Flexible(
                    child: Text(
                      "We'll never share your number with anyone.",
                      textAlign: TextAlign.center,
                      style: McTextStyles.body(fontSize: 12.5, color: McColors.text),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The illustration's own background (~253,250,244) is close enough to
/// [McColors.bg] (250,247,243) that it blends in without any masking.
class _ResetIllustration extends StatelessWidget {
  const _ResetIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.95,
        child: AspectRatio(
          aspectRatio: 1402 / 1122,
          child: Image.asset('assets/images/reset_password_illustration.png', fit: BoxFit.contain),
        ),
      ),
    );
  }
}

