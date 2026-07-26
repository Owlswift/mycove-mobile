import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
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
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Security Gate', style: ChTextStyles.body(fontSize: 13, color: ChColors.neutralN(600))),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
        type: BottomNavigationBarType.fixed,
        backgroundColor: ChColors.bg,
        selectedItemColor: ChColors.accent2,
        unselectedItemColor: ChColors.neutralN(600),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'Log'),
        ],
      ),
    );
  }
}
