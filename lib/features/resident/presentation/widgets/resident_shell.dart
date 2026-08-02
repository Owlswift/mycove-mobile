import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';

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
class ResidentShell extends StatelessWidget {
  const ResidentShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: navigationShell),
      // Must be the real BottomNavigationBar widget: a custom Row of
      // Expanded+InkWell here collapses this Scaffold's body to zero height
      // (Scaffold's body renders blank, nav bar pinned under the status bar)
      // whenever this shell sits inside a ShellRoute's nested Navigator.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
        type: BottomNavigationBarType.fixed,
        backgroundColor: ChColors.bg,
        selectedItemColor: ChColors.accent2,
        unselectedItemColor: ChColors.neutralN(600),
        items: [
          for (var i = 0; i < _tabLabels.length; i++)
            BottomNavigationBarItem(icon: Icon(_tabIcons[i]), label: _tabLabels[i]),
        ],
      ),
    );
  }
}
