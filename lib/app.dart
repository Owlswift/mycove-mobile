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

class MyCoveApp extends ConsumerStatefulWidget {
  const MyCoveApp({super.key});

  @override
  ConsumerState<MyCoveApp> createState() => _MyCoveAppState();
}

class _MyCoveAppState extends ConsumerState<MyCoveApp>
    with WidgetsBindingObserver {
  // `inactive` fires for plenty of things that aren't "the resident left
  // the app" — pulling down Control Center, a phone call banner, a share
  // sheet, or our own Face ID/Touch ID prompt all dip through `inactive`
  // without the app ever truly leaving the foreground. Only `paused` means
  // the app actually stopped being visible (home button, app switcher, or
  // the screen locking) — tracking the last state lets `resumed` be
  // treated as "really coming back" only when it follows a genuine pause,
  // which is what should gate both the data refresh and the biometric lock.
  AppLifecycleState? _lastLifecycleState;

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
    final wasPaused = _lastLifecycleState == AppLifecycleState.paused ||
        _lastLifecycleState == AppLifecycleState.hidden;
    _lastLifecycleState = state;
    if (state == AppLifecycleState.resumed && wasPaused) {
      ref.read(appStateProvider.notifier).refreshOnResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStage = ref.watch(appStateProvider.select((s) => s.authStage));

    if (authStage == AuthStage.bootstrapping) {
      return MaterialApp(
        title: 'MyCove',
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
        title: 'MyCove',
        debugShowCheckedModeBanner: false,
        theme: ChTheme.light,
        builder: _scaleText,
        home: const BiometricUnlockPage(),
      );
    }

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'MyCove',
      debugShowCheckedModeBanner: false,
      builder: _scaleText,
      theme: ChTheme.light,
      routerConfig: router,
    );
  }
}
