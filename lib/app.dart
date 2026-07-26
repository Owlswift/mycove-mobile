import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/ch_colors.dart';
import 'core/theme/ch_theme.dart';
import 'state/app_notifier.dart';
import 'state/app_state.dart';

class CommunityHubApp extends ConsumerWidget {
  const CommunityHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
