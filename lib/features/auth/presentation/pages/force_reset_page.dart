import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_help_pill.dart';
import '../../../../core/widgets/ch_password_field.dart';
import '../../../../core/widgets/ch_square_icon_button.dart';
import '../../../../state/app_notifier.dart';

/// First-login flow for an admin-created account: this is a two-step
/// *local* wizard (both steps stay on AuthStage.forceReset — there's
/// nothing for go_router to do here) rather than two separate stages,
/// since [AppNotifier.completeForceReset] already expects password and
/// profile fields together in one call. Step 1 (password) is purely a
/// client-side gate before step 2 (profile) can even be reached.
class ForceResetPage extends ConsumerStatefulWidget {
  const ForceResetPage({super.key});

  @override
  ConsumerState<ForceResetPage> createState() => _ForceResetPageState();
}

class _ForceResetPageState extends ConsumerState<ForceResetPage> {
  int _step = 0;
  String _passwordError = '';

  int _rulesMet(String password) {
    var count = 0;
    if (password.length >= 8) count++;
    if (password.contains(RegExp(r'[0-9]'))) count++;
    if (password.contains(RegExp(r'[A-Z]'))) count++;
    return count;
  }

  void _continueFromPassword(String pass1, String pass2) {
    if (_rulesMet(pass1) < 3) {
      setState(
        () => _passwordError =
            'Your password doesn\'t meet all the requirements below yet.',
      );
      return;
    }
    if (pass1 != pass2) {
      setState(() => _passwordError = 'Passwords do not match.');
      return;
    }
    setState(() {
      _passwordError = '';
      _step = 1;
    });
  }

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Need help?'),
        content: const Text(
          'Contact your estate management office if you have trouble setting up your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(appStateProvider.notifier);
    return Scaffold(
      backgroundColor: ChColors.bg,
      body: SafeArea(
        child: _step == 0
            ? _PasswordStep(
                error: _passwordError,
                onBack: notifier.backToLogin,
                onContinue: _continueFromPassword,
                rulesMet: _rulesMet,
                onShowHelp: () => _showHelp(context),
              )
            : _ProfileStep(onBack: () => setState(() => _step = 0)),
      ),
    );
  }
}

class _PasswordStep extends ConsumerWidget {
  const _PasswordStep({
    required this.error,
    required this.onBack,
    required this.onContinue,
    required this.rulesMet,
    required this.onShowHelp,
  });

