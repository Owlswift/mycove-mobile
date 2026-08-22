import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../state/app_notifier.dart';

class GuardShell extends ConsumerWidget {
  const GuardShell({super.key, required this.navigationShell});

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
                      Text('Security Gate', style: ChTextStyles.body(fontSize: 13, color: ChColors.bodyText)),
                      Text(s.currentUser?.fullName ?? '', style: ChTextStyles.heading(fontSize: 19)),
                    ],
                  ),
                  GestureDetector(
                    onTap: notifier.logout,
                    child: Text(
                      'Log Out',
                      style: ChTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600, color: ChColors.danger),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: navigationShell),
          ],
        ),
      ),
      // See ResidentShell: must be the real BottomNavigationBar widget, not a
      // custom Row of gesture widgets, or this shell's body renders blank.
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: ChColors.surface,
          border: Border(top: BorderSide(color: ChColors.divider)),
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (i) {
            // Clear any stale verification result when switching tabs — otherwise
            // the preserved navigation stack can land back on /guard/result with
            // the previous scan's outcome still in state (e.g. "Pass Already Used").
            if (i != navigationShell.currentIndex) {
              notifier.resetGuardResult();
            }
            navigationShell.goBranch(i, initialLocation: true);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: ChColors.surface,
          elevation: 0,
          selectedItemColor: ChColors.accent2,
          unselectedItemColor: ChColors.neutralN(500),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scan'),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'Log'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Dues'),
          ],
        ),
      ),
    );
  }
}
