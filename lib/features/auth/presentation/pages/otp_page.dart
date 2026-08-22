import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../core/widgets/ch_otp_boxes.dart';
import '../../../../core/widgets/ch_square_icon_button.dart';
import '../../../../state/app_notifier.dart';

class OtpPage extends ConsumerWidget {
  const OtpPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return Scaffold(
      backgroundColor: ChColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(context.rs(20), context.rs(12), context.rs(20), context.rs(28)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChSquareIconButton(icon: Icons.arrow_back, onTap: notifier.backToLogin),
              const _OtpIllustration(),
              SizedBox(height: context.rs(12)),
              Center(
                child: Text(
                  'Enter Verification Code',
                  textAlign: TextAlign.center,
                  style: ChTextStyles.heading(fontSize: 24, color: ChColors.accent2),
                ),
              ),
              SizedBox(height: context.rs(8)),
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.rs(16)),
                  child: Text(
                    "We've sent a 6-digit code to +234 ${s.forgotPhone}",
                    textAlign: TextAlign.center,
                    style: ChTextStyles.body(fontSize: 13.5, color: ChColors.text, height: 1.4),
                  ),
                ),
              ),
              if (s.devOtp != null) ...[
                SizedBox(height: context.rs(4)),
                Center(
                  child: Text(
                    'No SMS provider wired up — demo code: ${s.devOtp}',
                    textAlign: TextAlign.center,
                    style: ChTextStyles.body(fontSize: 11.5, color: ChColors.accent2N(700)),
                  ),
                ),
              ],
              SizedBox(height: context.rs(28)),
              Center(
                child: ChOtpBoxes(value: s.otpCode, onChanged: notifier.onOtpChange),
              ),
              if (s.resetMsg.isNotEmpty) ...[
                SizedBox(height: context.rs(14)),
                Center(
                  child: Text(s.resetMsg, style: ChTextStyles.body(fontSize: 13, color: ChColors.danger)),
                ),
              ],
              SizedBox(height: context.rs(20)),
              Center(child: ChResendRow(onResend: notifier.sendOtp)),
              SizedBox(height: context.rs(24)),
              ChButton(label: 'Verify Code', onPressed: s.isLoading ? null : notifier.verifyOtp, isLoading: s.isLoading),
            ],
          ),
        ),
      ),
    );
  }
}

/// Same asset family as the reset-request screen's illustration — its
/// background (~254,249,244) is close enough to [ChColors.bg] to blend in
/// without masking.
class _OtpIllustration extends StatelessWidget {
  const _OtpIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.95,
        child: AspectRatio(
          aspectRatio: 1402 / 1122,
          child: Image.asset('assets/images/otp_illustration.png', fit: BoxFit.contain),
        ),
      ),
    );
  }
}
