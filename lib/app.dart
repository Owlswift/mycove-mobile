import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/ch_colors.dart';
import 'core/theme/ch_responsive.dart';
import 'core/theme/ch_theme.dart';
import 'features/auth/presentation/pages/biometric_unlock_page.dart';
import 'state/app_notifier.dart';
import 'state/app_state.dart';

/// Composes the device-width-based scale on top of the user's own OS
/// accessibility text-size setting (never replaces it) — every screen's
/// `Text` widgets pick this up automatically via `MediaQuery.textScaler`,
/// with no per-screen changes needed.
Widget _scaleText(BuildContext context, Widget? child) {
  final mediaQuery = MediaQuery.of(context);
  final deviceScale = ChResponsive.scaleOf(context);
  final composedScale = mediaQuery.textScaler.scale(1.0) * deviceScale;
  return MediaQuery(
    data: mediaQuery.copyWith(
      textScaler: TextScaler.linear(composedScale),
    ),
    child: child!,
  );
}

class CommunityHubApp extends ConsumerStatefulWidget {
  const CommunityHubApp({super.key});

  @override
  ConsumerState<CommunityHubApp> createState() => _CommunityHubAppState();
}

class _CommunityHubAppState extends ConsumerState<CommunityHubApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Covers both re-opening from the app switcher and opening via a tapped
    // push notification — either way the data on screen may be stale.
    if (state == AppLifecycleState.resumed) {
      ref.read(appStateProvider.notifier).refreshOnResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStage = ref.watch(appStateProvider.select((s) => s.authStage));

    if (authStage == AuthStage.bootstrapping) {
      return MaterialApp(
        title: 'CommunityHub',
        debugShowCheckedModeBanner: false,
        theme: ChTheme.light,
        builder: _scaleText,
        home: const Scaffold(
          backgroundColor: ChColors.bg,
          body: Center(
            child: CircularProgressIndicator(color: ChColors.accent),
          ),
        ),
      );
    }

    // Sits outside the router, same as `bootstrapping` above — a lock
    // screen over a silently-restored session doesn't need go_router's
    // back/forward or deep-link semantics any more than the splash does.
    if (authStage == AuthStage.locked) {
      return MaterialApp(
        title: 'CommunityHub',
        debugShowCheckedModeBanner: false,
        theme: ChTheme.light,
        builder: _scaleText,
        home: const BiometricUnlockPage(),
      );
    }

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'CommunityHub',
      debugShowCheckedModeBanner: false,
      builder: _scaleText,
      theme: ChTheme.light,
      routerConfig: router,
    );
  }
}
