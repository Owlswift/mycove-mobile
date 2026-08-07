import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../state/app_notifier.dart';

/// The very first screen a fresh install sees, before any estate has been
/// remembered on this device — matches the Palm Court mockup's landing
/// page. Returning devices skip straight past this (see
/// AppNotifier._bootstrap): once an estate code has been validated once,
/// it's stored and this screen never shows again.
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(appStateProvider.notifier);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: ChColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.holiday_village_rounded, size: 30, color: ChColors.accent2),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CommunityHub', style: ChTextStyles.heading(fontSize: 17)),
                            Text('Palm Court Estate', style: ChTextStyles.body(fontSize: 12, color: ChColors.neutralN(600))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: ChColors.surface,
                      borderRadius: BorderRadius.circular(ChRadii.pill),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.language_rounded, size: 15, color: ChColors.neutralN(700)),
                        const SizedBox(width: 6),
                        Text('Language', style: ChTextStyles.body(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: ChColors.neutralN(700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    // 29, not the scale's 36 — at 36 "all in one place" wraps
                    // across 3 lines and splits "one"/"place" awkwardly; 29
                    // is what reproduces the reference's clean 2-line break
                    // on this screen's width.
                    text: TextSpan(
                      style: ChTextStyles.heroTitle(fontSize: 29),
                      children: [
                        const TextSpan(text: 'Welcome to your community, all in '),
                        TextSpan(text: 'one place', style: ChTextStyles.heroTitle(fontSize: 29, color: ChColors.accent2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Stay informed, make payments, book visitors and connect with your estate seamlessly.',
                    style: ChTextStyles.body(fontSize: 14.5, color: ChColors.neutralN(600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _EstateBanner(),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(24, 26, 24, 22 + bottomInset),
                      decoration: BoxDecoration(
                        color: ChColors.surface,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 28, offset: const Offset(0, -6)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _WelcomeButton(
                            icon: Icons.apartment_rounded,
                            label: 'Find Your Estate',
                            primary: true,
                            onTap: notifier.goToEstateCode,
                          ),
                          const SizedBox(height: 12),
                          _WelcomeButton(
                            icon: Icons.person_outline_rounded,
                            label: 'Log In',
                            primary: false,
                            onTap: notifier.goToEstateCode,
                          ),
                          const SizedBox(height: 12),
                          _WelcomeButton(
                            icon: Icons.verified_user_outlined,
                            label: "I'm a Security Guard",
                            primary: false,
                            onTap: () {
                              notifier.setRoleGuard();
                              notifier.goToEstateCode();
                            },
                          ),
                          const SizedBox(height: 18),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: ChTextStyles.body(fontSize: 13, color: ChColors.neutralN(600)),
                              children: [
                                const TextSpan(text: "New to CommunityHub? "),
                                TextSpan(
                                  text: 'Contact your estate management',
                                  style: ChTextStyles.body(fontSize: 13, fontWeight: FontWeight.w700, color: ChColors.accent2),
                                ),
                                const TextSpan(text: ' for access.'),
                              ],
                            ),
                          ),
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
    );
  }
}

class _WelcomeButton extends StatelessWidget {
  const _WelcomeButton({required this.icon, required this.label, required this.primary, required this.onTap});

  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? ChColors.accent2 : ChColors.surface,
          borderRadius: BorderRadius.circular(ChRadii.button),
          border: primary ? null : Border.all(color: ChColors.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: primary ? Colors.white : ChColors.text),
            const SizedBox(width: 10),
            Text(label, style: ChTextStyles.button(color: primary ? Colors.white : ChColors.text)),
          ],
        ),
      ),
    );
  }
}

/// The estate's gate photo, supplied directly for this screen.
class _EstateBanner extends StatelessWidget {
  const _EstateBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: ChColors.accent2N(800),
      child: Image.asset('assets/images/welcome_banner.png', fit: BoxFit.cover),
    );
  }
}
