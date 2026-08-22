import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_data_media.dart';
import '../../../../core/widgets/ch_help_pill.dart';
import '../../../../core/widgets/ch_password_field.dart';
import '../../../../core/widgets/ch_phone_field.dart';
import '../../../../core/widgets/ch_square_icon_button.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final isResident = s.role == Role.resident;

    return Scaffold(
      backgroundColor: ChColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(context.rs(25), context.rs(12), context.rs(25), context.rs(28)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ChSquareIconButton(
                    icon: Icons.arrow_back,
                    onTap: notifier.backToWelcome,
                  ),
                  ChHelpPill(onTap: () => _showHelp(context)),
                ],
              ),
              SizedBox(height: context.rs(16)),
              _EstateBanner(
                name: s.estateName ?? 'Your Estate',
                address: s.estateAddress,
                image: s.estateImage,
                onChange: s.estateLocked ? null : notifier.changeEstate,
              ),
              SizedBox(height: context.rs(22)),
              Text('Welcome back', style: ChTextStyles.heading(fontSize: 30)),
              SizedBox(height: context.rs(6)),
              Text(
                'Sign in to access your estate community',
                style: ChTextStyles.body(
                  fontSize: 14,
                  color: ChColors.text,
                ),
              ),
              SizedBox(height: context.rs(22)),
              _RoleToggle(
                isResident: isResident,
                onSelectResident: notifier.setRoleResident,
                onSelectGuard: notifier.setRoleGuard,
              ),
              SizedBox(height: context.rs(20)),
              _FieldLabel('Phone Number'),
              SizedBox(height: context.rs(6)),
              ChPhoneField(
                value: s.loginPhone,
                onChanged: notifier.onPhoneChange,
              ),
              SizedBox(height: context.rs(16)),
              _FieldLabel('Password'),
              SizedBox(height: context.rs(6)),
              ChPasswordField(
                value: s.loginPassword,
                onChanged: notifier.onPasswordChange,
              ),
              SizedBox(height: context.rs(14)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => notifier.setRememberMe(!s.rememberMe),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Checkbox(checked: s.rememberMe),
                        SizedBox(width: context.rs(7)),
                        Text(
                          'Remember me',
                          style: ChTextStyles.body(fontSize: 11, color: ChColors.text),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: notifier.goForgot,
                    child: Text(
                      'Forgot password?',
                      style: ChTextStyles.body(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ChColors.accent2,
                      ),
                    ),
                  ),
                ],
              ),
              if (s.loginError.isNotEmpty) ...[
                SizedBox(height: context.rs(12)),
                Text(
                  s.loginError,
                  style: ChTextStyles.body(
                    fontSize: 13,
                    color: ChColors.danger,
                  ),
                ),
              ],
              SizedBox(height: context.rs(28)),
              GestureDetector(
                onTap: s.isLoading ? null : notifier.doLogin,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: context.rs(15),
                    horizontal: context.rs(20),
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
                                size: context.rs(22),
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: context.rs(28)),
              Container(
                padding: EdgeInsets.all(context.rs(14)),
                decoration: BoxDecoration(
                  color: ChColors.surfaceSunken,
                  borderRadius: BorderRadius.circular(ChRadii.button),
                  border: Border.all(color: ChColors.divider)
                ),
                child: Row(
                  children: [
                    Container(
                      width: context.rs(50),
                      height: context.rs(50),
                      decoration: BoxDecoration(
                        color: ChColors.accent2N(100),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified_user_outlined,
                        size: context.rs(24),
                        color: ChColors.accent2N(700),
                      ),
                    ),
                    SizedBox(width: context.rs(18)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Secure & Private',
                            style: ChTextStyles.body(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: ChColors.text
                            ),
                          ),
                          SizedBox(height: context.rs(2)),
                          Padding(
                            padding: EdgeInsets.only(right: context.rs(20)),
                            child: Text(
                              'Your information is encrypted and protected. We value your privacy.',
                              style: ChTextStyles.body(
                                fontSize: 11,
                                color: ChColors.text,
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
              SizedBox(height: context.rs(30)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.rs(50)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: context.rs(2)),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: context.rs(19),
                        color: ChColors.text,
                      ),
                    ),
                    SizedBox(width: context.rs(6)),
                    Expanded(
                      child: RichText(
                        textAlign: TextAlign.left,
                        text: TextSpan(
                          style: ChTextStyles.body(
                            fontSize: 11,
                            color: ChColors.text,
                            height: 1.8,
                          ),
                          children: [
                            const TextSpan(
                              text: 'By continuing, you agree to our ',
                            ),
                            TextSpan(
                              text: 'Terms of Service',
                              style: ChTextStyles.body(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: ChColors.accent2,
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: ChTextStyles.body(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: ChColors.accent2,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
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
    );
  }

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trouble logging in?'),
        content: const Text(
          "Double-check your phone number and password. If you've forgotten your password, use \"Forgot password?\" below, or contact your estate management office.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: ChColors.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: ChTextStyles.body(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: ChColors.text,
      ),
    );
  }
}

/// The estate card + photo above "Welcome back" — a photo peeking out from
/// behind a narrower info card, matching the estate-code/estate-found
/// screens' visual language rather than the flat banner this replaces.
class _EstateBanner extends StatelessWidget {
  const _EstateBanner({
    required this.name,
    required this.address,
    required this.image,
    required this.onChange,
  });

  final String name;
  final String? address;
  final String? image;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.rs(128),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final photoWidth = constraints.maxWidth * 0.52;
          final cardWidth = constraints.maxWidth * 0.68;
          return Stack(
            children: [
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: photoWidth,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ChRadii.card),
                  child: image != null
                      ? ChDataMedia(dataUrl: image!)
                      : Image.asset(
                          'assets/images/welcome_banner.png',
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                width: cardWidth,
                child: Container(
                  padding: EdgeInsets.all(context.rs(14)),
                  decoration: BoxDecoration(
                    color: ChColors.surface,
                    borderRadius: BorderRadius.circular(ChRadii.card),
                    boxShadow: ChColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: context.rs(40),
                            height: context.rs(40),
                            decoration: BoxDecoration(
                              color: ChColors.accent2N(100),
                              borderRadius: BorderRadius.circular(ChRadii.sm),
                            ),
                            child: Icon(
                              Icons.park_outlined,
                              size: context.rs(20),
                              color: ChColors.accent2N(700),
                            ),
                          ),
                          SizedBox(width: context.rs(10)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ChTextStyles.heading(fontSize: 15),
                                ),
                                if (address != null) ...[
                                  SizedBox(height: context.rs(2)),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: context.rs(12),
                                        color: ChColors.text,
                                      ),
                                      SizedBox(width: context.rs(3)),
                                      Expanded(
                                        child: Text(
                                          address!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: ChTextStyles.body(
                                            fontSize: 11,
                                            color: ChColors.text,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (onChange != null)
                        GestureDetector(
                          onTap: onChange,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Change',
                                style: ChTextStyles.body(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: ChColors.accent2,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: context.rs(16),
                                color: ChColors.accent2,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoleToggle extends StatelessWidget {
  const _RoleToggle({
    required this.isResident,
    required this.onSelectResident,
    required this.onSelectGuard,
  });

  final bool isResident;
  final VoidCallback onSelectResident;
  final VoidCallback onSelectGuard;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleButton(
            icon: Icons.people_alt_rounded,
            label: 'Resident',
            selected: isResident,
            onTap: onSelectResident,
          ),
        ),
        SizedBox(width: context.rs(10)),
        Expanded(
          child: _RoleButton(
            icon: Icons.verified_user_outlined,
            label: 'Security Guard',
            selected: !isResident,
            onTap: onSelectGuard,
          ),
        ),
      ],
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: context.rs(13)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? ChColors.accent2 : ChColors.surfaceSunken,
          borderRadius: BorderRadius.circular(ChRadii.button),
          border: Border.all(color: ChColors.neutralN(200)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: context.rs(22),
              color: selected ? Colors.white : ChColors.neutralN(700),
            ),
            SizedBox(width: context.rs(6)),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: ChTextStyles.body(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: selected ? Colors.white : ChColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.rs(20),
      height: context.rs(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: checked ? ChColors.accent2 : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border: checked
            ? null
            : Border.all(color: ChColors.divider, width: 1.5),
      ),
      child: checked
          ? Icon(Icons.check_rounded, size: context.rs(14), color: Colors.white)
          : null,
    );
  }
}
