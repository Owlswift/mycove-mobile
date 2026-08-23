import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/analytics/analytics_service.dart';
import 'core/push/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (_) {
    // No Firebase config dropped in yet (google-services.json /
    // GoogleService-Info.plist) — the rest of the app still works, push
    // notifications are just disabled until then.
  }

  final container = ProviderContainer();
  await container.read(pushServiceProvider).initialize();

  // Analytics init is fire-and-forget — a Mixpanel outage must never delay
  // or block app startup.
  unawaited(AnalyticsService.instance.initialize());
  AnalyticsService.instance.track('app_opened', {
    'platform': Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'other',
  });

  runApp(UncontrolledProviderScope(container: container, child: const CommunityHubApp()));
}