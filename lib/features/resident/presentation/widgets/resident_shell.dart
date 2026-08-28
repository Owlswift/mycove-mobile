import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';
import 'authorization_sheet.dart';
import 'voice_overlay.dart';

const _tabLabels = ['Home', 'Notices', 'Projects', 'Dues', 'Pass'];
const _tabIcons = [
  Icons.home_rounded,
  Icons.campaign_rounded,
  Icons.home_work_rounded,
  Icons.receipt_long_rounded,
  Icons.badge_rounded,
];

/// Persistent bottom nav shell for the resident app — the mockup keeps this
/// bar visible on every resident screen, not just the 5 root tabs.
///
/// Backed by StatefulShellRoute.indexedStack: each tab's page tree (and its
/// own push stack) stays alive in an IndexedStack, so switching tabs is
/// instant instead of tearing down and rebuilding the destination page.
class ResidentShell extends ConsumerWidget {
  const ResidentShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(appStateProvider.notifier);

    // Single bridge from voice's pure-state pipeline to real navigation and
    // authorization — see AppNotifier's class-level voice comment. Both
    // fields can be set together (voice already knows enough to jump
    // straight to payment), so both branches are checked on every change.
    ref.listen<AppState>(appStateProvider, (prev, next) async {
      if (next.voiceNavigationTarget != null &&
          next.voiceNavigationTarget != prev?.voiceNavigationTarget) {
        final target = next.voiceNavigationTarget!;
        notifier.clearVoiceNavigationTarget();
        context.go(target);
      }
      if (next.pendingAuthorizationFor != null &&
          next.pendingAuthorizationFor != prev?.pendingAuthorizationFor) {
        final kind = next.pendingAuthorizationFor!;
        notifier.clearPendingAuthorization();
        final authorized = await showAuthorizationSheet(context, ref);
        if (!context.mounted) return;
        if (!authorized) return;
        if (kind == 'dues' || kind == 'levy') {
          // PaymentPage already reactively re-renders off `paymentStep` —
          // no navigation needed here, unlike the utility purchases below.
          await notifier.confirmPayment();
          return;
        }
        final ok = kind == 'electricity' ? await notifier.buyElectricity() : await notifier.buyAirtime();
        if (ok && context.mounted) context.go('/resident/$kind/success');
      }
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            navigationShell,
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: const VoiceOverlay(),
            ),
          ],
        ),
      ),
      // Must be the real BottomNavigationBar widget: a custom Row of
      // Expanded+InkWell here collapses this Scaffold's body to zero height
      // (Scaffold's body renders blank, nav bar pinned under the status bar)
      // whenever this shell sits inside a ShellRoute's nested Navigator.
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: McColors.surface,
          border: Border(top: BorderSide(color: McColors.divider)),
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
          type: BottomNavigationBarType.fixed,
          backgroundColor: McColors.surface,
          elevation: 0,
          selectedItemColor: McColors.accent2,
          unselectedItemColor: McColors.bodyText,
          selectedLabelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
          items: [
            for (var i = 0; i < _tabLabels.length; i++)
              BottomNavigationBarItem(icon: Icon(_tabIcons[i], size: context.rs(22)), label: _tabLabels[i]),
          ],
        ),
      ),
    );
  }
}
