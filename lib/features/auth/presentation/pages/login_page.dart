import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../core/widgets/ch_pill_tabs.dart';
import '../../../../core/widgets/ch_text_field.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';

// Demo credentials for this hint box — matches prisma/seed.ts in
// communityhub-api. Purely a human-readable hint, not app data.
const _demoResidentPhone = '0803 555 0142';
const _demoGuardPhone = '0805 222 9981';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final isResident = s.role == Role.resident;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LoginBanner(),
              const SizedBox(height: 20),
              Text('CommunityHub', style: ChTextStyles.heading(fontSize: 28)),
              const SizedBox(height: 4),
              Text(
                s.estateName ?? 'Palm Court Estate',
                style: ChTextStyles.body(fontSize: 14, color: ChColors.neutralN(600)),
              ),
              const SizedBox(height: 24),
              ChPillTabs(
                options: [
                  ChPillTabOption(label: 'Resident', selected: isResident, onSelect: notifier.setRoleResident),
                  ChPillTabOption(label: 'Security Guard', selected: !isResident, onSelect: notifier.setRoleGuard),
                ],
              ),
              const SizedBox(height: 20),
              ChTextField(
                label: 'Phone number',
                value: s.loginPhone,
                onChanged: notifier.onPhoneChange,
                placeholder: '0803 555 0142',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              ChTextField(
                label: 'Password',
                value: s.loginPassword,
                onChanged: notifier.onPasswordChange,
                placeholder: '••••••••',
                obscureText: true,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: notifier.goForgot,
                  child: Text(
                    'Forgot password?',
                    style: ChTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600, color: ChColors.accentN(700)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (s.loginError.isNotEmpty) ...[
                Text(s.loginError, style: ChTextStyles.body(fontSize: 13, color: ChColors.danger)),
                const SizedBox(height: 12),
              ],
              ChButton(label: 'Log In', onPressed: s.isLoading ? null : notifier.doLogin, isLoading: s.isLoading),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: ChColors.surface,
                  borderRadius: BorderRadius.circular(ChRadii.md),
                ),
                child: RichText(
                  text: TextSpan(
                    style: ChTextStyles.body(fontSize: 12.5, color: ChColors.text.withValues(alpha: 0.65)),
                    children: [
                      TextSpan(text: 'Demo credentials — ${isResident ? 'resident' : 'security guard'}\n'),
                      TextSpan(text: 'Phone '),
                      TextSpan(
                        text: isResident ? _demoResidentPhone : _demoGuardPhone,
                        style: const TextStyle(color: ChColors.text, fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' · Password '),
                      TextSpan(
                        text: isResident ? 'estate123' : 'guard123',
                        style: const TextStyle(color: ChColors.text, fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: '\nTry '),
                      const TextSpan(text: 'temp1234', style: TextStyle(color: ChColors.text, fontWeight: FontWeight.w700)),
                      const TextSpan(text: ' to preview first-time setup.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ChRadii.md),
      child: Container(
        height: 118,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [ChColors.accent2, Color(0xffe1eecc)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _house(44, 50, ChColors.accent2N(700)),
            const SizedBox(width: 10),
            _house(54, 70, ChColors.accent2N(800)),
            const SizedBox(width: 10),
            Container(width: 14, height: 14, margin: const EdgeInsets.only(bottom: 4), decoration: const BoxDecoration(color: ChColors.accent2, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            _house(44, 58, ChColors.accentN(700)),
          ],
        ),
      ),
    );
  }

  Widget _house(double w, double h, Color roofColor) {
    return SizedBox(
      width: w,
      height: h + 18,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: w,
            height: h,
            decoration: const BoxDecoration(
              color: ChColors.bg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
          ),
          Positioned(
            top: 0,
            child: CustomPaint(size: Size(w + 8, 18), painter: _RoofPainter(roofColor)),
          ),
        ],
      ),
    );
  }
}

class _RoofPainter extends CustomPainter {
  _RoofPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _RoofPainter oldDelegate) => oldDelegate.color != color;
}
