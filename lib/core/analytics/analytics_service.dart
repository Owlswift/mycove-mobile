import 'package:mixpanel_flutter/mixpanel_flutter.dart';

/// Mixpanel project token — a client-side identifier by design (safe to
/// embed; it identifies the *project*, not a secret). Override at build
/// time with --dart-define=MIXPANEL_TOKEN=<token> to point at another
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
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  Mixpanel? _mixpanel;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _mixpanel = await Mixpanel.init(kMixpanelToken, trackAutomaticEvents: true);
      _initialized = true;
    } catch (_) {
      // Offline / plugin unavailable — stay a silent no-op.
    }
  }

  /// Attaches identity + estate/role super properties after login or on
  /// session restore.
  void identify({
    required String userId,
    required String role,
    required String platform,
    String? estateId,
    String? estateName,
  }) {
    final mp = _mixpanel;
    if (mp == null) return;
    try {
      mp.identify(userId);
      final superProps = <String, dynamic>{
        'role': role,
        'platform': platform,
        if (estateId != null) 'estate_id': estateId,
        if (estateName != null) 'estate_name': estateName,
      };
      mp.registerSuperProperties(superProps);
      mp.getPeople().set(userId, superProps);
    } catch (_) {}
  }

  /// Clears identity on logout so the next user isn't attributed to the
  /// previous one's funnel.
  void reset() {
    try {
      _mixpanel?.reset();
    } catch (_) {}
  }

  void track(String event, [Map<String, dynamic>? props]) {
    try {
      _mixpanel?.track(event, properties: props);
    } catch (_) {}
  }
}

/// Redacts long digit runs (meter numbers, phone numbers) and truncates —
/// transcripts carry analytical signal via intent/params, never raw PII.
String redactTranscript(String transcript) {
  var t = transcript.replaceAll(RegExp(r'\d{7,}'), '<redacted>');
  if (t.length > 120) t = '${t.substring(0, 120)}…';
  return t;
}