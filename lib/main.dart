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
  // Deferred to just after the first frame, not run inline here: this ends
  // in a native permission prompt, and presenting that prompt before
  // Flutter's own view has ever drawn a frame froze the whole screen at
  // the OS level until the resident answered it (a `Future`-based
  // unawaited() alone didn't help — the freeze is UIKit's, tied to
  // *when* the prompt fires, not to whether Dart is awaiting it).
  // Letting the real UI paint first avoids that blank/frozen launch.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(container.read(pushServiceProvider).initialize());
  });

  // Analytics init is fire-and-forget — a Mixpanel outage must never delay
  // or block app startup.
  unawaited(AnalyticsService.instance.initialize());
  AnalyticsService.instance.track('app_opened', {
    'platform': Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'other',
  });

  runApp(UncontrolledProviderScope(container: container, child: const MyCoveApp()));
}