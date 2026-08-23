import 'package:dio/dio.dart';
import '../core/network/api_client.dart';

/// One typed method per CommunityHub API endpoint. Returns decoded JSON;
/// callers parse into models. See ~/dev/communityhub-api for the server.
class CommunityHubApi {
  CommunityHubApi([Dio? dio]) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Map<String, dynamic> _map(Response r) => r.data as Map<String, dynamic>;
  List<dynamic> _list(Response r) => r.data as List<dynamic>;

  // ── Estate (pre-login) ───────────────────────────────────────────────
  Future<Map<String, dynamic>> lookupEstate(String code) async =>
      _map(await _dio.get('/estates/$code'));

  // ── Auth ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
    required String role,
    String? platform,
    String? deviceName,
  }) async => _map(
    await _dio.post(
      '/auth/login',
      data: {
        'phone': phone,
        'password': password,
        'role': role,
        'platform': ?platform,
        'deviceName': ?deviceName,
      },
    ),
  );

  Future<Map<String, dynamic>> forgotPassword(String phone) async =>
      _map(await _dio.post('/auth/forgot-password', data: {'phone': phone}));

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
  }) async => _map(
    await _dio.post('/auth/verify-otp', data: {'phone': phone, 'code': code}),
  );

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) => _dio.post(
    '/auth/reset-password',
    data: {'resetToken': resetToken, 'newPassword': newPassword},
  );

  Future<void> completeForceReset({
    required String newPassword,
    String? fullName,
    String? house,
    String? email,
    String? emergencyContactName,
    String? emergencyContactPhone,
    List<String>? vehiclePlates,
  }) => _dio.post(
    '/auth/complete-force-reset',
    data: {
      'newPassword': newPassword,
      'fullName': ?fullName,
      'house': ?house,
      'email': ?email,
      'emergencyContactName': ?emergencyContactName,
      'emergencyContactPhone': ?emergencyContactPhone,
      'vehiclePlates': ?vehiclePlates,
    },
  );

  Future<void> logoutRequest(String? refreshToken) =>
      _dio.post('/auth/logout', data: {'refreshToken': refreshToken});

  Future<Map<String, dynamic>> me() async => _map(await _dio.get('/users/me'));

  // ── Announcements ────────────────────────────────────────────────────
  Future<List<dynamic>> announcements() async =>
      _list(await _dio.get('/announcements'));
  Future<Map<String, dynamic>> announcement(String id) async =>
      _map(await _dio.get('/announcements/$id'));
  Future<void> markAnnouncementRead(String id) =>
      _dio.post('/announcements/$id/read');

  // ── Meetings ──────────────────────────────────────────────────────────
  Future<List<dynamic>> meetings() async => _list(await _dio.get('/meetings'));
  Future<Map<String, dynamic>> meeting(String id) async =>
      _map(await _dio.get('/meetings/$id'));
  Future<void> addToCalendar(String id) => _dio.post('/meetings/$id/calendar');

  // ── Dues & levies ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> dues() async => _map(await _dio.get('/dues'));
  Future<Map<String, dynamic>> levies() async => _map(await _dio.get('/levies'));
  Future<void> payLevy(String id) => _dio.post('/levies/$id/pay');

  Future<int> walletBalance() async =>
      (_map(await _dio.get('/wallet/balance'))['balance'] as num).toInt();

  Future<Map<String, dynamic>> voicePrepare({
    required String intent,
    int? amount,
    String? network,
    String? meterId,
  }) async => _map(
    await _dio.post(
      '/voice/prepare',
      data: {'intent': intent, 'amount': ?amount, 'network': ?network, 'meterId': ?meterId},
    ),
  );

  Future<void> setPin(String pin) => _dio.post('/auth/pin/set', data: {'pin': pin});

  Future<bool> verifyPin(String pin) async =>
      _map(await _dio.post('/auth/pin/verify', data: {'pin': pin}))['valid'] as bool;

  // ── Payments ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> initiatePayment({
    required int amount,
    required String purpose,
    String? levyId,
  }) async => _map(
    await _dio.post(
      '/payments/initiate',
      data: {'amount': amount, 'purpose': purpose, 'levyId': levyId},
    ),
  );

  Future<Map<String, dynamic>> verifyPayment(String reference) async =>
      _map(await _dio.get('/payments/verify/$reference'));

  Future<Map<String, dynamic>> receipt(String reference) async =>
      _map(await _dio.get('/payments/$reference/receipt'));

  // ── Visitor passes (resident) ────────────────────────────────────────
  Future<List<dynamic>> visitorPasses() async =>
      _list(await _dio.get('/visitor-passes'));

  Future<Map<String, dynamic>> createVisitorPass({
    required String name,
    required String phone,
    String? plate,
    int? validHours,
  }) async => _map(
    await _dio.post(
      '/visitor-passes',
      data: {
        'name': name,
        'phone': phone,
        'plate': plate,
        'validHours': ?validHours,
      },
    ),
  );

  Future<Map<String, dynamic>> visitorPass(String id) async =>
      _map(await _dio.get('/visitor-passes/$id'));

  Future<Map<String, dynamic>> revokeVisitorPass(String id) async =>
      _map(await _dio.patch('/visitor-passes/$id/revoke'));

  // ── Visitor passes (guard) ───────────────────────────────────────────
  Future<Map<String, dynamic>> guardVerify(String code) async =>
      _map(await _dio.post('/visitor-passes/verify', data: {'code': code}));

  Future<void> recordEntry(String visitorPassId) =>
      _dio.post('/visitor-passes/$visitorPassId/entry');
  Future<void> recordExit(String visitorPassId) =>
      _dio.post('/visitor-passes/$visitorPassId/exit');
  Future<List<dynamic>> accessLog() async =>
      _list(await _dio.get('/access-log'));
  Future<List<dynamic>> duesOwing() async =>
      _list(await _dio.get('/dues/owing'));

  // ── Projects ──────────────────────────────────────────────────────────
  Future<List<dynamic>> projects() async => _list(await _dio.get('/projects'));
  Future<Map<String, dynamic>> project(String id) async =>
      _map(await _dio.get('/projects/$id'));
  Future<void> pledge({required String projectId, required int amount}) =>
      _dio.post('/projects/$projectId/pledges', data: {'amount': amount});
  Future<List<dynamic>> myPledges() async =>
      _list(await _dio.get('/projects/my-pledges'));

  // ── Spotlights ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> currentSpotlight() async {
    final response = await _dio.get('/spotlights/current');
    return response.data as Map<String, dynamic>?;
  }

  // ── Polls ─────────────────────────────────────────────────────────────
  Future<List<dynamic>> polls() async => _list(await _dio.get('/polls'));
  Future<void> vote({required String pollId, required String optionId}) =>
      _dio.post('/polls/$pollId/vote', data: {'optionId': optionId});

  // ── Notifications ────────────────────────────────────────────────────
  Future<List<dynamic>> notifications() async =>
      _list(await _dio.get('/notifications'));
  Future<void> markAllNotificationsRead() =>
      _dio.post('/notifications/read-all');

  // ── Rules ─────────────────────────────────────────────────────────────
  Future<List<dynamic>> rules() async => _list(await _dio.get('/rules'));

  // ── Complaints ────────────────────────────────────────────────────────
  Future<List<dynamic>> complaints() async =>
      _list(await _dio.get('/complaints'));
  Future<Map<String, dynamic>> submitComplaint({
    required String category,
    required String description,
  }) async => _map(
    await _dio.post(
      '/complaints',
      data: {'category': category, 'description': description},
    ),
  );

  // ── Push notifications ───────────────────────────────────────────────
  Future<void> registerDeviceToken(String token, String platform) => _dio.post(
    '/push/register-token',
    data: {'token': token, 'platform': platform},
  );
  Future<void> unregisterDeviceToken(String token) =>
      _dio.post('/push/unregister-token', data: {'token': token});

  // ── Sessions (logged-in devices) ────────────────────────────────────
  Future<List<dynamic>> listSessions() async =>
      _list(await _dio.get('/auth/sessions'));
  Future<void> revokeSession(String id) => _dio.delete('/auth/sessions/$id');

  // ── Utilities (electricity + airtime) ───────────────────────────────
  //
  // These hit a real external payment provider (VTpass, possibly failing
  // over to BuyPower) rather than our own DB, so they routinely take much
  // longer than the app's default 10s timeout — a real electricity vend
  // was observed taking ~20s against VTpass's sandbox. A longer per-request
  // timeout here avoids the client giving up (and showing an error) on a
  // purchase that's still genuinely in flight server-side.
  static final _utilityRequestOptions = Options(
    sendTimeout: const Duration(seconds: 45),
    receiveTimeout: const Duration(seconds: 45),
  );

  Future<List<dynamic>> utilityMeters() async =>
      _list(await _dio.get('/utilities/meters'));

  Future<List<dynamic>> discos() async => _list(await _dio.get('/utilities/discos'));

  Future<Map<String, dynamic>> verifyMeter({
    required String discoCode,
    required String meterNumber,
    required String meterType,
  }) async => _map(
    await _dio.post(
      '/utilities/meters/verify',
      data: {
        'discoCode': discoCode,
        'meterNumber': meterNumber,
        'meterType': meterType,
      },
      options: _utilityRequestOptions,
    ),
  );

  Future<Map<String, dynamic>> saveMeter({
    required String discoCode,
    required String discoName,
    required String meterNumber,
    required String meterType,
  }) async => _map(
    await _dio.post(
      '/utilities/meters',
      data: {
        'discoCode': discoCode,
        'discoName': discoName,
        'meterNumber': meterNumber,
        'meterType': meterType,
      },
      options: _utilityRequestOptions,
    ),
  );

  Future<Map<String, dynamic>> buyElectricity({
    required String meterId,
    required String phone,
    required int amount,
  }) async => _map(
    await _dio.post(
      '/utilities/electricity/buy',
      data: {'meterId': meterId, 'phone': phone, 'amount': amount},
      options: _utilityRequestOptions,
    ),
  );

  Future<Map<String, dynamic>> buyAirtime({
    required String network,
    required String phone,
    required int amount,
  }) async => _map(
    await _dio.post(
      '/utilities/airtime/buy',
      data: {'network': network, 'phone': phone, 'amount': amount},
      options: _utilityRequestOptions,
    ),
  );

  Future<List<dynamic>> utilityPurchases() async =>
      _list(await _dio.get('/utilities/purchases'));

  // ── Household ────────────────────────────────────────────────────────
  Future<List<dynamic>> householdMembers() async =>
      _list(await _dio.get('/household/members'));
  Future<List<dynamic>> householdInvites() async =>
      _list(await _dio.get('/household/invites'));
  Future<Map<String, dynamic>> sendHouseholdInvite({
    required String fullName,
    required String phone,
  }) async => _map(
    await _dio.post('/household/invite', data: {'fullName': fullName, 'phone': phone}),
  );
  Future<void> cancelHouseholdInvite(String id) =>
      _dio.delete('/household/invite/$id');

  // ── Voice interaction logs ───────────────────────────────────────────
  /// Uploads a batch of on-device voice-turn logs (transcript + parser
  /// decision trail) for offline analysis of how residents actually use
  /// the assistant. Best-effort from the caller's side — failures are
  /// non-fatal and retried on a later attempt.
  Future<void> uploadVoiceLogs(List<Map<String, dynamic>> logs) =>
      _dio.post('/voice/logs', data: {'logs': logs});
}
