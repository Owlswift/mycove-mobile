import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_brand_mark.dart';
import '../../../../state/app_notifier.dart';

/// The very first screen a fresh install sees, before any estate has been
/// remembered on this device. Returning devices skip straight past this
/// (see AppNotifier._bootstrap): once an estate code has been validated
/// once, it's stored and this screen never shows again.
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(appStateProvider.notifier);
    final heroHeight = MediaQuery.sizeOf(context).height * 0.32;

    return Scaffold(
      backgroundColor: ChColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: context.rs(8)),
              const ChBrandMark(),
              SizedBox(height: context.rs(10)),
              RichText(
                text: TextSpan(
                  style: ChTextStyles.heading(fontSize: 28),
                  children: [
                    const TextSpan(text: 'Community'),
                    TextSpan(
                      text: 'Hub',
                      style: ChTextStyles.heading(
                        fontSize: 28,
                        color: ChColors.accent2,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.rs(4)),
              Text(
                'Your Community. Connected.',
                style: ChTextStyles.body(
                  fontSize: 13,
                  color: ChColors.bodyText,
                ),
              ),
              _HeroPhoto(height: heroHeight),
              SizedBox(height: context.rs(4)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.rs(16),
                  vertical: context.rs(9),
                ),
                decoration: BoxDecoration(
                  color: ChColors.accent2N(100),
                  borderRadius: BorderRadius.circular(ChRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      size: context.rs(15),
                      color: ChColors.accent2N(700),
                    ),
                    SizedBox(width: context.rs(7)),
                    Text(
                      'Secure • Private • Trusted',
                      style: ChTextStyles.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ChColors.accent2N(800),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.rs(20)),
              Text(
                'Welcome Home',
                style: ChTextStyles.heroTitle(
                  fontSize: 32,
                  color: ChColors.accent2,
                ),
              ),
              SizedBox(height: context.rs(12)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.rs(56)),
                child: Text(
                  'MyCove brings your whole estate together. Stay informed, make payments, manage visitors and more.',
                  textAlign: TextAlign.center,
                  style: ChTextStyles.body(
                    fontSize: 14,
                    height: 1.5,
                    color: ChColors.bodyText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: context.rs(26)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.rs(24)),
                child: GestureDetector(
                  onTap: notifier.goToEstateCode,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: context.rs(16),
                      horizontal: context.rs(20),
                    ),
                    decoration: BoxDecoration(
                      color: ChColors.accent2,
                      borderRadius: BorderRadius.circular(ChRadii.button),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text('Get Started', style: ChTextStyles.button()),
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
              ),
              SizedBox(height: context.rs(24)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.rs(24)),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: ChColors.divider)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.rs(12)),
                      child: Text(
                        'Trusted by communities',
                        style: ChTextStyles.body(
                          fontSize: 12.5,
                          color: ChColors.bodyText,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: ChColors.divider)),
                  ],
                ),
              ),
              SizedBox(height: context.rs(20)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.rs(24)),
                child: Row(
                  children: const [
                    Expanded(
                      child: _TrustItem(
                        icon: Icons.verified_user_outlined,
                        label: 'Safe & Secure',
                      ),
                    ),
                    Expanded(
                      child: _TrustItem(
                        icon: Icons.groups_outlined,
                        label: 'Community First',
                      ),
                    ),
                    Expanded(
                      child: _TrustItem(
                        icon: Icons.notifications_outlined,
                        label: 'Always Informed',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.rs(20)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The estate's gate photo, faded into the page background at the bottom
/// rather than ending in a hard rectangular edge — same technique used on
/// the estate-found/onboarding-complete celebration graphics.
class _HeroPhoto extends StatelessWidget {
  const _HeroPhoto({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.black, Colors.black, Colors.transparent],
        stops: [0.0, 0.55, 1.0],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: Image.asset(
        'assets/images/welcome_banner.png',
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: context.rs(48),
          height: context.rs(48),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ChColors.accent2N(100),
            borderRadius: BorderRadius.circular(ChRadii.md),
          ),
          child: Icon(icon, size: context.rs(28), color: ChColors.accent2N(700)),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: ChTextStyles.body(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: ChColors.bodyText,
          ),
        ),
      ],
    );
  }
}
