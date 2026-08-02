import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/ch_colors.dart';
import 'core/theme/ch_theme.dart';
import 'state/app_notifier.dart';
import 'state/app_state.dart';

class CommunityHubApp extends ConsumerStatefulWidget {
  const CommunityHubApp({super.key});

  @override
  ConsumerState<CommunityHubApp> createState() => _CommunityHubAppState();
}

class _CommunityHubAppState extends ConsumerState<CommunityHubApp> with WidgetsBindingObserver {
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
        home: const Scaffold(
          backgroundColor: ChColors.bg,
          body: Center(child: CircularProgressIndicator(color: ChColors.accent)),
        ),
      );
    }

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'CommunityHub',
      debugShowCheckedModeBanner: false,
      theme: ChTheme.light,
      routerConfig: router,
    );
  }
}
