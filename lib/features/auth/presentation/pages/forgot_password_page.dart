import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../core/widgets/ch_square_icon_button.dart';
import '../../../../state/app_notifier.dart';

class ForgotPasswordPage extends ConsumerWidget {
  const ForgotPasswordPage({super.key});

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
              const _ResetIllustration(),
              SizedBox(height: context.rs(12)),
              Center(
                child: Text(
                  'Reset Your Password',
                  textAlign: TextAlign.center,
                  style: ChTextStyles.heading(fontSize: 24, color: ChColors.accent2),
                ),
              ),
              SizedBox(height: context.rs(8)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.rs(24)),
                child: Text(
                  "Enter your registered phone number and we'll send you a verification code.",
                  textAlign: TextAlign.center,
                  style: ChTextStyles.body(fontSize: 13.5, color: ChColors.text, height: 1.5),
                ),
              ),
              SizedBox(height: context.rs(24)),
              Text(
                'Phone Number',
                style: ChTextStyles.body(fontSize: 13, fontWeight: FontWeight.w500, color: ChColors.text),
              ),
              SizedBox(height: context.rs(6)),
              _PhoneField(value: s.forgotPhone, onChanged: notifier.onForgotPhoneChange),
              if (s.resetMsg.isNotEmpty) ...[
                SizedBox(height: context.rs(12)),
                Text(s.resetMsg, style: ChTextStyles.body(fontSize: 13, color: ChColors.danger)),
              ],
              SizedBox(height: context.rs(22)),
              ChButton(
                label: 'Send Verification Code',
                onPressed: s.isLoading ? null : notifier.sendOtp,
                isLoading: s.isLoading,
              ),
              SizedBox(height: context.rs(20)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_outlined, size: context.rs(24), color: ChColors.accent2N(700)),
                  SizedBox(width: context.rs(8)),
                  Flexible(
                    child: Text(
                      "We'll never share your number with anyone.",
                      textAlign: TextAlign.center,
                      style: ChTextStyles.body(fontSize: 12.5, color: ChColors.text),
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
/// [ChColors.bg] (250,247,243) that it blends in without any masking.
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

/// Same styling as the phone field on the login screen (flag, country code,
/// divider, input, call icon) — duplicated locally rather than shared since
/// neither screen has a widget extracted for it yet.
class _PhoneField extends StatefulWidget {
  const _PhoneField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<_PhoneField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant _PhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.rs(52),
      decoration: BoxDecoration(
        color: const Color(0xfffdfbf9),
        borderRadius: BorderRadius.circular(ChRadii.button),
        border: Border.all(color: ChColors.neutralN(300)),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.rs(12)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🇳🇬', style: TextStyle(fontSize: 20)),
                SizedBox(width: context.rs(6)),
                Text('+234', style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w500)),
                SizedBox(width: context.rs(2)),
                Icon(Icons.keyboard_arrow_down_rounded, size: context.rs(16), color: ChColors.neutralN(600)),
              ],
            ),
          ),
          Container(width: 1, height: context.rs(24), color: ChColors.neutralN(300)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.rs(10)),
              child: TextField(
                controller: _controller,
                onChanged: widget.onChanged,
                keyboardType: TextInputType.phone,
                style: ChTextStyles.body(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintText: 'Enter phone number',
                  hintStyle: ChTextStyles.body(fontSize: 12, color: ChColors.bodyText),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: context.rs(12)),
            child: Icon(Icons.call_outlined, size: context.rs(22), color: ChColors.neutralN(600)),
          ),
        ],
      ),
    );
  }
}
