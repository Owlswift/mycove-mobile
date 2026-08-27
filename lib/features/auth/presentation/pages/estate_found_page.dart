import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_data_media.dart';
import '../../../../core/widgets/mc_square_icon_button.dart';
import '../../../../state/app_notifier.dart';

/// Shown after [EstateCodePage] resolves a valid code — confirms which
/// estate it matched before anything is written to EstateStorage (see
/// AppNotifier.submitEstateCode/confirmEstate), so a mistyped-but-valid
/// code that happens to hit a different estate doesn't get committed
/// silently.
class EstateFoundPage extends ConsumerWidget {
  const EstateFoundPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final imageHeight = MediaQuery.sizeOf(context).height * 0.20;

    return Scaffold(
      backgroundColor: McColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              McSquareIconButton(
                icon: Icons.arrow_back,
                onTap: notifier.reenterEstateCode,
              ),
              const _CelebrationBadge(),
              Center(
                child: Text(
                  'Estate found!',
                  style: McTextStyles.heading(
                    fontSize: 32,
                    color: McColors.accent2,
                  ),
                ),
              ),
              SizedBox(height: context.rs(8)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.rs(50)),
                child: Center(
                  child: Text(
                    'We found your estate. Please confirm the details below to continue.',
                    textAlign: TextAlign.center,
                    style: McTextStyles.body(
                      fontSize: 14,
                      color: McColors.text,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              SizedBox(height: context.rs(14)),
              Container(
                decoration: BoxDecoration(
                  color: McColors.surface,
                  borderRadius: BorderRadius.circular(McRadii.card),
                  boxShadow: McColors.cardShadow,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    s.pendingEstateImage != null
                        ? McDataMedia(
                            dataUrl: s.pendingEstateImage!,
                            height: imageHeight,
                          )
                        : Image.asset(
                            'assets/images/welcome_banner.png',
                            width: double.infinity,
                            height: imageHeight,
                            fit: BoxFit.cover,
                          ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.rs(16), vertical: context.rs(20)),
                      child: Row(
                        children: [
                          Container(
                            width: context.rs(60),
                            height: context.rs(60),
                            decoration: BoxDecoration(
                              color: McColors.accent2N(100),
                              borderRadius: BorderRadius.circular(McRadii.sm),
                            ),
                            child: Icon(
                              Icons.park_outlined,
                              size: context.rs(36),
                              color: McColors.accent2N(700),
                            ),
                          ),
                          SizedBox(width: context.rs(14)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.pendingEstateName ?? '',
                                  style: McTextStyles.heading(fontSize: 18),
                                ),
                                if ((s.pendingEstateAddress ?? '')
                                    .isNotEmpty) ...[
                                  SizedBox(height: context.rs(3)),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: context.rs(14),
                                        color: McColors.text,
                                      ),
                                      SizedBox(width: context.rs(4)),
                                      Expanded(
                                        child: Text(
                                          s.pendingEstateAddress!,
                                          style: McTextStyles.body(
                                            fontSize: 13,
                                            color: McColors.text,
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
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.rs(16)),
                      child: Divider(height: 1, color: McColors.divider),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.rs(16),
                        vertical: context.rs(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 25,
                            child: _StatItem(
                              icon: Icons.groups_outlined,
                              label: 'Residents',
                              value: s.pendingEstateResidentCount != null
                                  ? '${s.pendingEstateResidentCount}+'
                                  : '—',
                            ),
                          ),
                          SizedBox(width: context.rs(8)),
                          Container(
                            width: 1,
                            height: context.rs(34),
                            color: McColors.divider,
                          ),
                          SizedBox(width: context.rs(8)),
                          const Expanded(
                            flex: 35,
                            child: _StatItem(
                              icon: Icons.gpp_good_outlined,
                              label: 'Gated Community',
                              value: 'Secure',
                            ),
                          ),
                          SizedBox(width: context.rs(8)),
                          Container(
                            width: 1,
                            height: context.rs(34),
                            color: McColors.divider,
                          ),
                          SizedBox(width: context.rs(8)),
                          Expanded(
                            flex: 40,
                            child: _StatItem(
                              icon: Icons.account_balance_outlined,
                              label: s.pendingEstateManagedBy ?? '—',
                              value: 'Managed by',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.rs(18)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.rs(14),
                  vertical: context.rs(16),
                ),
                decoration: BoxDecoration(
                  color: McColors.surfaceSunken,
                  borderRadius: BorderRadius.circular(McRadii.button),
                  border: Border.all(color: McColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      width: context.rs(50),
                      height: context.rs(50),
                      decoration: BoxDecoration(
                        color: McColors.accent2N(100),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified_user_outlined,
                        size: context.rs(24),
                        color: McColors.accent2N(700),
                      ),
                    ),
                    SizedBox(width: context.rs(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Is this your estate?',
                            style: McTextStyles.body(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: McColors.text
                            ),
                          ),
                          SizedBox(height: context.rs(2)),
                          Padding(
                            padding: EdgeInsets.only(right: context.rs(50)),
                            child: Text(
                              'You will be able to login and access your estate community.',
                              textAlign: TextAlign.left,
                              style: McTextStyles.body(
                                fontSize: 12,
                                color: McColors.text,
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
              SizedBox(height: context.rs(24)),
              GestureDetector(
                onTap: notifier.confirmEstate,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: context.rs(15)),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: McColors.accent2,
                    borderRadius: BorderRadius.circular(McRadii.button),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Continue to Login',
                        style: McTextStyles.body(
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
              SizedBox(height: context.rs(20)),
              Center(
                child: GestureDetector(
                  onTap: notifier.reenterEstateCode,
                  child: Text(
                    'Enter a different code',
                    style: McTextStyles.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: McColors.accent2,
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

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: context.rs(24),
          height: context.rs(24),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: McColors.accent2N(100),
            borderRadius: BorderRadius.circular(McRadii.sm),
          ),
          child: Icon(icon, size: context.rs(16), color: McColors.accent2N(700)),
        ),
        SizedBox(width: context.rs(8)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: McTextStyles.body(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  color: McColors.text,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: McTextStyles.body(fontSize: 9, color: McColors.text),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The checkmark + scattered confetti above "Estate found!" — purely
/// decorative. Each piece gently bobs and spins in a continuous loop off a
/// single shared [AnimationController] (rather than one controller per
/// piece), with a `phase` offset per piece so they don't all move in
/// lockstep.
class _CelebrationBadge extends StatefulWidget {
  const _CelebrationBadge();

  @override
  State<_CelebrationBadge> createState() => _CelebrationBadgeState();
}

class _CelebrationBadgeState extends State<_CelebrationBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: context.rs(110),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Stack(
            children: [
              _confetti(
                t: t,
                phase: 0,
                dx: -0.22,
                dy: -0.75,
                color: McColors.accentN(400),
                angle: -0.5,
                spin: 1,
              ),
              _confetti(
                t: t,
                phase: 0.15,
                dx: 0.2,
                dy: -0.55,
                color: McColors.accent2N(300),
                angle: 0.6,
                spin: -1,
              ),
              _confetti(
                t: t,
                phase: 0.3,
                dx: -0.32,
                dy: 0.35,
                color: const Color(0xffb9a6e0),
                angle: 0.3,
                spin: 1,
              ),
              _confetti(
                t: t,
                phase: 0.45,
                dx: 0.28,
                dy: 0.45,
                color: McColors.accentN(300),
                angle: -0.4,
                spin: -1,
              ),
              _confetti(
                t: t,
                phase: 0.6,
                dx: 0.4,
                dy: -0.95,
                color: McColors.accent2N(400),
                angle: 0.2,
                spin: 1,
              ),
              _confetti(
                t: t,
                phase: 0.75,
                dx: -0.42,
                dy: -0.1,
                color: McColors.accent2N(200),
                angle: 0.8,
                spin: -1,
              ),
              _confetti(
                t: t,
                phase: 0.9,
                dx: 0.45,
                dy: 0.1,
                color: const Color(0xffb9a6e0),
                angle: -0.7,
                spin: 1,
              ),
              _confetti(
                t: t,
                phase: 0.5,
                dx: -0.05,
                dy: -0.9,
                color: McColors.accentN(500),
                angle: 0.4,
                spin: -1,
              ),
              Center(
                child: Container(
                  width: context.rs(72),
                  height: context.rs(72),
                  decoration: const BoxDecoration(
                    color: McColors.accent2,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: context.rs(38),
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// [dx]/[dy] are Alignment coordinates (-1 to 1, center-relative) rather
  /// than pixel offsets, so the scatter stays proportional to the badge's
  /// actual width instead of being clipped or bunched on narrower screens.
  /// [t] is the shared 0-1 loop position; [phase] staggers each piece so
  /// they bob and spin out of sync with each other.
  Widget _confetti({
    required double t,
    required double phase,
    required double dx,
    required double dy,
    required Color color,
    required double angle,
    required double spin,
  }) {
    final cycle = (t + phase) % 1.0;
    final bob = math.sin(cycle * 2 * math.pi) * 0.06;
    final rotation = angle + cycle * 2 * math.pi * spin;
    return Align(
      alignment: Alignment(dx, dy + bob),
      child: Transform.rotate(
        angle: rotation,
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
