import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/force_reset_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/new_password_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/guard/presentation/pages/guard_code_page.dart';
import '../../features/guard/presentation/pages/guard_log_page.dart';
import '../../features/guard/presentation/pages/guard_result_page.dart';
import '../../features/guard/presentation/pages/guard_scan_page.dart';
import '../../features/guard/presentation/widgets/guard_shell.dart';
import '../../features/resident/presentation/pages/announcement_detail_page.dart';
import '../../features/resident/presentation/pages/announcements_page.dart';
import '../../features/resident/presentation/pages/complaint_page.dart';
import '../../features/resident/presentation/pages/complaint_success_page.dart';
import '../../features/resident/presentation/pages/dashboard_page.dart';
import '../../features/resident/presentation/pages/dues_page.dart';
import '../../features/resident/presentation/pages/meeting_detail_page.dart';
import '../../features/resident/presentation/pages/meetings_page.dart';
import '../../features/resident/presentation/pages/notifications_page.dart';
import '../../features/resident/presentation/pages/payment_page.dart';
import '../../features/resident/presentation/pages/polls_page.dart';
import '../../features/resident/presentation/pages/profile_page.dart';
import '../../features/resident/presentation/pages/project_detail_page.dart';
import '../../features/resident/presentation/pages/projects_page.dart';
import '../../features/resident/presentation/pages/receipt_page.dart';
import '../../features/resident/presentation/pages/rules_page.dart';
import '../../features/resident/presentation/pages/visitor_create_page.dart';
import '../../features/resident/presentation/pages/visitor_detail_page.dart';
import '../../features/resident/presentation/pages/visitor_page.dart';
import '../../features/resident/presentation/widgets/resident_shell.dart';
import '../../state/app_notifier.dart';
import '../../state/app_state.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final _routerRefreshProvider = Provider<_RouterRefreshNotifier>((ref) {
  final notifier = _RouterRefreshNotifier();
  ref.listen<AppState>(appStateProvider, (previous, next) {
    if (previous?.authStage != next.authStage || previous?.role != next.role) {
      notifier.notify();
    }
  });
  ref.onDispose(notifier.dispose);
  return notifier;
});

const _authPaths = {
  AuthStage.login: '/login',
  AuthStage.forgot: '/forgot-password',
  AuthStage.otp: '/otp',
  AuthStage.newPassword: '/new-password',
  AuthStage.forceReset: '/force-reset',
};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_routerRefreshProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final s = ref.read(appStateProvider);
      final loc = state.matchedLocation;

      if (s.authStage != AuthStage.app) {
        final target = _authPaths[s.authStage]!;
        return loc == target ? null : target;
      }

      final roleRoot = s.role == Role.resident ? '/resident' : '/guard';
      if (!loc.startsWith(roleRoot)) return roleRoot;
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordPage()),
      GoRoute(path: '/otp', builder: (_, _) => const OtpPage()),
      GoRoute(path: '/new-password', builder: (_, _) => const NewPasswordPage()),
      GoRoute(path: '/force-reset', builder: (_, _) => const ForceResetPage()),

      // StatefulShellRoute.indexedStack keeps each tab's page (and its own
      // push stack) alive in an IndexedStack, so switching tabs is instant
      // and preserves scroll position instead of tearing down and rebuilding
      // the destination page on every tap (which is what made tab switches
      // feel rough with a plain ShellRoute).
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => ResidentShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/resident',
                builder: (_, _) => const DashboardPage(),
                routes: [
                  GoRoute(path: 'profile', builder: (_, _) => const ProfilePage()),
                  GoRoute(path: 'notifications', builder: (_, _) => const NotificationsPage()),
                  GoRoute(path: 'polls', builder: (_, _) => const PollsPage()),
                  GoRoute(path: 'rules', builder: (_, _) => const RulesPage()),
                  GoRoute(
                    path: 'complaint',
                    builder: (_, _) => const ComplaintPage(),
                    routes: [GoRoute(path: 'success', builder: (_, _) => const ComplaintSuccessPage())],
                  ),
                  GoRoute(
                    path: 'projects',
                    builder: (_, _) => const ProjectsPage(),
                    routes: [
                      GoRoute(path: ':id', builder: (_, s) => ProjectDetailPage(id: s.pathParameters['id']!)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/resident/announcements',
                builder: (_, _) => const AnnouncementsPage(),
                routes: [
                  GoRoute(path: ':id', builder: (_, s) => AnnouncementDetailPage(id: s.pathParameters['id']!)),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/resident/meetings',
                builder: (_, _) => const MeetingsPage(),
                routes: [
                  GoRoute(path: ':id', builder: (_, s) => MeetingDetailPage(id: s.pathParameters['id']!)),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/resident/dues', builder: (_, _) => const DuesPage()),
              GoRoute(path: '/resident/payment', builder: (_, _) => const PaymentPage()),
              GoRoute(path: '/resident/receipt', builder: (_, _) => const ReceiptPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/resident/visitor',
                builder: (_, _) => const VisitorPage(),
                routes: [
                  GoRoute(path: 'new', builder: (_, _) => const VisitorCreatePage()),
                  GoRoute(path: ':id', builder: (_, s) => VisitorDetailPage(id: s.pathParameters['id']!)),
                ],
              ),
            ],
          ),
        ],
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => GuardShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guard',
                builder: (_, _) => const GuardScanPage(),
                routes: [
                  GoRoute(path: 'code', builder: (_, _) => const GuardCodePage()),
                  GoRoute(path: 'result', builder: (_, _) => const GuardResultPage()),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/guard/log', builder: (_, _) => const GuardLogPage())],
          ),
        ],
      ),
    ],
  );
});
