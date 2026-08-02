import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_router.dart';

const _channel = AndroidNotificationChannel(
  'high_importance_channel',
  'Important notifications',
  description: 'CommunityHub alerts for visitor activity and payments.',
  importance: Importance.high,
);

/// Runs in a separate isolate when a push arrives while the app is fully
/// backgrounded/terminated — Firebase needs its own init here too.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Already initialized, or Firebase isn't configured — nothing to do.
  }
}

/// Wraps firebase_messaging + flutter_local_notifications: requests
/// permission, surfaces the FCM token for backend registration, shows a
/// local notification when a push arrives while the app is foregrounded
/// (FCM notifications are otherwise silent in that case), and navigates to
/// a relevant screen on tap. Every method here is best-effort — if Firebase
/// isn't configured yet (no google-services.json / GoogleService-Info.plist
/// dropped in), everything no-ops instead of crashing the app.
class PushService {
  PushService(this._ref);

  final Ref _ref;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get _supported => Platform.isAndroid || Platform.isIOS;

  Future<void> initialize() async {
    if (!_supported || _initialized) return;
    _initialized = true;

    try {
      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            // firebase_messaging's requestPermission() below already asks
            // for the native permission — asking again here would double-prompt.
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final type = response.payload;
          if (type != null) _navigateForType(type);
        },
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      await FirebaseMessaging.instance.requestPermission();

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) _handleMessageTap(initialMessage);
    } catch (e, st) {
      // Firebase isn't configured yet — push notifications stay disabled,
      // the rest of the app is unaffected.
      debugPrint('PushService.initialize failed: $e\n$st');
    }
  }

  /// The current FCM registration token, for the backend to send pushes to.
  /// Returns null on unsupported platforms or if Firebase isn't configured.
  Future<String?> getToken() async {
    if (!_supported) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    debugPrint('PushService: onMessage fired, notification=${notification?.title}');
    if (notification == null) return;
    try {
      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(_channel.id, _channel.name, importance: Importance.high, priority: Priority.high),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data['type'] as String?,
      );
    } catch (e, st) {
      debugPrint('PushService: showing foreground notification failed: $e\n$st');
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    final type = message.data['type'] as String?;
    if (type != null) _navigateForType(type);
  }

  void _navigateForType(String type) {
    final router = _ref.read(routerProvider);
    switch (type) {
      case 'visitor':
        router.go('/resident/visitor');
      case 'payment':
        router.go('/resident/dues');
      default:
        router.go('/resident/notifications');
    }
  }
}

final pushServiceProvider = Provider<PushService>((ref) => PushService(ref));
