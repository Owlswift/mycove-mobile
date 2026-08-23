import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Mixpanel project token — a client-side identifier by design (safe to
/// embed; it identifies the *project*, not a secret). Override at build
/// time with --dart-define=MIXPANEL_TOKEN=`<token>` to point at another
/// project (e.g. a staging one).
const kMixpanelToken = String.fromEnvironment(
  'MIXPANEL_TOKEN',
  defaultValue: '2a61ab19563d6f61331f2d469bf8d24a',
);

/// The single analytics choke point for the mobile app. Every event goes
/// through [track]; identity through [identify]/[reset].
///
/// Guarantees:
/// - Never throws into caller code — analytics must not break a flow
///   (payment, voice, login) that matters more than the datapoint.
/// - No-ops entirely until [initialize] succeeds, so dev/demo builds
///   without network still run clean.
/// - Global properties (user_id, estate_id, user_role, session_id,
///   platform, app_version, os_version, device_model, environment) are
///   auto-attached to every event via Mixpanel super-properties — callers
///   only pass business-specific properties.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  Mixpanel? _mixpanel;
  bool _initialized = false;
  final String _sessionId = _generateSessionId();

  /// Global properties auto-attached to every tracked event.
  /// Populated by [initialize] (device/app info) and [identify] (user info).
  final Map<String, dynamic> _globalProps = {};

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _mixpanel = await Mixpanel.init(kMixpanelToken, trackAutomaticEvents: true);
      _initialized = true;
      await _collectDeviceProps();
      _registerGlobalProps();
    } catch (_) {
      // Offline / plugin unavailable — stay a silent no-op.
    }
  }

  /// Collects device and app properties once at startup.
  Future<void> _collectDeviceProps() async {
    final platform = Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'other';
    _globalProps['platform'] = platform;
    _globalProps['session_id'] = _sessionId;
    _globalProps['environment'] = const String.fromEnvironment(
      'FLUTTER_ENV',
      defaultValue: 'production',
    );

    try {
      final info = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final iosInfo = await info.iosInfo;
        _globalProps['device_model'] = iosInfo.model;
        _globalProps['os_version'] = iosInfo.systemVersion;
      } else if (Platform.isAndroid) {
        final androidInfo = await info.androidInfo;
        _globalProps['device_model'] = androidInfo.model;
        _globalProps['os_version'] = androidInfo.version.release;
      }
    } catch (_) {
      // Device info unavailable — skip silently.
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _globalProps['app_version'] = packageInfo.version;
    } catch (_) {
      // Package info unavailable — skip silently.
    }
  }

  /// Registers global properties as Mixpanel super-properties so every
  /// subsequent track() call inherits them automatically.
  void _registerGlobalProps() {
    final mp = _mixpanel;
    if (mp == null) return;
    try {
      mp.registerSuperProperties(Map<String, dynamic>.from(_globalProps));
    } catch (_) {}
  }

  /// Attaches identity + user-level global properties after login or on
  /// session restore. Also writes the person's Mixpanel people profile
  /// ([fullName], [phone], [estateName]) so every user has a people object
  /// carrying who they are and which estate they belong to.
  void identify({
    required String userId,
    required String role,
    required String fullName,
    required String phone,
    String? estateId,
    String? estateName,
  }) {
    final mp = _mixpanel;
    if (mp == null) return;
    try {
      mp.identify(userId);
      _globalProps['user_id'] = userId;
      _globalProps['user_role'] = role;
      _globalProps['full_name'] = fullName;
      _globalProps['phone'] = phone;
      if (estateId != null) _globalProps['estate_id'] = estateId;
      if (estateName != null) _globalProps['estate_name'] = estateName;
      mp.registerSuperProperties(Map<String, dynamic>.from(_globalProps));
      mp.getPeople().set(userId, {
        'full_name': fullName,
        'phone': phone,
        'estate_id': estateId,
        'estate_name': estateName,
        ...Map<String, dynamic>.from(_globalProps),
      });
    } catch (_) {}
  }

  /// Clears identity on logout so the next user isn't attributed to the
  /// previous one's funnel.
  void reset() {
    try {
      _mixpanel?.reset();
    } catch (_) {}
    // Clear user-level props but keep device/app props for the next session.
    _globalProps.remove('user_id');
    _globalProps.remove('user_role');
    _globalProps.remove('estate_id');
    _globalProps.remove('estate_name');
    _globalProps.remove('full_name');
    _globalProps.remove('phone');
  }

  /// Tracks an event. Global properties are auto-attached via super-properties;
  /// [props] should contain only business-specific properties.
  void track(String event, [Map<String, dynamic>? props]) {
    try {
      _mixpanel?.track(event, properties: props);
    } catch (_) {}
  }
}

/// Generates a random session ID for the current app session.
String _generateSessionId() {
  final rand = Random.secure();
  final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Redacts long digit runs (meter numbers, phone numbers) and truncates —
/// transcripts carry analytical signal via intent/params, never raw PII.
String redactTranscript(String transcript) {
  var t = transcript.replaceAll(RegExp(r'\d{7,}'), '<redacted>');
  if (t.length > 120) t = '${t.substring(0, 120)}…';
  return t;
}