import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../state/app_notifier.dart';

/// Shown once, right after [AppNotifier.completeForceReset] succeeds —
/// data's already loaded by then, so tapping through here is just a
/// authStage flip (see [AppNotifier.finishOnboarding]), not another fetch.
class OnboardingCompletePage extends ConsumerWidget {
  const OnboardingCompletePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(appStateProvider.notifier);

    return Scaffold(
      backgroundColor: ChColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SuccessGraphic(),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'You\'re All Set!',
                  style: ChTextStyles.heading(
                    fontSize: 28,
                    color: ChColors.accent2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Your profile has been updated successfully. You can now access all community features.',
                  textAlign: TextAlign.center,
                  style: ChTextStyles.body(
                    fontSize: 14,
                    color: ChColors.bodyText,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: ChColors.surface,
                  borderRadius: BorderRadius.circular(ChRadii.card),
                  boxShadow: ChColors.cardShadow,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: ChColors.accent2N(100),
                      child: Text(
                        "What's next?",
                        style: ChTextStyles.heading(
                          fontSize: 16,
                          color: ChColors.accent2N(800),
                        ),
                      ),
                    ),
                    _NextStepRow(
                      icon: Icons.notifications_none_rounded,
                      title: 'Stay informed',
                      description:
                          'Get important notices and updates from your estate management.',
                      showBorder: true,
                    ),
                    _NextStepRow(
                      icon: Icons.groups_outlined,
                      title: 'Get involved',
                      description:
                          'View community projects, meetings and announcements.',
                      showBorder: true,
                    ),
                    _NextStepRow(
                      icon: Icons.shield_outlined,
                      title: 'Stay secure',
                      description:
                          'Manage visitors, access codes and other security features.',
                      showBorder: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: notifier.finishOnboarding,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ChColors.accent2,
                    borderRadius: BorderRadius.circular(ChRadii.button),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Go to Dashboard',
                        style: ChTextStyles.body(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: context.rs(8)),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: context.rs(18),
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: notifier.finishOnboarding,
                  child: Text(
                    'Explore App Features',
                    style: ChTextStyles.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ChColors.accent2,
                    ),
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

class _NextStepRow extends StatelessWidget {
  const _NextStepRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.showBorder,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showBorder
            ? const Border(bottom: BorderSide(color: ChColors.divider))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.rs(40),
            height: context.rs(40),
            decoration: BoxDecoration(
              color: ChColors.accent2N(100),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: context.rs(19), color: ChColors.accent2N(700)),
          ),
          SizedBox(width: context.rs(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ChTextStyles.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: ChTextStyles.body(
                    fontSize: 12.5,
                    color: ChColors.bodyText,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Checkmark badge (with a soft radial glow and scattered confetti,
/// matching the estate-found/force-reset celebration graphics) sitting
/// over the estate photo, which is arch-clipped and fades out at the
/// bottom to blend into the page background rather than ending in a
/// hard rectangular edge.
class _SuccessGraphic extends StatelessWidget {
  const _SuccessGraphic();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.rs(260),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: EdgeInsets.only(top: context.rs(56)),
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.black, Colors.transparent],
                stops: [0.0, 0.65, 1.0],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(160),
                  topRight: Radius.circular(160),
                ),
                child: Image.asset(
                  'assets/images/welcome_banner.png',
                  height: context.rs(204),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          _confetti(
            dx: -0.42,
            dy: 0.02,
            color: ChColors.accentN(400),
            angle: -0.4,
          ),
          _confetti(
            dx: 0.46,
            dy: 0.1,
            color: ChColors.accent2N(300),
            angle: 0.5,
          ),
          _confetti(
            dx: -0.3,
            dy: -0.12,
            color: const Color(0xffb9a6e0),
            angle: 0.3,
          ),
          _confetti(
            dx: 0.24,
            dy: -0.15,
            color: ChColors.accentN(300),
            angle: -0.3,
          ),
          Padding(
            padding: EdgeInsets.only(top: context.rs(8)),
            child: Container(
              width: context.rs(100),
              height: context.rs(100),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    ChColors.accent2N(100).withValues(alpha: 0.9),
                    ChColors.accent2N(100).withValues(alpha: 0),
                  ],
                ),
              ),
              child: Container(
                width: context.rs(56),
                height: context.rs(56),
                decoration: const BoxDecoration(
                  color: ChColors.accent2,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: context.rs(30),
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confetti({
    required double dx,
    required double dy,
    required Color color,
    required double angle,
  }) {
    return Align(
      alignment: Alignment(dx, dy),
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 10,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
