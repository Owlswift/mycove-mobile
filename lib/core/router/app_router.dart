import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/estate_code_page.dart';
import '../../features/auth/presentation/pages/estate_found_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/force_reset_page.dart';
import '../../features/auth/presentation/pages/onboarding_complete_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/new_password_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/password_reset_success_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/guard/presentation/pages/guard_code_page.dart';
import '../../features/guard/presentation/pages/guard_dues_page.dart';
import '../../features/guard/presentation/pages/guard_log_page.dart';
import '../../features/guard/presentation/pages/guard_result_page.dart';
import '../../features/guard/presentation/pages/guard_scan_page.dart';
import '../../features/guard/presentation/widgets/guard_shell.dart';
import '../../features/resident/presentation/pages/announcement_detail_page.dart';
import '../../features/resident/presentation/pages/announcements_page.dart';
import '../../features/resident/presentation/pages/buy_airtime_page.dart';
import '../../features/resident/presentation/pages/complaint_log_page.dart';
import '../../features/resident/presentation/pages/complaint_page.dart';
import '../../features/resident/presentation/pages/complaint_success_page.dart';
import '../../features/resident/presentation/pages/dashboard_page.dart';
import '../../features/resident/presentation/pages/dues_page.dart';
import '../../features/resident/presentation/pages/electricity_confirm_meter_page.dart';
import '../../features/resident/presentation/pages/electricity_enter_amount_page.dart';
import '../../features/resident/presentation/pages/electricity_enter_meter_page.dart';
import '../../features/resident/presentation/pages/electricity_payment_page.dart';
import '../../features/resident/presentation/pages/electricity_select_meter_page.dart';
import '../../features/resident/presentation/pages/electricity_select_provider_page.dart';
import '../../features/resident/presentation/pages/household_page.dart';
import '../../features/resident/presentation/pages/invite_resident_page.dart';
import '../../features/resident/presentation/pages/meeting_detail_page.dart';
import '../../features/resident/presentation/pages/meetings_page.dart';
import '../../features/resident/presentation/pages/notifications_page.dart';
import '../../features/resident/presentation/pages/payment_page.dart';
import '../../features/resident/presentation/pages/polls_page.dart';
import '../../features/resident/presentation/pages/manage_devices_page.dart';
import '../../features/resident/presentation/pages/profile_page.dart';
import '../../features/resident/presentation/pages/project_detail_page.dart';
import '../../features/resident/presentation/pages/projects_page.dart';
import '../../features/resident/presentation/pages/receipt_page.dart';
import '../../features/resident/presentation/pages/rules_page.dart';
import '../../features/resident/presentation/pages/sos_page.dart';
import '../../features/resident/presentation/pages/utility_history_page.dart';
import '../../features/resident/presentation/pages/utility_purchase_success_page.dart';
import '../../features/resident/presentation/pages/utility_receipt_page.dart';
import '../../features/resident/presentation/pages/visitor_create_page.dart';
import '../../features/resident/presentation/pages/set_pin_page.dart';
import '../../features/resident/presentation/pages/visitor_detail_page.dart';
import '../../features/resident/presentation/pages/visitor_page.dart';
import '../../features/resident/presentation/pages/voice_settings_page.dart';
import '../../features/resident/presentation/pages/wallet_page.dart';
import '../../features/resident/presentation/pages/domestic_log_page.dart';
import '../../features/resident/presentation/pages/domestic_staff_flow_page.dart';
import '../../features/resident/presentation/pages/domestic_staff_page.dart';
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
  AuthStage.welcome: '/welcome',
  AuthStage.estateCode: '/estate-code',
  AuthStage.estateFound: '/estate-found',
  AuthStage.login: '/login',
  AuthStage.forgot: '/forgot-password',
  AuthStage.otp: '/otp',
  AuthStage.newPassword: '/new-password',
  AuthStage.resetSuccess: '/reset-success',
  AuthStage.forceReset: '/force-reset',
  AuthStage.onboardingComplete: '/onboarding-complete',
};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_routerRefreshProvider);

  return GoRouter(
    initialLocation: '/welcome',
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
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomePage()),
      GoRoute(path: '/estate-code', builder: (_, _) => const EstateCodePage()),
      GoRoute(
        path: '/estate-found',
        builder: (_, _) => const EstateFoundPage(),
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordPage(),
      ),
      GoRoute(path: '/otp', builder: (_, _) => const OtpPage()),
      GoRoute(
        path: '/new-password',
        builder: (_, _) => const NewPasswordPage(),
      ),
      GoRoute(
        path: '/reset-success',
        builder: (_, _) => const PasswordResetSuccessPage(),
      ),
      GoRoute(path: '/force-reset', builder: (_, _) => const ForceResetPage()),
      GoRoute(
        path: '/onboarding-complete',
        builder: (_, _) => const OnboardingCompletePage(),
      ),

      // StatefulShellRoute.indexedStack keeps each tab's page (and its own
      // push stack) alive in an IndexedStack, so switching tabs is instant
      // and preserves scroll position instead of tearing down and rebuilding
      // the destination page on every tap (which is what made tab switches
      // feel rough with a plain ShellRoute).
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ResidentShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/resident',
                builder: (_, _) => const DashboardPage(),
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (_, _) => const ProfilePage(),
                    routes: [
                      GoRoute(
                        path: 'devices',
                        builder: (_, _) => const ManageDevicesPage(),
                      ),
                      GoRoute(
                        path: 'pin',
                        builder: (_, _) => const SetPinPage(),
                      ),
                      GoRoute(
                        path: 'voice',
                        builder: (_, _) => const VoiceSettingsPage(),
                      ),
                      GoRoute(
                        path: 'household',
                        builder: (_, _) => const HouseholdPage(),
                        routes: [
                          GoRoute(
                            path: 'invite',
                            builder: (_, _) => const InviteResidentPage(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (_, _) => const NotificationsPage(),
                  ),
                  GoRoute(path: 'polls', builder: (_, _) => const PollsPage()),
                  GoRoute(path: 'rules', builder: (_, _) => const RulesPage()),
                  GoRoute(path: 'sos', builder: (_, _) => const SosPage()),
                  GoRoute(path: 'wallet', builder: (_, _) => const WalletPage()),
                  GoRoute(
                    path: 'domestic-staff',
                    builder: (_, _) => const DomesticStaffPage(),
                    routes: [
                      GoRoute(
                        path: 'log',
                        builder: (_, state) {
                          final extra = state.extra as Map<String, dynamic>?;
                          return DomesticLogPage(
                            staffId: extra?['id'] as String?,
                            staffName: extra?['name'] as String?,
                          );
                        },
                      ),
                      GoRoute(
                        path: 'add',
                        builder: (_, state) =>
                            DomesticStaffFlowPage(existing: state.extra as Map<String, dynamic>?),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'complaint',
                    builder: (_, _) => const ComplaintPage(),
                    routes: [
                      GoRoute(
                        path: 'success',
                        builder: (_, _) => const ComplaintSuccessPage(),
                      ),
                      GoRoute(
                        path: 'log',
                        builder: (_, _) => const ComplaintLogPage(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'meetings',
                    builder: (_, _) => const MeetingsPage(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (_, s) =>
                            MeetingDetailPage(id: s.pathParameters['id']!),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'airtime',
                    builder: (_, _) => const BuyAirtimePage(),
                    routes: [
                      GoRoute(
                        path: 'success',
                        builder: (_, _) => const UtilityPurchaseSuccessPage(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'electricity',
                    builder: (_, _) => const ElectricitySelectProviderPage(),
                    routes: [
                      GoRoute(
                        path: 'meter',
                        builder: (_, _) => const ElectricityEnterMeterPage(),
                      ),
                      GoRoute(
                        path: 'select-meter',
                        builder: (_, _) => const ElectricitySelectMeterPage(),
                      ),
                      GoRoute(
                        path: 'confirm',
                        builder: (_, _) => const ElectricityConfirmMeterPage(),
                      ),
                      GoRoute(
                        path: 'amount',
                        builder: (_, _) => const ElectricityEnterAmountPage(),
                      ),
                      GoRoute(
                        path: 'payment',
                        builder: (_, _) => const ElectricityPaymentPage(),
                      ),
                      GoRoute(
                        path: 'success',
                        builder: (_, _) => const UtilityPurchaseSuccessPage(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'utility-history',
                    builder: (_, s) => UtilityHistoryPage(type: s.extra as String?),
                    routes: [
                      GoRoute(
                        path: ':id/receipt',
                        builder: (_, s) =>
                            UtilityReceiptPage(purchaseId: s.pathParameters['id']!),
                      ),
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
                  GoRoute(
                    path: ':id',
                    builder: (_, s) =>
                        AnnouncementDetailPage(id: s.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/resident/projects',
                builder: (_, _) => const ProjectsPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, s) =>
                        ProjectDetailPage(id: s.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/resident/dues',
                builder: (_, _) => const DuesPage(),
              ),
              GoRoute(
                path: '/resident/payment',
                builder: (_, _) => const PaymentPage(),
              ),
              GoRoute(
                path: '/resident/receipt',
                builder: (_, _) => const ReceiptPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/resident/visitor',
                builder: (_, _) => const VisitorPage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, _) => const VisitorCreatePage(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, s) =>
                        VisitorDetailPage(id: s.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            GuardShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guard',
                builder: (_, _) => const GuardScanPage(),
                routes: [
                  GoRoute(
                    path: 'code',
                    builder: (_, _) => const GuardCodePage(),
                  ),
                  GoRoute(
                    path: 'result',
                    builder: (_, _) => const GuardResultPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guard/log',
                builder: (_, _) => const GuardLogPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guard/dues',
                builder: (_, _) => const GuardDuesPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
