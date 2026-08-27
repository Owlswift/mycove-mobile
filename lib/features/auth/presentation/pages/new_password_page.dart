import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_password_field.dart';
import '../../../../core/widgets/mc_square_icon_button.dart';
import '../../../../state/app_notifier.dart';

class NewPasswordPage extends ConsumerWidget {
  const NewPasswordPage({super.key});

  int _rulesMet(String password) {
    var count = 0;
    if (password.length >= 8) count++;
    if (password.contains(RegExp(r'[0-9]'))) count++;
    if (password.contains(RegExp(r'[A-Z]'))) count++;
    return count;
  }

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
              McSquareIconButton(icon: Icons.arrow_back, onTap: notifier.backToOtp),
              const _PadlockIllustration(),
              SizedBox(height: context.rs(12)),
              Center(
                child: Text(
                  'Create New Password',
                  textAlign: TextAlign.center,
                  style: McTextStyles.heading(fontSize: 24, color: McColors.accent2),
                ),
              ),
              SizedBox(height: context.rs(8)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.rs(70)),
                child: Text(
                  'Your new password must be different from previous passwords.',
                  textAlign: TextAlign.center,
                  style: McTextStyles.body(fontSize: 13.5, color: McColors.text, height: 1.4),
                ),
              ),
              SizedBox(height: context.rs(24)),
              Text(
                'New Password',
                style: McTextStyles.body(fontSize: 13, fontWeight: FontWeight.w500, color: McColors.text),
              ),
              SizedBox(height: context.rs(6)),
              McPasswordField(
                value: s.newPass1,
                onChanged: notifier.onNewPass1,
                hintText: 'Enter new password',
              ),
              SizedBox(height: context.rs(10)),
              _RuleCheckList(rulesMet: _rulesMet(s.newPass1), hasInput: s.newPass1.isNotEmpty),
              SizedBox(height: context.rs(16)),
              Text(
                'Confirm New Password',
                style: McTextStyles.body(fontSize: 13, fontWeight: FontWeight.w500, color: McColors.text),
              ),
              SizedBox(height: context.rs(6)),
              McPasswordField(
                value: s.newPass2,
                onChanged: notifier.onNewPass2,
                hintText: 'Confirm new password',
              ),
              if (s.resetMsg.isNotEmpty) ...[
                SizedBox(height: context.rs(12)),
                Text(s.resetMsg, style: McTextStyles.body(fontSize: 13, color: McColors.danger)),
              ],
              SizedBox(height: context.rs(24)),
              McButton(
                label: 'Reset Password',
                onPressed: s.isLoading ? null : notifier.submitNewPassword,
                isLoading: s.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Real illustration asset (pre-cut with transparency via Photoroom, unlike
/// the flat-background ones used elsewhere in this flow) — no masking needed.
class _PadlockIllustration extends StatelessWidget {
  const _PadlockIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.95,
        child: AspectRatio(
          aspectRatio: 1402 / 1122,
          child: Image.asset('assets/images/new_password_illustration.png', fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// Vertically-stacked rule rows (met = filled green check, unmet = outline)
/// — this mockup lists rules one per row rather than in the 3-column layout
/// used on the force-reset screen's own password step.
class _RuleCheckList extends StatelessWidget {
  const _RuleCheckList({required this.rulesMet, required this.hasInput});

  final int rulesMet;
  final bool hasInput;

  @override
  Widget build(BuildContext context) {
    final met = hasInput
        ? [rulesMet >= 1, rulesMet >= 2, rulesMet >= 3]
        : [false, false, false];
    const labels = ['At least 8 characters', 'Contains a number', 'Contains an uppercase letter'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: context.rs(6), left: context.rs(6)),
            child: Row(
              children: [
                Icon(
                  met[i] ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                  size: context.rs(18),
                  color: met[i] ? McColors.accent2 : McColors.neutralN(400),
                ),
                SizedBox(width: context.rs(12)),
                Text(
                  labels[i],
                  style: McTextStyles.body(
                    fontSize: 12,
                    color: met[i] ? McColors.accent2 : McColors.bodyText,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
