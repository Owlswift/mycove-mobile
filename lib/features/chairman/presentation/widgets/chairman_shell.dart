import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../state/app_notifier.dart';

/// Frame for the estate chairman's oversight screens — same layout as the
/// guard shell (name header + bottom tabs), since it's the other
/// non-resident experience.
class ChairmanShell extends ConsumerWidget {
  const ChairmanShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(22, context.rs(6), 22, context.rs(14)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.estateName != null ? '${s.estateName} · Chairman' : 'Estate Chairman',
                        style: McTextStyles.body(fontSize: 13, color: McColors.bodyText),
                      ),
                      Text(s.currentUser?.fullName ?? '', style: McTextStyles.heading(fontSize: 19)),
                    ],
                  ),
                  GestureDetector(
                    onTap: notifier.logout,
                    child: Text(
                      'Log Out',
                      style: McTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600, color: McColors.danger),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: navigationShell),
          ],
        ),
      ),
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
          unselectedItemColor: McColors.neutralN(500),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
            BottomNavigationBarItem(icon: Icon(Icons.report_problem_outlined), label: 'Complaints'),
            BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), label: 'Gate'),
            BottomNavigationBarItem(icon: Icon(Icons.apartment_outlined), label: 'Projects'),
            BottomNavigationBarItem(icon: Icon(Icons.campaign_outlined), label: 'Notices'),
          ],
        ),
      ),
    );
  }
}