  final String error;
  final VoidCallback onBack;
  final void Function(String pass1, String pass2) onContinue;
  final int Function(String password) rulesMet;
  final VoidCallback onShowHelp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final met = rulesMet(s.newPass1);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChSquareIconButton(icon: Icons.arrow_back, onTap: onBack),
          const _CelebrationGraphic(),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text('Welcome to', style: ChTextStyles.heading(fontSize: 32)),
                Text(
                  '${s.estateName ?? 'your estate'}!',
                  textAlign: TextAlign.center,
                  style: ChTextStyles.heading(
                    fontSize: 32,
                    color: ChColors.accent2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 70),
            child: Center(
              child: Text(
                'Your account has been created by the estate management. For your security, please set a new password to continue.',
                textAlign: TextAlign.center,
                style: ChTextStyles.body(
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xfff4f5f0),
                borderRadius: BorderRadius.circular(ChRadii.card),
                border: Border.all(color: const Color(0xffe9ebe6)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: context.rs(60),
                    height: context.rs(60),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: ChColors.accent2N(200)),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: context.rs(44),
                          color: ChColors.accent2N(700),
                        ),
                        Icon(
                          Icons.lock,
                          size: context.rs(18),
                          color: ChColors.accent2N(700),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: context.rs(14)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Keep your account secure',
                          style: ChTextStyles.body(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: ChColors.accent2N(800),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.only(right: 30),
                          child: Text(
                            "Choose a strong password that you don't use on other apps.",
                            style: ChTextStyles.body(
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'New Password',
            style: ChTextStyles.body(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          ChPasswordField(
            value: s.newPass1,
            onChanged: notifier.onNewPass1,
            hintText: 'Enter new password',
          ),
          const SizedBox(height: 8),
          _StrengthMeter(rulesMet: met, hasInput: s.newPass1.isNotEmpty),
          const SizedBox(height: 16),
          Text(
            'Confirm New Password',
            style: ChTextStyles.body(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          ChPasswordField(
            value: s.newPass2,
            onChanged: notifier.onNewPass2,
            hintText: 'Confirm new password',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xfff4f5f0),
              borderRadius: BorderRadius.circular(ChRadii.sm),
              border: Border.all(color: const Color(0xffe9ebe6)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _RuleCheck(
                    label: 'At least 8 characters',
                    met: s.newPass1.length >= 8,
                  ),
                ),
                Expanded(
                  child: _RuleCheck(
                    label: 'Include a number',
                    met: s.newPass1.contains(RegExp(r'[0-9]')),
                  ),
                ),
                Expanded(
                  child: _RuleCheck(
                    label: 'Include an uppercase letter',
                    met: s.newPass1.contains(RegExp(r'[A-Z]')),
                  ),
                ),
              ],
            ),
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              error,
              style: ChTextStyles.body(fontSize: 13, color: ChColors.danger),
            ),
          ],
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => onContinue(s.newPass1, s.newPass2),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 20,
              ),
              decoration: BoxDecoration(
                color: ChColors.accent2,
                borderRadius: BorderRadius.circular(ChRadii.button),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'Continue',
                    style: ChTextStyles.body(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: context.rs(18),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: GestureDetector(
              onTap: onShowHelp,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: context.rs(15),
                    color: ChColors.neutralN(600),
                  ),
                  SizedBox(width: context.rs(6)),
                  RichText(
                    text: TextSpan(
                      style: ChTextStyles.body(
                        fontSize: 13,
                        color: ChColors.bodyText,
                      ),
                      children: [
                        const TextSpan(text: 'Need help? '),
                        TextSpan(
                          text: 'Contact estate management',
                          style: ChTextStyles.body(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ChColors.accent2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CelebrationGraphic extends StatelessWidget {
  const _CelebrationGraphic();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: context.rs(150),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/5b2b41ac-38ab-4b30-9c9b-1678f038d2ef.png',
            height: context.rs(150),
          ),
          Align(
            alignment: const Alignment(0.3, 0.9),
            child: Container(
              width: context.rs(50),
              height: context.rs(50),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ChColors.surface,
                shape: BoxShape.circle,
                boxShadow: ChColors.cardShadow,
              ),
              child: Icon(
                Icons.check_rounded,
                size: context.rs(38),
                color: ChColors.accent2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.rulesMet, required this.hasInput});

  final int rulesMet;
  final bool hasInput;

  @override
  Widget build(BuildContext context) {
    final filled = hasInput ? rulesMet + 1 : 0;
    final label = switch (rulesMet) {
      0 || 1 => 'Weak',
      2 => 'Fair',
      _ => 'Strong',
    };
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) SizedBox(width: context.rs(4)),
          Container(
            width: context.rs(48),
            height: 4,
            decoration: BoxDecoration(
              color: i < filled ? ChColors.accent2 : ChColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
        SizedBox(width: context.rs(10)),
        Text(
          label,
          style: ChTextStyles.body(fontSize: 12),
        ),
      ],
    );
  }
}

class _RuleCheck extends StatelessWidget {
  const _RuleCheck({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outlined,
            size: context.rs(16),
            color: met ? ChColors.accent2 : ChColors.neutralN(400),
          ),
          SizedBox(width: context.rs(6)),
          Expanded(
            child: Text(
              label,
              style: ChTextStyles.body(
                fontSize: 10.5,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Profile completion — full name/house are enforced client-side in
/// [AppNotifier.completeForceReset] (dashboard greeting etc. depend on
/// fullName being set), even though the backend itself treats them as
/// optional. No mockup existed for this step, so it keeps the prior
/// screen's fields/layout as-is.
class _ProfileStep extends ConsumerWidget {
  const _ProfileStep({required this.onBack});

  final VoidCallback onBack;

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Need help?'),
        content: const Text(
          'Contact your estate management office if you have trouble completing your profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ChSquareIconButton(
                icon: Icons.arrow_back,
                onTap: onBack,
                iconColor: ChColors.accent2,
              ),
              ChHelpPill(
                onTap: () => _showHelp(context),
                color: ChColors.accent2,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _StepProgress(current: 1, total: 1),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Complete Your Profile',
              style: ChTextStyles.heading(fontSize: 26),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Help us personalize your experience and keep your community secure.',
              textAlign: TextAlign.center,
              style: ChTextStyles.body(
                fontSize: 14,
                color: ChColors.bodyText,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _AvatarPicker(),
          const SizedBox(height: 24),
          _ProfileField(
            icon: Icons.person_outline_rounded,
            label: 'Full Name',
            value: s.setupFullName,
            onChanged: notifier.onSetupFullName,
            hint: 'Enter your full name',
          ),
          const SizedBox(height: 12),
          _ProfileField(
            icon: Icons.home_outlined,
            label: 'House Address',
            value: s.setupHouse,
            onChanged: notifier.onSetupHouse,
            hint: 'House number, street, estate',
            trailing: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: ChColors.neutralN(600),
            ),
          ),
          const SizedBox(height: 12),
          _ProfileField(
            icon: Icons.directions_car_outlined,
            label: 'Vehicle Plate Number',
            optional: true,
            value: s.setupVehiclePlates,
            onChanged: notifier.onSetupVehiclePlates,
            hint: 'e.g. ABC-123-XY',
          ),
          const SizedBox(height: 6),
          Text(
            'Add your vehicle plate number for easy gate access.',
            style: ChTextStyles.body(
              fontSize: 12,
              color: ChColors.bodyText,
            ),
          ),
          const SizedBox(height: 12),
          _ProfileField(
            icon: Icons.mail_outline_rounded,
            label: 'Email Address',
            optional: true,
            value: s.setupEmail,
            onChanged: notifier.onSetupEmail,
            hint: 'Enter your email address',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _EmergencyContactField(
            value: s.setupEmergencyContactPhone,
            onChanged: notifier.onSetupEmergencyContactPhone,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ChColors.surfaceSunken,
              borderRadius: BorderRadius.circular(ChRadii.card),
            ),
            child: Row(
              children: [
                Container(
                  width: context.rs(44),
                  height: context.rs(44),
                  decoration: BoxDecoration(
                    color: ChColors.accent2N(100),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified_user_outlined,
                    size: context.rs(21),
                    color: ChColors.accent2N(700),
                  ),
                ),
                SizedBox(width: context.rs(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your information is secure',
                        style: ChTextStyles.body(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: ChColors.accent2N(800),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your details are encrypted and only visible to estate management.',
                        style: ChTextStyles.body(
                          fontSize: 12,
                          color: ChColors.bodyText,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (s.resetMsg.isNotEmpty) ...[
            Text(
              s.resetMsg,
              style: ChTextStyles.body(fontSize: 13, color: ChColors.danger),
            ),
            const SizedBox(height: 12),
          ],
          GestureDetector(
            onTap: s.isLoading ? null : notifier.completeForceReset,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 20,
              ),
              decoration: BoxDecoration(
                color: ChColors.accent2,
                borderRadius: BorderRadius.circular(ChRadii.button),
              ),
              child: s.isLoading
                  ? Center(
                      child: SizedBox(
                        width: context.rs(20),
                        height: context.rs(20),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          'Save & Continue',
                          style: ChTextStyles.body(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: context.rs(18),
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Step $current of $total',
          style: ChTextStyles.body(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: ChColors.accent2,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: current / total,
            minHeight: 6,
            backgroundColor: ChColors.divider,
            valueColor: const AlwaysStoppedAnimation(ChColors.accent2),
          ),
        ),
      ],
    );
  }
}

/// No photo-upload support exists in the backend (CurrentUser has no
/// avatar field) — tapping this tells the resident that plainly instead
/// of silently doing nothing, since the pencil badge visually promises
/// it's tappable.
class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: ChColors.accent2N(100),
        borderRadius: BorderRadius.circular(ChRadii.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 4,
            left: 24,
            child: Icon(
              Icons.home_outlined,
              size: context.rs(20),
              color: ChColors.accent2N(300),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 30,
            child: Icon(
              Icons.park_outlined,
              size: context.rs(22),
              color: ChColors.accent2N(300),
            ),
          ),
          Positioned(
            top: 10,
            right: 40,
            child: Icon(
              Icons.home_work_outlined,
              size: context.rs(18),
              color: ChColors.accent2N(300),
            ),
          ),
          GestureDetector(
            onTap: () => _showComingSoon(context),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: context.rs(84),
                  height: context.rs(84),
                  decoration: BoxDecoration(
                    color: ChColors.accent2N(200),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: context.rs(46),
                    color: ChColors.accent2N(600),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: context.rs(30),
                    height: context.rs(30),
                    decoration: BoxDecoration(
                      color: ChColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: ChColors.cardShadow,
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      size: context.rs(15),
                      color: ChColors.accent2N(700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile photos aren't supported yet.")),
    );
  }
}

/// Icon-in-box + stacked bold label/hint pattern used throughout this
/// screen — a plain [ChTextField] doesn't match this look (label above
/// the field rather than inline with a leading icon).
class _ProfileField extends StatefulWidget {
  const _ProfileField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.hint,
    this.optional = false,
    this.keyboardType,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final bool optional;
  final String value;
  final ValueChanged<String> onChanged;
  final String hint;
  final TextInputType? keyboardType;
  final Widget? trailing;

  @override
  State<_ProfileField> createState() => _ProfileFieldState();
}

class _ProfileFieldState extends State<_ProfileField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant _ProfileField oldWidget) {
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: ChColors.surface,
        borderRadius: BorderRadius.circular(ChRadii.button),
        border: Border.all(color: ChColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: context.rs(40),
            height: context.rs(40),
            decoration: BoxDecoration(
              color: ChColors.accent2N(100),
              borderRadius: BorderRadius.circular(ChRadii.sm),
            ),
            child: Icon(widget.icon, size: context.rs(19), color: ChColors.accent2N(700)),
          ),
          SizedBox(width: context.rs(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style: ChTextStyles.body(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      TextSpan(text: widget.label),
                      if (widget.optional)
                        TextSpan(
                          text: ' (Optional)',
                          style: ChTextStyles.body(
                            fontSize: 12,
                            color: ChColors.neutralN(500),
                          ),
                        ),
                    ],
                  ),
                ),
                TextField(
                  controller: _controller,
                  onChanged: widget.onChanged,
                  keyboardType: widget.keyboardType,
                  style: ChTextStyles.body(
                    fontSize: 13.5,
                    color: ChColors.bodyText,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: ChTextStyles.body(
                      fontSize: 13.5,
                      color: ChColors.neutralN(500),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.trailing != null) widget.trailing!,
        ],
      ),
    );
  }
}

/// Simplified from the old two-field (name + phone) emergency contact —
/// this screen only collects a phone number, matching the design; the
/// name field is left unset (it's optional server-side).
class _EmergencyContactField extends StatefulWidget {
  const _EmergencyContactField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_EmergencyContactField> createState() => _EmergencyContactFieldState();
}

class _EmergencyContactFieldState extends State<_EmergencyContactField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant _EmergencyContactField oldWidget) {
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: ChColors.surface,
        borderRadius: BorderRadius.circular(ChRadii.button),
        border: Border.all(color: ChColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: context.rs(40),
            height: context.rs(40),
            decoration: BoxDecoration(
              color: ChColors.accent2N(100),
              borderRadius: BorderRadius.circular(ChRadii.sm),
            ),
            child: Icon(
              Icons.call_outlined,
              size: context.rs(19),
              color: ChColors.accent2N(700),
            ),
          ),
          SizedBox(width: context.rs(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style: ChTextStyles.body(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      const TextSpan(text: 'Emergency Contact'),
                      TextSpan(
                        text: ' (Optional)',
                        style: ChTextStyles.body(
                          fontSize: 12,
                          color: ChColors.neutralN(500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('🇳🇬', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '+234',
                      style: ChTextStyles.body(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 1, height: context.rs(16), color: ChColors.divider),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: widget.onChanged,
                        keyboardType: TextInputType.phone,
                        style: ChTextStyles.body(
                          fontSize: 13.5,
                          color: ChColors.bodyText,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          hintText: 'Enter phone number',
                          hintStyle: ChTextStyles.body(
                            fontSize: 13.5,
                            color: ChColors.neutralN(500),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
