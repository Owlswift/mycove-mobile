import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/analytics/analytics_service.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/network/biometric_storage.dart';
import '../core/network/estate_storage.dart';
import '../core/network/jwt_decode.dart';
import '../core/network/token_storage.dart';
import '../core/network/voice_settings_storage.dart';
import '../core/push/push_service.dart';
import '../core/storage/app_state_cache.dart';
import '../core/voice/voice_intent_parser.dart';
import '../core/voice/voice_log_storage.dart';
import '../data/my_cove_api.dart';
import '../data/models/access_log_entry.dart';
import '../data/models/owing_resident.dart';
import '../data/models/announcement.dart';
import '../data/models/complaint_item.dart';
import '../data/models/dues_entry.dart';
import '../data/models/household_invite.dart';
import '../data/models/household_member.dart';
import '../data/models/levy.dart';
import '../data/models/wallet_transaction.dart';
import '../data/models/meeting.dart';
import '../data/models/my_pledge.dart';
import '../data/models/notification_item.dart';
import '../data/models/person.dart';
import '../data/models/poll.dart';
import '../data/models/project.dart';
import '../data/models/rules_section.dart';
import '../data/models/session_info.dart';
import '../data/models/spotlight.dart';
import '../data/models/tts_voice_option.dart';
import '../data/models/utility_meter.dart';
import '../data/models/utility_purchase.dart';
import '../data/models/visitor_pass.dart';
import 'app_state.dart';

/// Demo-only: the guard's "Simulate Scan" button has no real camera. The API
/// correctly doesn't expose a "list all passes" endpoint to guards (that'd
/// be a privacy hole), so this cycles through the two seeded demo codes
/// instead — preserves the "sometimes valid, sometimes expired" demo without
/// an endpoint that shouldn't exist.
const demoScanCodes = ['482913', '116607'];

Role _roleFromApi(String value) =>
    value == 'GUARD' ? Role.guard : Role.resident;
String _roleToApi(Role role) => role == Role.guard ? 'GUARD' : 'RESIDENT';
String _digitsOnly(String v) => v.replaceAll(RegExp(r'\D'), '');

enum _VoiceFlow { none, electricity, airtime }

class AppNotifier extends StateNotifier<AppState> {
  AppNotifier(
    this._api,
    this._tokenStorage,
    this._estateStorage,
    this._ref, [
    BiometricStorage? biometricStorage,
  ]) : _biometricStorage = biometricStorage ?? const BiometricStorage(),
       super(AppState()) {
    ApiClient.instance.onAccountDeactivated = _handleAccountDeactivated;
    // Speaks the voice assistant's response out loud whenever it changes —
    // hooked here rather than at each of the many call sites that set
    // voiceResponse, since AppNotifier already sees every state change.
    addListener((state) {
      if (state.voiceResponse.isNotEmpty && state.voiceResponse != _lastSpokenResponse) {
        _lastSpokenResponse = state.voiceResponse;
        unawaited(_speak(state.voiceResponse));
      }
    });
    unawaited(_configureTts());
    unawaited(_restoreSavedVoice());
    _bootstrap();
  }

  final MyCoveApi _api;
  final TokenStorage _tokenStorage;
  final EstateStorage _estateStorage;
  final BiometricStorage _biometricStorage;
  final VoiceSettingsStorage _voiceSettingsStorage = const VoiceSettingsStorage();
  final AppStateCache _stateCache = AppStateCache();
  final Ref _ref;
  final _random = Random();
  final _localAuth = LocalAuthentication();
  int _loginAttempts = 0;
  int _otpAttempts = 0;
  // True while a biometric prompt we ourselves triggered is up (or in the
  // brief window right after it closes) — see refreshOnResume/
  // unlockWithBiometrics for why this exists.
  bool _biometricPromptActive = false;
  final _speech = SpeechToText();
  bool _speechInitialized = false;
  final _tts = FlutterTts();
  // Guards the addListener-driven speak-on-change hook above from
  // re-speaking the same text on every unrelated state mutation.
  String? _lastSpokenResponse;
  // The report currently being read aloud, and how far into it playback
  // got — see playMeetingReport/pauseMeetingReport/resumeMeetingReport.
  // Tracked here rather than in AppState since it's TTS-engine plumbing,
  // not anything the UI reads directly.
  String? _reportText;
  int _reportOffset = 0;
  // Which real screen voice is currently mid-flow with — drives how the
  // NEXT utterance is interpreted (a bare "20000" means different things
  // depending on whether we're still resolving BUY_ELECTRICITY's amount, or
  // reading back a meter number, or answering a yes/no). Not part of
  // AppState since no widget needs to read it directly.
  _VoiceFlow _voiceContext = _VoiceFlow.none;
  // Caps auto-restarting the mic after unparsed/failed turns, so a broken
  // recognizer can't loop forever without the resident tapping anything.
  // Non-null exactly while asking "which meter?" — a resident with more
  // than one saved meter is never assumed to mean "the" one, so this holds
  // the choices (and the already-known amount) until one is picked, either
  // by voice (matchMeterChoice) or by tapping a card on the select-meter
  // screen (which bypasses voice entirely and just proceeds normally).
  List<UtilityMeter>? _pendingMeterChoices;
  int? _pendingMeterChoiceAmount;
  // True exactly while asking "would you like a breakdown?" after speaking
  // the estate dues balance — the next utterance is a yes/no answer to
  // that, not a fresh top-level command.
  bool _pendingDuesBreakdown = false;
  // Voice-turn logging (see VoiceLogEntry) — one entry per spoken turn,
  // capturing what was said, how the parser classified it and why, and
  // what the assistant did about it. Feeds the offline analysis loop that
  // proposes reviewed parser improvements.
  final VoiceLogStorage _voiceLog = VoiceLogStorage();
  // The parser's result for the turn currently being processed — stashed
  // by _processVoiceTranscript so the logging wrapper can read it once the
  // whole turn settles.
  ParsedVoiceCommand? _turnParseResult;
  // Voice-turn latency measurement — set when the transcript lands, read
  // when the turn settles (both for the JSON log and Mixpanel).
  final Stopwatch _turnLatency = Stopwatch();

  AnalyticsService get _analytics => AnalyticsService.instance;
  String get _platform =>
      Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'other';

  /// Attaches Mixpanel identity after login or silent session restore.
  void _identifyAnalytics() {
    final user = state.currentUser;
    if (user == null) return;
    _analytics.identify(
      userId: user.id,
      role: user.role,
      fullName: user.fullName,
      phone: user.phone,
      estateName: user.estateName,
    );
  }

  /// Gate on a validated estate code before anything else — this app is
  /// shared across estates, so a fresh install doesn't know which estate's
  /// backend data it should even be logging into. Once an estate has been
  /// validated once, it's remembered and this step is skipped on future
  /// launches (see submitEstateCode).
  Future<void> _bootstrap() async {
    unawaited(_checkBiometricAvailability());
    final estateName = await _estateStorage.readName();
    if (estateName == null) {
      state = state.copyWith(authStage: AuthStage.welcome);
      return;
    }
    final estateAddress = await _estateStorage.readAddress();
    final estateImage = await _estateStorage.readImage();
    final estateLocked = await _estateStorage.readLocked();
    state = state.copyWith(
      estateName: estateName,
      estateAddress: estateAddress,
      estateImage: estateImage,
      estateLocked: estateLocked,
    );
    await _tryAutoLogin();
  }

  /// From the welcome screen — "Find Your Estate" and "Log In" both need an
  /// estate code entered first (the API itself is estate-scoped), so both
  /// land here; "I'm a Security Guard" calls [setRoleGuard] first so the
  /// guard tab is already selected once they reach the login screen.
  ///
  /// Once this device is locked to an estate (see [estateLocked] on
  /// AppState), there's no code left to enter — go straight to login
  /// instead of re-offering "Find Your Estate".
  void goToEstateCode() => state = state.copyWith(
    authStage: state.estateLocked ? AuthStage.login : AuthStage.estateCode,
  );

  void backToWelcome() => state = state.copyWith(
    authStage: AuthStage.welcome,
    estateCodeInput: '',
    estateCodeError: '',
  );

  /// A revoked account means this person no longer belongs to this
  /// estate — the token and estate code are both already cleared from
  /// storage by ApiClient by the time this fires, so this just resets
  /// in-memory state and sends them back to "Find your estate" with an
  /// explanation, ready to enter a different estate's code if they've
  /// joined one.
  void _handleAccountDeactivated() {
    state = AppState(
      authStage: AuthStage.estateCode,
      estateCodeError:
          'Your access was revoked by your estate admin. Enter an estate code to continue.',
    );
  }

  void onEstateCodeChange(String v) =>
      state = state.copyWith(estateCodeInput: v, estateCodeError: '');

  /// Only looks the code up and stages the result — nothing is persisted
  /// to EstateStorage yet. The resident confirms what they found on the
  /// "Estate found" screen first (see [confirmEstate]); this keeps a
  /// mistyped-but-valid code (someone else's estate) from being committed
  /// before they've actually seen which estate it resolved to.
  Future<void> submitEstateCode() async {
    final code = state.estateCodeInput.trim();
    if (code.isEmpty) {
      state = state.copyWith(estateCodeError: 'Enter your estate code.');
      return;
    }
    state = state.copyWith(estateCodeLoading: true, estateCodeError: '');
    try {
      final result = await _api.lookupEstate(code);
      state = state.copyWith(
        estateCodeLoading: false,
        pendingEstateCode: code,
        pendingEstateName: result['name'] as String,
        pendingEstateAddress: result['address'] as String?,
        pendingEstateImage: result['imageBase64'] as String?,
        pendingEstateManagedBy: result['managedBy'] as String?,
        pendingEstateResidentCount: result['residentCount'] as int?,
        authStage: AuthStage.estateFound,
      );
      _analytics.track('estate_code_submitted', {'success': true});
    } catch (e) {
      _analytics.track('estate_code_submitted', {
        'success': false,
        'error': extractMessage(e),
      });
      state = state.copyWith(
        estateCodeLoading: false,
        estateCodeError: extractMessage(e),
      );
    }
  }

  /// "Continue to Login" on the estate-found screen — this is the actual
  /// commit point: only now does the code get remembered on-device (see
  /// EstateStorage's doc comment on why that matters for future launches).
  Future<void> confirmEstate() async {
    final code = state.pendingEstateCode;
    final name = state.pendingEstateName;
    if (code == null || name == null) return;
    final address = state.pendingEstateAddress;
    final image = state.pendingEstateImage;
    await _estateStorage.save(
      code: code,
      name: name,
      address: address,
      image: image,
    );
    state = state.copyWith(
      estateName: name,
      estateAddress: address,
      estateImage: image,
      pendingEstateCode: null,
      pendingEstateName: null,
      pendingEstateAddress: null,
      pendingEstateImage: null,
      pendingEstateManagedBy: null,
      pendingEstateResidentCount: null,
    );
    _analytics.track('estate_confirmed', {'estate_name': name});
    await _tryAutoLogin();
  }

  /// "Enter a different code" (or the back arrow) on the estate-found
  /// screen — nothing was ever persisted, so this just clears the staged
  /// result and returns to the code entry field.
  void reenterEstateCode() {
    state = state.copyWith(
      authStage: AuthStage.estateCode,
      pendingEstateCode: null,
      pendingEstateName: null,
      pendingEstateAddress: null,
      pendingEstateImage: null,
      pendingEstateManagedBy: null,
      pendingEstateResidentCount: null,
    );
  }

  Future<void> _registerPushToken() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      final token = await _ref.read(pushServiceProvider).getToken();
      if (token == null) return;
      await _api.registerDeviceToken(token, Platform.isIOS ? 'IOS' : 'ANDROID');
    } catch (_) {
      // Best-effort — push registration failing shouldn't block login.
    }
  }

  Future<void> _unregisterPushToken() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      final token = await _ref.read(pushServiceProvider).getToken();
      if (token == null) return;
      await _api.unregisterDeviceToken(token);
    } catch (_) {
      // Best-effort.
    }
  }

  Future<void> _tryAutoLogin() async {
    final token = await _tokenStorage.read();
    if (token == null) {
      state = state.copyWith(authStage: AuthStage.login);
      return;
    }

    Map<String, dynamic> meJson;
    try {
      meJson = await _api.me();
    } on DioException catch (e) {
      // No response at all (offline/unreachable/timeout) is not proof the
      // token itself is invalid — an actual rejection (expired/revoked)
      // comes back as a real HTTP response, e.response != null, and falls
      // through to the catch-all below unchanged. With cached data on
      // hand, enter the app off it instead of forcing a login the device
      // can't even attempt right now; _enterApp's identityUnconfirmed
      // fail-safes the biometric-lock decision since currentUser can't be
      // confirmed this way.
      if (e.response == null) {
        final cached = await _stateCache.read();
        if (cached != null) {
          await _hydrateFromCache();
          await _enterApp(identityUnconfirmed: true);
          unawaited(
            _bootstrapResidentDeduped().catchError((_) {
              // Swallow — will retry on the next refresh trigger (resume,
              // pull-to-refresh, push) once connectivity returns.
            }),
          );
          return;
        }
      }
      await _tokenStorage.clear();
      state = state.copyWith(authStage: AuthStage.login);
      return;
    } catch (_) {
      await _tokenStorage.clear();
      state = state.copyWith(authStage: AuthStage.login);
      return;
    }

    try {
      final user = CurrentUser.fromJson(meJson);
      final role = _roleFromApi(user.role);
      state = state.copyWith(
        currentUser: user,
        role: role,
        estateName: user.estateName ?? state.estateName,
        estateAddress: user.estateAddress ?? state.estateAddress,
      );
      if (user.role == 'GUARD') {
        // Guard-role offline caching isn't built yet — unchanged: block on
        // a real fetch before entering the app, same as before this cache
        // existed.
        await _bootstrapGuardDeduped();
        await _enterApp();
      } else {
        // Show last-known data immediately instead of sitting on
        // AuthStage.bootstrapping for the full ~17-request fetch — hydrate
        // from cache (if any), enter the app right away, then let the real
        // bootstrap run in the background and overwrite the cached data
        // with fresh data once it lands (see _bootstrapResident's own
        // _persistCache() call, which refreshes this cache for next time).
        await _hydrateFromCache();
        await _enterApp();
        // Deliberately not awaited (see above) — but also deliberately not
        // left to fail into this method's own try/catch, since that catch
        // means "auto-login failed, log out." A resident already looking
        // at valid cached data from a dead connection must stay logged in;
        // a real auth failure (expired/revoked token) is handled
        // independently by ApiClient's onAccountDeactivated interceptor,
        // not by this call site.
        unawaited(
          _bootstrapResidentDeduped().catchError((_) {
            // Swallow — see comment above. Next successful refresh trigger
            // (resume, pull-to-refresh, push) will retry.
          }),
        );
      }
      _identifyAnalytics();
      unawaited(_registerPushToken());
    } catch (_) {
      await _tokenStorage.clear();
      state = state.copyWith(authStage: AuthStage.login);
    }
  }

  /// Data is already loaded by the time this runs (called after bootstrap)
  /// — biometric lock, when enabled, sits in front of an already-ready app
  /// rather than blocking the data fetch behind it.
  ///
  /// [identityUnconfirmed] is set when entering the app off a cached
  /// snapshot because the identity check ([_api.me]) couldn't reach the
  /// server at all — [state.currentUser] is whatever it was before (often
  /// null), so its `hasPin` can't be trusted either way. Fail safe in that
  /// case: if biometric unlock is enabled at all, lock regardless of
  /// `hasPin`, rather than risk skipping a lock screen the resident
  /// actually has configured just because we couldn't confirm it.
  Future<void> _enterApp({bool identityUnconfirmed = false}) async {
    final biometricEnabled = await _biometricStorage.readEnabled();
    final hasPin = identityUnconfirmed
        ? biometricEnabled
        : (state.currentUser?.hasPin ?? false);
    state = state.copyWith(
      authStage: biometricEnabled && hasPin ? AuthStage.locked : AuthStage.app,
      biometricEnabled: biometricEnabled,
    );
  }

  // ── Login ────────────────────────────────────────────────────────────
  void setRoleResident() =>
      state = state.copyWith(role: Role.resident, loginError: '');
  void setRoleGuard() =>
      state = state.copyWith(role: Role.guard, loginError: '');
  void onPhoneChange(String v) => state = state.copyWith(loginPhone: v);
  void onPasswordChange(String v) => state = state.copyWith(loginPassword: v);
  void setRememberMe(bool v) => state = state.copyWith(rememberMe: v);

  /// Hands off to the Google Maps app (or its web fallback) centered on the
  /// estate's address, rather than embedding a maps SDK of our own — that
  /// would need a billed Google Cloud API key just to show live traffic
  /// coloring, which Maps already does for free once it opens.
  Future<void> openTrafficUpdate() async {
    final address = state.estateAddress ?? state.estateName;
    if (address == null || address.isEmpty) return;
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': address,
    });
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // No maps app/browser available to hand off to — nothing else to do.
    }
  }

  /// "Change" on the estate card during login — unlike [reenterEstateCode]
  /// (used before anything's been confirmed), the estate here is already
  /// committed to EstateStorage, so this actually clears it.
  Future<void> changeEstate() async {
    await _estateStorage.clear();
    state = state.copyWith(
      authStage: AuthStage.estateCode,
      estateName: null,
      estateAddress: null,
      estateCodeInput: '',
    );
  }

  Future<void> doLogin() async {
    state = state.copyWith(isLoading: true, loginError: '');
    final loginStart = DateTime.now();
    _analytics.track('login_started', {'login_method': 'password'});
    developer.log('doLogin: starting, role=${state.role}', name: 'AppNotifier');
    try {
      final (platform, deviceName) = await _deviceInfo();
      final result = await _api.login(
        phone: _digitsOnly(state.loginPhone),
        password: state.loginPassword,
        role: _roleToApi(state.role),
        platform: platform,
        deviceName: deviceName,
      );
      developer.log(
        'doLogin: /auth/login succeeded, mustResetPassword=${result['mustResetPassword']}',
        name: 'AppNotifier',
      );
      await _tokenStorage.save(result['accessToken'] as String);
      // Always needed for this session's own requests (see ApiClient's
      // interceptor) regardless of "remember me" — only the *refresh*
      // token controls whether the session outlives the 15-minute access
      // token.
      if (state.rememberMe) {
        await _tokenStorage.saveRefreshToken(result['refreshToken'] as String);
      }
      final user = CurrentUser.fromJson(await _api.me());
      // A successful login proves this device belongs to this estate —
      // lock it in so "Change" stops being offered on the login screen.
      await _estateStorage.markLocked();
      state = state.copyWith(
        currentUser: user,
        isLoading: false,
        // The server's own estate relation is the source of truth — local
        // storage (set only when this device went through "Find Your
        // Estate" itself) can be stale or, on some paths to this screen,
        // never populated at all.
        estateName: user.estateName ?? state.estateName,
        estateAddress: user.estateAddress ?? state.estateAddress,
        estateLocked: true,
      );

      // Guards share a duty phone rather than a personal device, so there's
      // no "first login, set up your own profile" moment for them — their
      // password is set directly by an admin and they go straight in, even
      // if an older account still has the resident-oriented flag set.
      if (result['mustResetPassword'] == true && user.role != 'GUARD') {
        developer.log('doLogin: routing to forceReset', name: 'AppNotifier');
        state = state.copyWith(
          authStage: AuthStage.forceReset,
          setupFullName: user.fullName,
          setupHouse: user.house ?? '',
          setupStreet: user.street ?? '',
          setupHouseNumber: user.houseNumber ?? '',
          setupEmail: user.email ?? '',
          setupEmergencyContactName: user.emergencyContactName ?? '',
          setupEmergencyContactPhone: user.emergencyContactPhone ?? '',
          setupVehiclePlates: user.vehiclePlates.join(', '),
        );
        await loadEstateStreets();
        return;
      }
      if (user.role == 'GUARD') {
        await _bootstrapGuardDeduped();
      } else {
        await _bootstrapResidentDeduped();
      }
      // Straight to `app`, not through the biometric lock — typing the
      // password just now already was the authentication event. The lock
      // only guards *silent* session restoration (see _tryAutoLogin).
      state = state.copyWith(
        authStage: AuthStage.app,
        biometricEnabled: await _biometricStorage.readEnabled(),
      );
      _identifyAnalytics();
      _analytics.track('login_success', {
        'login_method': 'password',
        'duration_ms': DateTime.now().difference(loginStart).inMilliseconds,
      });
      unawaited(_registerPushToken());
      developer.log('doLogin: complete, authStage=app', name: 'AppNotifier');
    } catch (e, st) {
      developer.log(
        'doLogin: FAILED — ${e.runtimeType}: $e',
        name: 'AppNotifier',
        error: e,
        stackTrace: st,
        level: 1000,
      );
      _analytics.track('login_failed', {
        'login_method': 'password',
        'failure_reason': extractMessage(e),
        'attempt_number': _loginAttempts,
      });
      _loginAttempts++;
      state = state.copyWith(isLoading: false, loginError: extractMessage(e));
    }
  }

  // ── Forgot / OTP / reset ─────────────────────────────────────────────
  void goForgot() =>
      state = state.copyWith(authStage: AuthStage.forgot, resetMsg: '');
  void onForgotPhoneChange(String v) => state = state.copyWith(forgotPhone: v);

  Future<void> sendOtp() async {
    state = state.copyWith(isLoading: true, resetMsg: '');
    try {
      final result = await _api.forgotPassword(_digitsOnly(state.forgotPhone));
      _analytics.track('otp_requested', {
        'otp_type': 'password_reset',
        'channel': 'sms',
      });
      state = state.copyWith(
        authStage: AuthStage.otp,
        isLoading: false,
        devOtp: result['devOtp'] as String?,
      );
    } catch (e) {
      _analytics.track('otp_requested', {
        'otp_type': 'password_reset',
        'channel': 'sms',
      });
      state = state.copyWith(isLoading: false, resetMsg: extractMessage(e));
    }
  }

  void onOtpChange(String v) {
    final digits = _digitsOnly(v);
    state = state.copyWith(otpCode: digits.substring(0, min(6, digits.length)));
  }

  Future<void> verifyOtp() async {
    final otpStart = DateTime.now();
    if (state.otpCode.length != 6) {
      state = state.copyWith(
        resetMsg: 'Enter the 6-digit code sent to your phone.',
      );
      return;
    }
    state = state.copyWith(isLoading: true, resetMsg: '');
    try {
      final result = await _api.verifyOtp(
        phone: _digitsOnly(state.forgotPhone),
        code: state.otpCode,
      );
      _analytics.track('otp_verified', {
        'otp_type': 'password_reset',
        'channel': 'sms',
        'attempt_number': _otpAttempts,
        'duration_ms': DateTime.now().difference(otpStart).inMilliseconds,
      });
      state = state.copyWith(
        authStage: AuthStage.newPassword,
        resetToken: result['resetToken'] as String,
        isLoading: false,
      );
    } catch (e) {
      _analytics.track('otp_verified', {
        'otp_type': 'password_reset',
        'channel': 'sms',
        'attempt_number': _otpAttempts,
        'duration_ms': DateTime.now().difference(otpStart).inMilliseconds,
      });
      _otpAttempts++;
      state = state.copyWith(isLoading: false, resetMsg: extractMessage(e));
    }
  }

  void onNewPass1(String v) => state = state.copyWith(newPass1: v);
  void onNewPass2(String v) => state = state.copyWith(newPass2: v);
  void onSetupFullName(String v) => state = state.copyWith(setupFullName: v);
  void onSetupHouse(String v) => state = state.copyWith(setupHouse: v);
  void onSetupStreet(String v) => state = state.copyWith(setupStreet: v);
  void onSetupHouseNumber(String v) =>
      state = state.copyWith(setupHouseNumber: v);

  /// Loads the estate's street list for the profile step. A failure just
  /// leaves the list empty, which falls back to the free-text house field —
  /// never worth blocking onboarding over.
  Future<void> loadEstateStreets() async {
    try {
      final streets = await _api.estateStreets();
      state = state.copyWith(estateStreets: streets);
    } catch (_) {
      // Keep whatever we had; the free-text fallback still works.
    }
  }
  void onSetupEmail(String v) => state = state.copyWith(setupEmail: v);
  void onSetupEmergencyContactName(String v) =>
      state = state.copyWith(setupEmergencyContactName: v);
  void onSetupEmergencyContactPhone(String v) =>
      state = state.copyWith(setupEmergencyContactPhone: v);
  void onSetupVehiclePlates(String v) =>
      state = state.copyWith(setupVehiclePlates: v);

  Future<void> submitNewPassword() async {
    if (state.newPass1.length < 6) {
      state = state.copyWith(
        resetMsg: 'Password must be at least 6 characters.',
      );
      return;
    }
    if (state.newPass1 != state.newPass2) {
      state = state.copyWith(resetMsg: 'Passwords do not match.');
      return;
    }
    state = state.copyWith(isLoading: true, resetMsg: '');
    try {
      await _api.resetPassword(
        resetToken: state.resetToken!,
        newPassword: state.newPass1,
      );
      // Successfully resetting the password proves this account belongs
      // to this device's estate — same commit point as a normal login.
      await _estateStorage.markLocked();
      _analytics.track('password_reset_completed');
      state = state.copyWith(
        authStage: AuthStage.resetSuccess,
        newPass1: '',
        newPass2: '',
        resetMsg: '',
        resetToken: null,
        loginError: '',
        isLoading: false,
        estateLocked: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, resetMsg: extractMessage(e));
    }
  }

  Future<void> completeForceReset() async {
    if (state.newPass1.length < 6) {
      state = state.copyWith(
        resetMsg: 'Password must be at least 6 characters.',
      );
      return;
    }
    if (state.newPass1 != state.newPass2) {
      state = state.copyWith(resetMsg: 'Passwords do not match.');
      return;
    }
    if (state.setupFullName.trim().isEmpty) {
      state = state.copyWith(resetMsg: 'Full name is required.');
      return;
    }
    final usesStreets = state.estateStreets.isNotEmpty;
    if (usesStreets) {
      if (state.setupStreet.trim().isEmpty) {
        state = state.copyWith(resetMsg: 'Please select your street.');
        return;
      }
      if (state.setupHouseNumber.trim().isEmpty) {
        state = state.copyWith(resetMsg: 'House number is required.');
        return;
      }
    } else if (state.setupHouse.trim().isEmpty) {
      state = state.copyWith(resetMsg: 'House address is required.');
      return;
    }
    state = state.copyWith(isLoading: true, resetMsg: '');
    developer.log('completeForceReset: starting', name: 'AppNotifier');
    try {
      final plates = state.setupVehiclePlates
          .split(',')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
      await _api.completeForceReset(
        newPassword: state.newPass1,
        fullName: state.setupFullName.trim(),
        house: usesStreets ? null : state.setupHouse.trim(),
        street: usesStreets ? state.setupStreet.trim() : null,
        houseNumber: usesStreets ? state.setupHouseNumber.trim() : null,
        email: state.setupEmail.trim().isEmpty ? null : state.setupEmail.trim(),
        emergencyContactName: state.setupEmergencyContactName.trim().isEmpty
            ? null
            : state.setupEmergencyContactName.trim(),
        emergencyContactPhone: state.setupEmergencyContactPhone.trim().isEmpty
            ? null
            : state.setupEmergencyContactPhone.trim(),
        vehiclePlates: plates,
      );
      developer.log(
        'completeForceReset: /auth/complete-force-reset succeeded, running bootstrap',
        name: 'AppNotifier',
      );

      // The role driving which bootstrap runs is whatever the admin set
      // this account up as — not assumed to always be a resident, since
      // guard accounts can need first-time setup too.
      final role = state.currentUser?.role == 'GUARD'
          ? Role.guard
          : Role.resident;
      if (role == Role.guard) {
        await _bootstrapGuardDeduped();
      } else {
        await _bootstrapResidentDeduped();
      }
      developer.log('completeForceReset: bootstrap succeeded', name: 'AppNotifier');
      // Data's already loaded (bootstrap just ran above) — the success
      // screen sits in front of an app that's ready to go the moment
      // finishOnboarding flips authStage to app, same as the biometric
      // lock screen does for a silently-restored session.
      _analytics.track('force_reset_completed', {'role': role.name});
      state = state.copyWith(
        authStage: AuthStage.onboardingComplete,
        role: role,
        newPass1: '',
        newPass2: '',
        resetMsg: '',
        isLoading: false,
      );
    } catch (e, st) {
      developer.log(
        'completeForceReset: FAILED — ${e.runtimeType}: $e',
        name: 'AppNotifier',
        error: e,
        stackTrace: st,
        level: 1000,
      );
      // A 401 here — even after the interceptor's own silent
      // refresh-and-retry (see ApiClient) — means there's no way left to
      // recover this session (no refresh token stored, or it's also
      // expired/revoked). Rather than strand the resident on this screen
      // staring at a raw "Invalid token" with no way forward, send them
      // back to a fresh login — most likely explanation is this device
      // already completed its reset in an earlier session and is holding
      // a stale token, so logging in again should just work.
      if (e is DioException && e.response?.statusCode == 401) {
        await _tokenStorage.clear();
        state = state.copyWith(
          isLoading: false,
          authStage: AuthStage.login,
          resetMsg: '',
          loginError: 'Your session expired. Please log in again.',
        );
        return;
      }
      state = state.copyWith(isLoading: false, resetMsg: extractMessage(e));
    }
  }

  void finishOnboarding() => state = state.copyWith(authStage: AuthStage.app);

  void backToLogin() =>
      state = state.copyWith(authStage: AuthStage.login, resetMsg: '');

  void backToOtp() =>
      state = state.copyWith(authStage: AuthStage.otp, resetMsg: '');

  Future<void> logout() async {
    await _unregisterPushToken();
    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      await _api.logoutRequest(refreshToken);
    } catch (_) {
      // Best-effort — the token is discarded locally regardless.
    }
    await _tokenStorage.clear();
    // Devices get handed to a different person often enough (guards share
    // a duty phone across shifts) that leaving a stale biometric-enabled
    // flag around would lock the *next* login behind someone else's face.
    await _biometricStorage.setEnabled(false);
    _analytics.track('logout');
    _analytics.reset();
    state = AppState(
      authStage: AuthStage.login,
      biometricAvailable: state.biometricAvailable,
      estateName: state.estateName,
      estateAddress: state.estateAddress,
      estateImage: state.estateImage,
      estateLocked: state.estateLocked,
    );
  }

  /// Pull-to-refresh for any resident list screen — re-runs the same
  /// batched fetch bootstrap used at login, so every screen it feeds stays
  /// in sync with whatever it refetches.
  Future<void> refreshResident() => _bootstrapResidentDeduped();

  /// Persists an emergency-contact edit from the profile page and swaps in
  /// the fresh [CurrentUser] the API echoes back. Returns null on success,
  /// otherwise a user-facing error string — same contract as
  /// [sendHouseholdInvite]. This is also how household-invited members add
  /// an emergency contact after the fact, since their first-login flow
  /// skips the profile-completion step entirely.
  Future<String?> saveEmergencyContact({required String name, required String phone}) async {
    final hadContact =
        (state.currentUser?.emergencyContactName?.isNotEmpty ?? false) ||
            (state.currentUser?.emergencyContactPhone?.isNotEmpty ?? false);
    try {
      final updated = CurrentUser.fromJson(
        await _api.updateMe(
          emergencyContactName: name.trim(),
          emergencyContactPhone: phone.trim(),
        ),
      );
      state = state.copyWith(currentUser: updated);
      // Segments funnels by first-time set vs later edit vs removal —
      // a spike in removals after a SOS change would be worth noticing.
      _analytics.track('emergency_contact_updated', {
        'action': phone.trim().isEmpty
            ? 'remove'
            : hadContact
                ? 'update'
                : 'set',
      });
      return null;
    } catch (e) {
      return extractMessage(e);
    }
  }

  /// Pull-to-refresh for the guard access-log screen — re-runs the same
  /// fetch bootstrap used at guard login, so the log stays in sync with
  /// whatever it refetches.
  Future<void> refreshGuard() => _bootstrapGuardDeduped();

  /// Re-fetches whenever the app comes back to the foreground (opened from
  /// the app switcher, or from tapping a push notification) — otherwise the
  /// screen just shows whatever was last fetched, possibly stale by then.
  /// No-ops outside the logged-in app state (e.g. mid-login) since there's
  /// nothing to refresh yet.
  Future<void> refreshOnResume() async {
    // Presenting the native Face ID/Touch ID system prompt itself fires an
    // app-resume lifecycle event when it dismisses — without this guard,
    // that spurious resume looks identical to "the user backgrounded and
    // returned," so unlockWithBiometrics()'s own success would immediately
    // trigger this method to lock the app right back, forever (the exact
    // "unlock, instantly locks again" loop).
    if (_biometricPromptActive) return;
    if (state.authStage != AuthStage.app) return;
    if (state.biometricEnabled && (state.currentUser?.hasPin ?? false)) {
      state = state.copyWith(authStage: AuthStage.locked);
      return;
    }
    unawaited(checkPendingPaymentStatus());
    if (state.role == Role.guard) {
      await _bootstrapGuardDeduped();
    } else {
      await _bootstrapResidentDeduped();
    }
  }

  // ── Biometric lock ───────────────────────────────────────────────────
  Future<void> _checkBiometricAvailability() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      state = state.copyWith(biometricAvailable: supported && canCheck);
    } catch (_) {
      state = state.copyWith(biometricAvailable: false);
    }
  }

  /// Called from the unlock screen. On success, resumes exactly what
  /// [refreshOnResume] paused (or what [_tryAutoLogin] deferred on cold
  /// start) by re-running the same data bootstrap.
  Future<bool> unlockWithBiometrics() async {
    // Set for the whole call, not just around authenticate() — the
    // resume event this guards against can land either while the native
    // prompt is up or in the brief window right after it closes.
    _biometricPromptActive = true;
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Unlock MyCove',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!ok) return false;
      _analytics.track('app_unlocked', {'method': 'biometric', 'success': true});
      await _resumeAppAfterUnlock();
      return true;
    } catch (_) {
      _analytics.track('app_unlocked', {'method': 'biometric', 'success': false});
      return false;
    } finally {
      _biometricPromptActive = false;
    }
  }

  /// The transaction PIN as a fallback unlock method, for when biometrics
  /// isn't available or isn't cooperating (wrong finger, Face ID blocked by
  /// a mask, etc.) — verifies against the same PIN used to authorize
  /// purchases, then does exactly what a successful biometric check does.
  Future<bool> unlockWithPin(String pin) async {
    final valid = await verifyTransactionPin(pin);
    _analytics.track('app_unlocked', {'method': 'pin', 'success': valid});
    if (!valid) return false;
    await _resumeAppAfterUnlock();
    return true;
  }

  Future<void> _resumeAppAfterUnlock() async {
    state = state.copyWith(authStage: AuthStage.app);
    if (state.role == Role.guard) {
      await _bootstrapGuardDeduped();
    } else {
      await _bootstrapResidentDeduped();
    }
  }

  /// Called from the profile toggle — requires a successful auth right
  /// then, before persisting the flag, so turning it on always proves the
  /// device's biometrics actually work for this user.
  Future<bool> enableBiometrics() async {
    // Same spurious-resume risk as unlockWithBiometrics: if the prompt's
    // dismissal resume event lands right after biometricEnabled flips to
    // true below, refreshOnResume would otherwise lock the app the instant
    // it's turned on.
    _biometricPromptActive = true;
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Confirm to enable biometric unlock',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!ok) return false;
      await _biometricStorage.setEnabled(true);
      state = state.copyWith(biometricEnabled: true);
      _analytics.track('biometric_enabled', {'success': true});
      return true;
    } catch (_) {
      return false;
    } finally {
      _biometricPromptActive = false;
    }
  }

  Future<void> disableBiometrics() async {
    await _biometricStorage.setEnabled(false);
    state = state.copyWith(biometricEnabled: false);
    _analytics.track('biometric_disabled');
  }

  // ── Device sessions ──────────────────────────────────────────────────
  Future<void> loadSessions() async {
    try {
      final raw = await _api.listSessions();
      final sessions = raw
          .map((e) => SessionInfo.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(sessions: sessions);
    } catch (_) {
      // Best-effort — the page just shows whatever was already loaded.
    }
  }

  Future<void> revokeSession(String id) async {
    try {
      await _api.revokeSession(id);
      await loadSessions();
    } catch (_) {
      // Best-effort.
    }
  }

  /// Compares against [SessionInfo.jti] to mark "this device" in the list
  /// — the access token attached to every guarded request carries its own
  /// jti, not the refresh token's, so this has to be read locally instead.
  Future<String?> currentSessionJti() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) return null;
    return jwtJti(refreshToken);
  }

  Future<(String?, String?)> _deviceInfo() async {
    if (!Platform.isAndroid && !Platform.isIOS) return (null, null);
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final iosInfo = await info.iosInfo;
        return ('IOS', iosInfo.name);
      }
      final androidInfo = await info.androidInfo;
      return ('ANDROID', androidInfo.model);
    } catch (_) {
      return (Platform.isIOS ? 'IOS' : 'ANDROID', null);
    }
  }

  // ── Bootstrap ─────────────────────────────────────────────────────────
  // `_bootstrapResident`/`_bootstrapGuard` are called from six independent
  // triggers (login, auto-login, force-reset, resume-refresh, and every
  // pull-to-refresh site) that can legitimately overlap — e.g. the app
  // resuming while a manual pull-to-refresh is already in flight. Routing
  // every call through these deduped wrappers means a second call while
  // one's already running just awaits the same Future instead of firing a
  // duplicate 17-request burst.
  Future<void>? _residentBootstrapInFlight;
  Future<void> _bootstrapResidentDeduped() {
    return _residentBootstrapInFlight ??= _bootstrapResident().whenComplete(
      () => _residentBootstrapInFlight = null,
    );
  }

  Future<void>? _guardBootstrapInFlight;
  Future<void> _bootstrapGuardDeduped() {
    return _guardBootstrapInFlight ??= _bootstrapGuard().whenComplete(
      () => _guardBootstrapInFlight = null,
    );
  }

  // ── Offline cache ────────────────────────────────────────────────────
  // Resident data only — guard-role caching (accessLog/duesOwing from
  // _bootstrapGuard) is a separate, not-yet-built decision. Deliberately
  // excludes authStage, form-input fields, and currentUser/tokens — this
  // file is unencrypted-at-rest JSON, not secure storage.
  Map<String, dynamic> _cacheSnapshot() => {
    'cachedAt': DateTime.now().toIso8601String(),
    'announcements': state.announcements.map((e) => e.toJson()).toList(),
    'meetings': state.meetings.map((e) => e.toJson()).toList(),
    'duesBalance': state.duesBalance,
    'duesMonthsPaid': state.duesMonthsPaid,
    'duesHistory': state.duesHistory.map((e) => e.toJson()).toList(),
    'levies': state.levies.map((e) => e.toJson()).toList(),
    'visitorPasses': state.visitorPasses.map((e) => e.toJson()).toList(),
    'projects': state.projects.map((e) => e.toJson()).toList(),
    'polls': state.polls.map((e) => e.toJson()).toList(),
    'notifications': state.notifications.map((e) => e.toJson()).toList(),
    'allNotifsRead': state.allNotifsRead,
    'rulesSections': state.rulesSections.map((e) => e.toJson()).toList(),
    'spotlight': state.spotlight?.toJson(),
    'spotlights': state.spotlights.map((e) => e.toJson()).toList(),
    'myPledges': state.myPledges.map((e) => e.toJson()).toList(),
    'utilityMeters': state.utilityMeters.map((e) => e.toJson()).toList(),
    'discos': state.discos.map((e) => e.toJson()).toList(),
    'walletBalance': state.walletBalance,
    'utilityPurchases': state.utilityPurchases.map((e) => e.toJson()).toList(),
    'householdMembers': state.householdMembers.map((e) => e.toJson()).toList(),
    'householdInvites': state.householdInvites.map((e) => e.toJson()).toList(),
    'securityGuardPhone': state.securityGuardPhone,
    'estateAdminPhone': state.estateAdminPhone,
  };

  /// Best-effort, fire-and-forget — a failed cache write must never block
  /// or fail whatever just finished fetching.
  void _persistCache() {
    unawaited(_stateCache.write(_cacheSnapshot()));
  }

  /// Applies a cached snapshot (if one exists) to `state` — called from
  /// `_tryAutoLogin` right after a real `currentUser` is confirmed but
  /// before the (slow) full bootstrap, so the UI has last-known data to
  /// show the instant `authStage` leaves `bootstrapping`, instead of
  /// sitting on a blank/loading screen for the full ~17-request fetch.
  Future<void> _hydrateFromCache() async {
    final json = await _stateCache.read();
    if (json == null) return;
    List<T> parseList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      final raw = json[key] as List<dynamic>?;
      if (raw == null) return <T>[];
      return raw.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }

    final spotlightJson = json['spotlight'] as Map<String, dynamic>?;
    state = state.copyWith(
      announcements: parseList('announcements', Announcement.fromJson),
      meetings: parseList('meetings', Meeting.fromJson),
      duesBalance: json['duesBalance'] as int? ?? 0,
      duesMonthsPaid: json['duesMonthsPaid'] as int? ?? 0,
      duesHistory: parseList('duesHistory', DuesEntry.fromJson),
      levies: parseList('levies', Levy.fromJson),
      visitorPasses: parseList('visitorPasses', VisitorPass.fromJson),
      projects: parseList('projects', Project.fromJson),
      polls: parseList('polls', Poll.fromJson),
      notifications: parseList('notifications', NotificationItem.fromJson),
      allNotifsRead: json['allNotifsRead'] as bool? ?? true,
      rulesSections: parseList('rulesSections', RulesSection.fromJson),
      spotlight: spotlightJson == null ? null : Spotlight.fromJson(spotlightJson),
      spotlights: parseList('spotlights', Spotlight.fromJson),
      myPledges: parseList('myPledges', MyPledge.fromJson),
      utilityMeters: parseList('utilityMeters', UtilityMeter.fromJson),
      discos: parseList('discos', Disco.fromJson),
      walletBalance: json['walletBalance'] as int? ?? 0,
      utilityPurchases: parseList('utilityPurchases', UtilityPurchase.fromJson),
      householdMembers: parseList('householdMembers', HouseholdMember.fromJson),
      householdInvites: parseList('householdInvites', HouseholdInvite.fromJson),
      securityGuardPhone: json['securityGuardPhone'] as String?,
      estateAdminPhone: json['estateAdminPhone'] as String?,
    );
  }

  Future<void> _bootstrapResident() async {
    final results = await Future.wait([
      _api.announcements(),
      _api.meetings(),
      _api.dues(),
      _api.levies(),
      _api.visitorPasses(),
      _api.projects(),
      _api.polls(),
      _api.notifications(),
      _api.rules(),
      _api.activeSpotlights(),
      _api.myPledges(),
      _api.utilityMeters(),
      _api.discos(),
      _api.walletBalance(),
      _api.utilityPurchases(),
      _api.householdMembers(),
      _api.householdInvites(),
    ]);
    // Fetched outside the batch above on purpose: an admin who hasn't set
    // estate emergency numbers yet (or an older API without them) must not
    // fail the entire dashboard refresh — the SOS screen just falls back
    // to hiding those rows.
    try {
      final contacts = await _api.estateEmergencyContacts();
      state = state.copyWith(
        securityGuardPhone: contacts['securityGuardPhone'] as String?,
        estateAdminPhone: contacts['estateAdminPhone'] as String?,
      );
    } catch (_) {
      // Keep whatever was previously loaded (or null) — non-fatal.
    }

    final announcements = (results[0] as List)
        .map((j) => Announcement.fromJson(j as Map<String, dynamic>))
        .toList();
    final meetings = (results[1] as List)
        .map((j) => Meeting.fromJson(j as Map<String, dynamic>))
        .toList();
    final dues = results[2] as Map<String, dynamic>;
    final levies = ((results[3] as Map<String, dynamic>)['levies'] as List)
        .map((j) => Levy.fromJson(j as Map<String, dynamic>))
        .toList();
    final visitorPasses = (results[4] as List)
        .map((j) => VisitorPass.fromJson(j as Map<String, dynamic>))
        .toList();
    final projects = (results[5] as List)
        .map((j) => Project.fromJson(j as Map<String, dynamic>))
        .toList();
    final polls = (results[6] as List)
        .map((j) => Poll.fromJson(j as Map<String, dynamic>))
        .toList();
    final notificationsJson = results[7] as List;
    final notifications = notificationsJson
        .map((j) => NotificationItem.fromJson(j as Map<String, dynamic>))
        .toList();
    final rulesSections = (results[8] as List)
        .map((j) => RulesSection.fromJson(j as Map<String, dynamic>))
        .toList();
    final spotlights = (results[9] as List)
        .map((j) => Spotlight.fromJson(j as Map<String, dynamic>))
        .toList();
    final spotlight = spotlights.isEmpty
        ? null
        : spotlights[Random().nextInt(spotlights.length)];
    final myPledges = (results[10] as List)
        .map((j) => MyPledge.fromJson(j as Map<String, dynamic>))
        .toList();
    final utilityMeters = (results[11] as List)
        .map((j) => UtilityMeter.fromJson(j as Map<String, dynamic>))
        .toList();
    final discos = (results[12] as List)
        .map((j) => Disco.fromJson(j as Map<String, dynamic>))
        .toList();
    final walletBalance = results[13] as int;
    // Full history, not merged with whatever was already in memory — this
    // is the source of truth bootstrap sets; buyElectricity()/buyAirtime()
    // still prepend the just-made purchase on top of it afterward.
    final utilityPurchases = (results[14] as List)
        .map((j) => UtilityPurchase.fromJson(j as Map<String, dynamic>))
        .toList();
    final householdMembers = (results[15] as List)
        .map((j) => HouseholdMember.fromJson(j as Map<String, dynamic>))
        .toList();
    final householdInvites = (results[16] as List)
        .map((j) => HouseholdInvite.fromJson(j as Map<String, dynamic>))
        .toList();

    state = state.copyWith(
      announcements: announcements,
      meetings: meetings,
      duesBalance: dues['balance'] as int,
      duesMonthsPaid: dues['monthsPaid'] as int? ?? 0,
      duesHistory: (dues['history'] as List)
          .map((j) => DuesEntry.fromJson(j as Map<String, dynamic>))
          .toList(),
      levies: levies,
      visitorPasses: visitorPasses,
      projects: projects,
      polls: polls,
      notifications: notifications,
      allNotifsRead: notificationsJson.every(
        (j) => (j as Map<String, dynamic>)['readAt'] != null,
      ),
      rulesSections: rulesSections,
      spotlight: spotlight,
      spotlights: spotlights,
      myPledges: myPledges,
      utilityMeters: utilityMeters,
      discos: discos,
      walletBalance: walletBalance,
      utilityPurchases: utilityPurchases,
      householdMembers: householdMembers,
      householdInvites: householdInvites,
    );
    _persistCache();
  }

  // ── Household ────────────────────────────────────────────────────────
  Future<void> _refreshHousehold() async {
    final results = await Future.wait([_api.householdMembers(), _api.householdInvites()]);
    state = state.copyWith(
      householdMembers: results[0].map((j) => HouseholdMember.fromJson(j as Map<String, dynamic>)).toList(),
      householdInvites: results[1].map((j) => HouseholdInvite.fromJson(j as Map<String, dynamic>)).toList(),
    );
  }

  Future<String?> sendHouseholdInvite({required String fullName, required String phone}) async {
    try {
      await _api.sendHouseholdInvite(fullName: fullName, phone: _digitsOnly(phone));
      await _refreshHousehold();
      return null;
    } catch (e) {
      return extractMessage(e);
    }
  }

  Future<String?> cancelHouseholdInvite(String id) async {
    try {
      await _api.cancelHouseholdInvite(id);
      await _refreshHousehold();
      return null;
    } catch (e) {
      return extractMessage(e);
    }
  }

  Future<void> _bootstrapGuard() async {
    final results = await Future.wait([_api.accessLog(), _api.duesOwing()]);
    final accessLog = results[0]
        .map((j) => AccessLogEntry.fromJson(j as Map<String, dynamic>))
        .toList();
    final owingResidents = results[1]
        .map((j) => OwingResident.fromJson(j as Map<String, dynamic>))
        .toList();
    state = state.copyWith(accessLog: accessLog, owingResidents: owingResidents);
  }

  // ── Meetings ──────────────────────────────────────────────────────────
  Future<void> addToCalendar(String id) => _api.addToCalendar(id);

  // ── Announcements ────────────────────────────────────────────────────
  Future<void> openAnnouncement(String id) async {
    try {
      await _api.markAnnouncementRead(id);
      final announcement =
          state.announcements.where((a) => a.id == id).firstOrNull;
      _analytics.track('announcement_read', {
        'announcement_id': id,
        if (announcement != null) 'category': announcement.category,
      });
      state = state.copyWith(
        announcements: [
          for (final a in state.announcements)
            if (a.id == id) a.copyWith(unread: false) else a,
        ],
      );
    } catch (_) {
      // Non-critical — the announcement still opens even if "mark read" fails.
    }
  }

  // ── Dues / payment ───────────────────────────────────────────────────
  /// Prepares the payment screen for the resident's own dues balance —
  /// called from the dues "Pay Now" button before pushing `/resident/payment`.
  void resetPayment() => state = state.copyWith(
    paymentStep: PaymentStep.idle,
    paymentReference: null,
    pendingPaymentAmount: state.duesBalance,
    pendingPaymentAmountEditable: true,
    pendingPaymentPurpose: 'DUES',
    pendingPaymentLevyId: null,
    paymentMethod: 'PAYSTACK',
  );

  /// Same as [resetPayment] but for a single levy — called from a levy
  /// row's "Pay" button before pushing `/resident/payment`.
  void startLevyPayment(Levy levy) => state = state.copyWith(
    paymentStep: PaymentStep.idle,
    paymentReference: null,
    pendingPaymentAmount: levy.amount,
    pendingPaymentAmountEditable: false,
    pendingPaymentPurpose: 'LEVY',
    pendingPaymentLevyId: levy.id,
    paymentMethod: 'PAYSTACK',
  );

  /// Switches between the two options on the payment method screen —
  /// 'PAYSTACK' or 'WALLET'.
  void selectPaymentMethod(String method) =>
      state = state.copyWith(paymentMethod: method);

  /// Lets a resident type how much of the dues balance to pay — only used
  /// when [AppState.pendingPaymentAmountEditable] is true.
  void setPendingPaymentAmount(int amount) =>
      state = state.copyWith(pendingPaymentAmount: amount);

  Future<void> confirmPayment() async {
    state = state.copyWith(paymentStep: PaymentStep.processing);
    final amount = state.pendingPaymentAmount;
    final purpose = state.pendingPaymentPurpose;
    final levyId = state.pendingPaymentLevyId;
    final method = state.paymentMethod;
    final analyticsMethod = method == 'WALLET' ? 'wallet' : 'paystack';
    final analyticsType = purpose == 'LEVY' ? 'levy' : 'monthly_dues';
    final paymentStart = DateTime.now();
    _analytics.track('dues_payment_started', {
      'amount': amount,
      'payment_method': analyticsMethod,
      'payment_type': analyticsType,
    });
    try {
      final initiated = await _api.initiatePayment(
        amount: amount,
        purpose: purpose,
        levyId: levyId,
        method: method,
      );
      final reference = initiated['reference'] as String;
      state = state.copyWith(paymentReference: reference);

      // Wallet payments settle synchronously server-side — there's no
      // checkout to hand off to or webhook to wait on, so a SUCCESS here is
      // final, unlike Paystack's PENDING-until-polled flow below.
      if (method == 'WALLET') {
        if (initiated['status'] == 'SUCCESS') {
          _analytics.track('dues_payment_success', {
            'amount': amount,
            'payment_method': analyticsMethod,
            'payment_type': analyticsType,
            'duration_ms': DateTime.now().difference(paymentStart).inMilliseconds,
          });
          await _refreshAfterPaymentSuccess(purpose);
          state = state.copyWith(
            paymentStep: PaymentStep.success,
            paymentReference: reference,
          );
        } else {
          _analytics.track('dues_payment_failed', {
            'amount': amount,
            'payment_method': analyticsMethod,
            'payment_type': analyticsType,
            'failure_reason': 'payment_not_successful',
          });
          state = state.copyWith(paymentStep: PaymentStep.idle);
        }
        return;
      }

      final authorizationUrl = initiated['authorizationUrl'] as String?;
      if (authorizationUrl != null) {
        try {
          await launchUrl(
            Uri.parse(authorizationUrl),
            mode: LaunchMode.externalApplication,
          );
        } catch (_) {
          // No browser available to hand off to — the poll loop below still
          // runs, it just has nothing to eventually report success.
        }
      }

      var status = 'PENDING';
      for (var attempt = 0; attempt < 40 && status == 'PENDING'; attempt++) {
        await Future<void>.delayed(const Duration(seconds: 3));
        status = (await _api.verifyPayment(reference))['status'] as String;
      }

      if (status == 'SUCCESS') {
        _analytics.track('dues_payment_success', {
          'amount': amount,
          'payment_method': analyticsMethod,
          'payment_type': analyticsType,
          'duration_ms': DateTime.now().difference(paymentStart).inMilliseconds,
        });
        await _refreshAfterPaymentSuccess(purpose);
        state = state.copyWith(
          paymentStep: PaymentStep.success,
          paymentReference: reference,
        );
      } else if (status == 'PENDING') {
        // Still unresolved after the poll bound — leave it in `processing`;
        // [refreshOnResume]'s pending-payment check or the "Check status"
        // affordance on that screen can pick it back up later, and the
        // webhook remains the actual source of truth server-side either way.
      } else {
        _analytics.track('dues_payment_failed', {
          'amount': amount,
          'payment_method': analyticsMethod,
          'payment_type': analyticsType,
          'failure_reason': 'payment_not_successful',
        });
        state = state.copyWith(paymentStep: PaymentStep.idle);
      }
    } catch (_) {
      _analytics.track('dues_payment_failed', {
        'amount': amount,
        'payment_method': analyticsMethod,
        'payment_type': analyticsType,
        'failure_reason': 'exception',
      });
      state = state.copyWith(paymentStep: PaymentStep.idle);
    }
  }

  /// Re-checks a payment left in `processing` — called automatically on
  /// app-resume (the resident may have completed, or abandoned, the
  /// checkout while the app was backgrounded and the poll loop in
  /// [confirmPayment] was suspended by the OS) and from the "Check status"
  /// affordance on the processing screen itself.
  Future<void> checkPendingPaymentStatus() async {
    if (state.paymentStep != PaymentStep.processing) return;
    final reference = state.paymentReference;
    if (reference == null) return;
    try {
      final status = (await _api.verifyPayment(reference))['status'] as String;
      if (status == 'SUCCESS') {
        await _refreshAfterPaymentSuccess(state.pendingPaymentPurpose);
        state = state.copyWith(paymentStep: PaymentStep.success);
      } else if (status != 'PENDING') {
        state = state.copyWith(paymentStep: PaymentStep.idle);
      }
    } catch (_) {
      // Leave it in `processing` — the poll loop or a manual re-check can
      // try again later.
    }
  }

  Future<void> _refreshAfterPaymentSuccess(String purpose) async {
    if (purpose == 'LEVY') {
      final levies = ((await _api.levies())['levies'] as List)
          .map((j) => Levy.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(levies: levies);
    } else {
      final dues = await _api.dues();
      state = state.copyWith(
        duesBalance: dues['balance'] as int,
        duesHistory: (dues['history'] as List)
            .map((j) => DuesEntry.fromJson(j as Map<String, dynamic>))
            .toList(),
      );
    }
  }

  // ── Wallet ────────────────────────────────────────────────────────────
  /// Loaded lazily by the wallet screen itself (not part of bootstrap) —
  /// the balance alone is cheap and already fetched at login, but the full
  /// history is only worth the round-trip once someone actually opens the
  /// screen to look at it.
  Future<void> loadWalletTransactions() async {
    state = state.copyWith(walletTransactionsLoading: true);
    try {
      final json = await _api.walletTransactions();
      final transactions = json
          .map((j) => WalletTransaction.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        walletTransactions: transactions,
        walletTransactionsLoading: false,
      );
    } catch (_) {
      state = state.copyWith(walletTransactionsLoading: false);
    }
  }

  String _walletTopUpError = '';
  String get walletTopUpError => _walletTopUpError;

  /// Funds the wallet via Paystack — unlike [confirmPayment], there's no
  /// "pay with wallet" option here (funding the wallet from itself makes no
  /// sense), so this always goes straight to a real checkout.
  Future<void> fundWallet(int amount) async {
    _walletTopUpError = '';
    state = state.copyWith(walletTopUpStep: WalletTopUpStep.processing);
    try {
      final initiated = await _api.initiatePayment(
        amount: amount,
        purpose: 'WALLET_TOPUP',
        method: 'PAYSTACK',
      );
      final reference = initiated['reference'] as String;
      final authorizationUrl = initiated['authorizationUrl'] as String?;
      if (authorizationUrl != null) {
        try {
          await launchUrl(Uri.parse(authorizationUrl), mode: LaunchMode.externalApplication);
        } catch (_) {
          // No browser available to hand off to — the poll loop below still
          // runs, it just has nothing to eventually report success.
        }
      }

      var status = 'PENDING';
      for (var attempt = 0; attempt < 40 && status == 'PENDING'; attempt++) {
        await Future<void>.delayed(const Duration(seconds: 3));
        status = (await _api.verifyPayment(reference))['status'] as String;
      }

      if (status == 'SUCCESS') {
        final balance = await _api.walletBalance();
        state = state.copyWith(walletBalance: balance, walletTopUpStep: WalletTopUpStep.idle);
        await loadWalletTransactions();
      } else {
        _walletTopUpError = status == 'PENDING'
            ? 'Still waiting for payment confirmation — check your wallet balance shortly.'
            : 'Payment was not completed.';
        state = state.copyWith(walletTopUpStep: WalletTopUpStep.idle);
      }
    } catch (e) {
      _walletTopUpError = extractMessage(e);
      state = state.copyWith(walletTopUpStep: WalletTopUpStep.idle);
    }
  }

  // ── Visitor passes ───────────────────────────────────────────────────
  void resetVisitorForm() =>
      state = state.copyWith(
        vfName: '',
        vfPhone: '',
        vfPlate: '',
        vfError: '',
        vfDuesBlocked: false,
        vfExtraTokenCode: '',
      );
  void onVfName(String v) => state = state.copyWith(vfName: v);
  void onVfPhone(String v) => state = state.copyWith(vfPhone: v);
  void onVfPlate(String v) => state = state.copyWith(vfPlate: v);

  /// Returns the new pass's id on success, or null if it failed. When the
  /// estate charges for tokens past the daily free allowance, the first
  /// attempt fails with an EXTRA_TOKEN_CHARGE code; the page then asks the
  /// resident and calls again with [acceptExtraCharge] true.
  Future<String?> createVisitorPass({bool acceptExtraCharge = false}) async {
    if (state.vfName.trim().isEmpty || state.vfPhone.trim().isEmpty) {
      state = state.copyWith(
        vfError: 'Visitor name and phone number are required.',
        vfDuesBlocked: false,
      );
      return null;
    }
    try {
      final json = await _api.createVisitorPass(
        name: state.vfName.trim(),
        phone: state.vfPhone.trim(),
        plate: state.vfPlate.trim().isEmpty ? null : state.vfPlate.trim(),
        acceptExtraCharge: acceptExtraCharge,
      );
      final pass = VisitorPass.fromJson(json);
      state = state.copyWith(
        visitorPasses: [pass, ...state.visitorPasses],
        vfName: '',
        vfPhone: '',
        vfPlate: '',
        vfError: '',
        vfDuesBlocked: false,
        vfExtraTokenCode: '',
      );
      _analytics.track('visitor_created', {'pass_id': pass.id});
      return pass.id;
    } catch (e) {
      // The estate blocks passes for residents owing too many months of
      // dues — the create page turns this into a "pay your dues" prompt
      // rather than just showing an error line.
      final duesBlocked = extractErrorCode(e) == 'DUES_OUTSTANDING';
      if (duesBlocked) _analytics.track('visitor_blocked_dues');
      final body = extractErrorBody(e);
      final code = extractErrorCode(e);
      final extraToken = code == 'EXTRA_TOKEN_CHARGE' || code == 'EXTRA_TOKEN_INSUFFICIENT_FUNDS';
      state = state.copyWith(
        vfError: extractMessage(e),
        vfDuesBlocked: duesBlocked,
        vfDuesMonthsOwed: (body?['monthsOwed'] as num?)?.toInt() ?? 0,
        vfDuesBalance: (body?['balance'] as num?)?.toInt() ?? 0,
        vfExtraTokenCode: extraToken ? code : '',
        vfExtraTokenPrice: (body?['price'] as num?)?.toInt() ?? 0,
        vfWalletBalance: (body?['walletBalance'] as num?)?.toInt() ?? 0,
      );
      return null;
    }
  }

  /// Revokes a visitor pass. The resident can no longer use this pass code.
  Future<String?> revokeVisitorPass(String id) async {
    try {
      final json = await _api.revokeVisitorPass(id);
      final pass = VisitorPass.fromJson(json);
      state = state.copyWith(
        visitorPasses: [
          for (final p in state.visitorPasses)
            if (p.id == id) pass else p,
        ],
      );
      _analytics.track('visitor_cancelled');
      return null;
    } catch (e) {
      return extractMessage(e);
    }
  }

  // ── Guard ─────────────────────────────────────────────────────────────
  void onGuardCodeChange(String v) {
    final digits = _digitsOnly(v);
    state = state.copyWith(
      guardCode: digits.substring(0, min(6, digits.length)),
    );
  }

  void resetGuardResult() =>
      state = state.copyWith(guardCode: '', guardResult: null);

  /// Returns null on success (the result — matched or not — lands in
  /// `guardResult`), or an error message if the check itself couldn't be
  /// completed (expired session, no connection, server error). Those two
  /// cases must stay distinguishable — collapsing an API failure into
  /// "Code Not Recognized" told guards a perfectly valid code was fake.
  Future<String?> simulateScan() async {
    final code = demoScanCodes[_random.nextInt(demoScanCodes.length)];
    return _verifyCode(code);
  }

  Future<String?> submitGuardCode() async {
    return _verifyCode(state.guardCode);
  }

  Future<String?> _verifyCode(String code) async {
    try {
      final json = await _api.guardVerify(code);
      final passJson = json['pass'] as Map<String, dynamic>?;
      final valid = json['valid'] as bool;
      final reason = json['reason'] as String?;
      state = state.copyWith(
        guardResult: GuardResult(
          pass: passJson == null ? null : VisitorPass.fromJson(passJson),
          valid: valid,
          reason: reason,
        ),
      );
      _analytics.track(valid ? 'gate_access_granted' : 'gate_access_denied', {
        if (reason != null) 'reason': reason,
      });
      return null;
    } catch (e) {
      return extractMessage(e);
    }
  }

  /// Deliberately leaves `guardResult` in state — the caller is still on
  /// the result page while this runs, and clearing it here would flip that
  /// page to its "no pass" (Code Not Recognized) branch before navigation
  /// away has happened. Callers must navigate off the result page first,
  /// then call `resetGuardResult()`.
  Future<void> recordEntry() async {
    final pass = state.guardResult?.pass;
    if (pass == null) return;
    try {
      await _api.recordEntry(pass.id);
      _analytics.track('entry_recorded');
    } catch (_) {
      // Fall through — still refresh the log below.
    }
    await _bootstrapGuardDeduped();
  }

  /// See `recordEntry` — same reasoning for leaving `guardResult` untouched.
  Future<void> recordExit() async {
    final pass = state.guardResult?.pass;
    if (pass == null) return;
    try {
      await _api.recordExit(pass.id);
      _analytics.track('exit_recorded');
    } catch (_) {
      // Fall through — still refresh the log below.
    }
    await _bootstrapGuardDeduped();
  }

  // ── Notifications / polls / rules / complaints ──────────────────────
  /// Picks the spotlight to show at random from all the active ones — called
  /// each time the dashboard is about to pop one up, so when several are
  /// running (e.g. two birthdays on the same day) each gets its turn.
  void shuffleSpotlight() {
    final all = state.spotlights;
    if (all.length < 2) return;
    state = state.copyWith(spotlight: all[Random().nextInt(all.length)]);
  }

  Future<void> loadComplaints() async {
    try {
      final complaints = (await _api.complaints())
          .map((j) => ComplaintItem.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(complaints: complaints);
    } catch (_) {
      // Non-critical — the complaint log just stays empty on failure.
    }
  }

  Future<void> markNotificationsRead() async {
    try {
      await _api.markAllNotificationsRead();
      state = state.copyWith(
        allNotifsRead: true,
        notifications: [
          for (final n in state.notifications)
            NotificationItem(
              id: n.id,
              title: n.title,
              time: n.time,
              type: n.type,
              read: true,
            ),
        ],
      );
    } catch (_) {
      // Non-critical.
    }
  }

  Future<void> refreshPolls() async {
    final polls = (await _api.polls())
        .map((j) => Poll.fromJson(j as Map<String, dynamic>))
        .toList();
    state = state.copyWith(polls: polls);
  }

  Future<String?> votePoll(String pollId, String optionId) async {
    try {
      await _api.vote(pollId: pollId, optionId: optionId);
      _analytics.track('poll_voted', {'poll_id': pollId});
      final polls = (await _api.polls())
          .map((j) => Poll.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(polls: polls);
      return null;
    } catch (e) {
      return extractMessage(e);
    }
  }

  // ── Projects ──────────────────────────────────────────────────────────
  Future<String?> pledge({
    required String projectId,
    required int amount,
  }) async {
    try {
      await _api.pledge(projectId: projectId, amount: amount);
      _analytics.track('pledge_made', {'project_id': projectId, 'amount': amount});
      final myPledges = (await _api.myPledges())
          .map((j) => MyPledge.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(myPledges: myPledges);
      return null;
    } catch (e) {
      return extractMessage(e);
    }
  }

  void resetComplaintForm() => state = state.copyWith(
    complaintDesc: '',
    complaintError: '',
    complaintCategory: 'Maintenance',
  );
  void selectComplaintCategory(String cat) =>
      state = state.copyWith(complaintCategory: cat);
  void onComplaintDesc(String v) => state = state.copyWith(complaintDesc: v);

  /// Returns the generated reference on success, or null if it failed.
  Future<String?> submitComplaint() async {
    if (state.complaintDesc.trim().length < 5) {
      state = state.copyWith(
        complaintError: 'Please describe the issue in a bit more detail.',
      );
      return null;
    }
    try {
      final result = await _api.submitComplaint(
        category: state.complaintCategory,
        description: state.complaintDesc,
      );
      final ref = result['ref'] as String;
      _analytics.track('complaint_submitted', {
        'category': state.complaintCategory,
        'ref': ref,
      });
      state = state.copyWith(complaintRef: ref, complaintError: '');
      await loadComplaints();
      return ref;
    } catch (e) {
      state = state.copyWith(complaintError: extractMessage(e));
      return null;
    }
  }

  // ── Utilities: airtime ───────────────────────────────────────────────

  void resetAirtimeForm() {
    _voiceContext = _VoiceFlow.none;
    state = state.copyWith(
      airtimeNetwork: '',
      airtimePhone: '',
      airtimeAmount: '',
      utilityError: '',
      utilityPaymentMethod: 'PAYSTACK',
    );
  }
  void onAirtimeNetwork(String v) => state = state.copyWith(airtimeNetwork: v);
  void onAirtimePhone(String v) => state = state.copyWith(airtimePhone: v);
  void onAirtimeAmount(String v) => state = state.copyWith(airtimeAmount: v);

  /// Shared by airtime and electricity — 'PAYSTACK' or 'WALLET'.
  void selectUtilityPaymentMethod(String method) =>
      state = state.copyWith(utilityPaymentMethod: method);

  /// For a PAYSTACK-funded utility purchase: tops the wallet up by exactly
  /// the purchase amount via a real Paystack checkout, then the caller
  /// proceeds with the normal wallet-debiting purchase call below. Reuses
  /// [fundWallet] rather than duplicating its checkout-launch/poll logic —
  /// if the vendor purchase then somehow fails, the money is simply sitting
  /// in the wallet rather than lost in a refund limbo.
  Future<bool> _topUpForUtilityPurchase(int amount) async {
    await fundWallet(amount);
    return state.walletTopUpStep == WalletTopUpStep.idle && _walletTopUpError.isEmpty;
  }

  Future<bool> buyAirtime() async {
    final amount = int.tryParse(state.airtimeAmount.trim());
    if (state.airtimeNetwork.isEmpty ||
        state.airtimePhone.trim().isEmpty ||
        amount == null ||
        amount <= 0) {
      state = state.copyWith(
        utilityError:
            'Select a network and enter a valid phone number and amount.',
      );
      return false;
    }
    final method = state.utilityPaymentMethod;
    state = state.copyWith(utilityLoading: true, utilityError: '');
    _analytics.track('airtime_purchase_started', {
      'amount': amount,
      'network': state.airtimeNetwork,
      'payment_method': method.toLowerCase(),
      'entry_point': 'manual',
    });
    if (method == 'PAYSTACK') {
      final funded = await _topUpForUtilityPurchase(amount);
      if (!funded) {
        _analytics.track('airtime_purchase_failed', {
          'amount': amount,
          'network': state.airtimeNetwork,
          'payment_method': 'paystack',
          'failure_reason': 'payment_not_completed',
        });
        state = state.copyWith(
          utilityLoading: false,
          utilityError: _walletTopUpError.isNotEmpty ? _walletTopUpError : 'Payment was not completed.',
        );
        return false;
      }
    }
    try {
      final json = await _api.buyAirtime(
        network: state.airtimeNetwork,
        phone: state.airtimePhone.trim(),
        amount: amount,
      );
      final purchase = UtilityPurchase.fromJson(json);
      // A SUCCESSFUL or PENDING purchase both debit the wallet server-side
      // (see UtilitiesService.finalizePurchase) — refresh so the balance
      // shown next isn't stale.
      final walletBalance = await _api.walletBalance();
      _voiceContext = _VoiceFlow.none;
      final success =
          purchase.status == UtilityPurchaseStatus.successful ||
          purchase.status == UtilityPurchaseStatus.pending;
      _analytics.track(
        success ? 'airtime_purchase_success' : 'airtime_purchase_failed',
        {
          'amount': amount,
          'network': state.airtimeNetwork,
          'payment_method': method.toLowerCase(),
          if (!success && purchase.failureReason != null)
            'failure_reason': purchase.failureReason,
        },
      );
      state = state.copyWith(
        utilityLoading: false,
        lastUtilityPurchase: purchase,
        utilityPurchases: [purchase, ...state.utilityPurchases],
        walletBalance: walletBalance,
      );
      return true;
    } catch (e) {
      _analytics.track('airtime_purchase_failed', {
        'amount': amount,
        'network': state.airtimeNetwork,
        'payment_method': method.toLowerCase(),
        'failure_reason': extractMessage(e),
      });
      state = state.copyWith(utilityLoading: false, utilityError: extractMessage(e));
      return false;
    }
  }

  // ── Utilities: electricity ───────────────────────────────────────────

  /// Used when leaving a step via the header's back arrow — a stale error
  /// from that step (e.g. a failed Verify Meter) shouldn't still be showing
  /// if the resident comes back to it later, or on whichever step they land
  /// on next. Unlike [resetElectricityForm], this leaves the rest of the
  /// form (disco, meter number, etc.) untouched.
  void clearUtilityError() => state = state.copyWith(utilityError: '');

  void resetElectricityForm() {
    _voiceContext = _VoiceFlow.none;
    _pendingMeterChoices = null;
    _pendingMeterChoiceAmount = null;
    state = state.copyWith(
      elecDiscoCode: '',
      elecDiscoName: '',
      elecMeterNumber: '',
      elecMeterType: 'PREPAID',
      elecPhone: '',
      elecAmount: '',
      elecAmountPrefilled: false,
      elecVerifiedName: null,
      elecVerifiedAddress: null,
      utilityError: '',
      utilityPaymentMethod: 'PAYSTACK',
    );
  }

  /// Pre-fills the form from a previously-saved, already-verified meter —
  /// lets a returning resident skip straight to Confirm Details (step 3)
  /// instead of re-picking their provider and re-typing their meter number
  /// every single purchase.
  void useExistingMeter(UtilityMeter meter) => state = state.copyWith(
    elecDiscoCode: meter.discoCode,
    elecDiscoName: meter.discoName,
    elecMeterNumber: meter.meterNumber,
    elecMeterType: meterTypeToJson(meter.meterType),
    elecPhone: '',
    elecAmount: '',
    elecVerifiedName: meter.customerName ?? '',
    elecVerifiedAddress: meter.address,
    utilityError: '',
  );

  /// Voice equivalent of [useExistingMeter] that also already knows the
  /// amount, in one shot — sets [AppState.elecAmountPrefilled] so
  /// `ElectricityConfirmMeterPage`'s Proceed button knows to skip straight
  /// to Payment instead of asking for an amount it already has.
  void applyVoiceElectricityMeter(UtilityMeter meter, int amount) =>
      state = state.copyWith(
        elecDiscoCode: meter.discoCode,
        elecDiscoName: meter.discoName,
        elecMeterNumber: meter.meterNumber,
        elecMeterType: meterTypeToJson(meter.meterType),
        elecPhone: '',
        elecAmount: amount.toString(),
        elecAmountPrefilled: true,
        elecVerifiedName: meter.customerName ?? '',
        elecVerifiedAddress: meter.address,
        utilityError: '',
      );

  /// Voice's "no saved meter" branch — same field-clearing as
  /// [resetElectricityForm] but keeps the already-known amount instead of
  /// wiping it, so the resident isn't asked for it again after typing/
  /// saying their meter number.
  void prefillElectricityAmountOnly(int amount) => state = state.copyWith(
    elecDiscoCode: '',
    elecDiscoName: '',
    elecMeterNumber: '',
    elecMeterType: 'PREPAID',
    elecPhone: '',
    elecAmount: amount.toString(),
    elecAmountPrefilled: true,
    elecVerifiedName: null,
    elecVerifiedAddress: null,
    utilityError: '',
  );

  /// Same as [prefillElectricityAmountOnly] but the provider is already
  /// known too (named in the same utterance as the amount) — used so the
  /// resident isn't asked "which provider?" for something they already said.
  void prefillElectricityDiscoAndAmount(Disco disco, int amount) => state = state.copyWith(
    elecDiscoCode: disco.code,
    elecDiscoName: disco.name,
    elecMeterNumber: '',
    elecMeterType: 'PREPAID',
    elecPhone: '',
    elecAmount: amount.toString(),
    elecAmountPrefilled: true,
    elecVerifiedName: null,
    elecVerifiedAddress: null,
    utilityError: '',
  );

  void onElecDisco(String code, String name) => state = state.copyWith(
    elecDiscoCode: code,
    elecDiscoName: name,
    elecVerifiedName: null,
    elecVerifiedAddress: null,
  );
  void onElecMeterNumber(String v) => state = state.copyWith(
    elecMeterNumber: v,
    elecVerifiedName: null,
    elecVerifiedAddress: null,
  );
  void onElecMeterType(String v) => state = state.copyWith(
    elecMeterType: v,
    elecVerifiedName: null,
    elecVerifiedAddress: null,
  );
  void onElecPhone(String v) => state = state.copyWith(elecPhone: v);
  void onElecAmount(String v) => state = state.copyWith(elecAmount: v);

  /// Verification result is staged onto elecVerifiedName/Address — the meter
  /// itself isn't saved until [buyElectricity] actually goes through, so
  /// backing out of the purchase doesn't leave an unused meter behind.
  Future<bool> verifyElecMeter() async {
    if (state.elecDiscoCode.isEmpty || state.elecMeterNumber.trim().isEmpty) {
      state = state.copyWith(
        utilityError: 'Select your DISCO and enter your meter number.',
      );
      return false;
    }
    state = state.copyWith(utilityLoading: true, utilityError: '');
    try {
      final json = await _api.verifyMeter(
        discoCode: state.elecDiscoCode,
        meterNumber: state.elecMeterNumber.trim(),
        meterType: state.elecMeterType,
      );
      _analytics.track('meter_verified', {
        'disco_code': state.elecDiscoCode,
        'meter_type': state.elecMeterType,
        'success': true,
      });
      state = state.copyWith(
        utilityLoading: false,
        elecVerifiedName: json['customerName'] as String?,
        elecVerifiedAddress: json['address'] as String?,
      );
      return true;
    } catch (e) {
      _analytics.track('meter_verified', {
        'disco_code': state.elecDiscoCode,
        'meter_type': state.elecMeterType,
        'success': false,
      });
      state = state.copyWith(utilityLoading: false, utilityError: extractMessage(e));
      return false;
    }
  }

  Future<bool> buyElectricity() async {
    final amount = int.tryParse(state.elecAmount.trim());
    // No wizard page ever collects a phone number for this flow — fall
    // back to the resident's own account phone rather than requiring one.
    final phone = state.elecPhone.trim().isNotEmpty
        ? state.elecPhone.trim()
        : (state.currentUser?.phone ?? '');
    if (state.elecVerifiedName == null ||
        phone.isEmpty ||
        amount == null ||
        amount < 500) {
      state = state.copyWith(
        utilityError:
            'Verify your meter and enter a valid phone number and amount (min ₦500).',
      );
      return false;
    }
    final method = state.utilityPaymentMethod;
    state = state.copyWith(utilityLoading: true, utilityError: '');
    _analytics.track('electricity_purchase_started', {
      'amount': amount,
      'disco': state.elecDiscoCode,
      'meter_type': state.elecMeterType,
      'payment_method': method.toLowerCase(),
      'entry_point': 'manual',
    });
    if (method == 'PAYSTACK') {
      final funded = await _topUpForUtilityPurchase(amount);
      if (!funded) {
        _analytics.track('electricity_purchase_failed', {
          'amount': amount,
          'disco': state.elecDiscoCode,
          'payment_method': 'paystack',
          'failure_reason': 'payment_not_completed',
        });
        state = state.copyWith(
          utilityLoading: false,
          utilityError: _walletTopUpError.isNotEmpty ? _walletTopUpError : 'Payment was not completed.',
        );
        return false;
      }
    }
    try {
      final meterJson = await _api.saveMeter(
        discoCode: state.elecDiscoCode,
        discoName: state.elecDiscoName,
        meterNumber: state.elecMeterNumber.trim(),
        meterType: state.elecMeterType,
      );
      final meter = UtilityMeter.fromJson(meterJson);
      final purchaseJson = await _api.buyElectricity(
        meterId: meter.id,
        phone: phone,
        amount: amount,
      );
      final purchase = UtilityPurchase.fromJson(purchaseJson);
      final walletBalance = await _api.walletBalance();
      _voiceContext = _VoiceFlow.none;
      final success =
          purchase.status == UtilityPurchaseStatus.successful ||
          purchase.status == UtilityPurchaseStatus.pending;
      _analytics.track(
        success ? 'electricity_purchase_success' : 'electricity_purchase_failed',
        {
          'amount': amount,
          'disco': state.elecDiscoCode,
          'payment_method': method.toLowerCase(),
          if (!success && purchase.failureReason != null)
            'failure_reason': purchase.failureReason,
        },
      );
      state = state.copyWith(
        utilityLoading: false,
        lastUtilityPurchase: purchase,
        utilityPurchases: [purchase, ...state.utilityPurchases],
        utilityMeters: [
          meter,
          for (final m in state.utilityMeters)
            if (m.id != meter.id) m,
        ],
        walletBalance: walletBalance,
        elecAmountPrefilled: false,
      );
      return true;
    } catch (e) {
      _analytics.track('electricity_purchase_failed', {
        'amount': amount,
        'disco': state.elecDiscoCode,
        'payment_method': method.toLowerCase(),
        'failure_reason': extractMessage(e),
      });
      state = state.copyWith(utilityLoading: false, utilityError: extractMessage(e));
      return false;
    }
  }

  // ── Voice assistant ──────────────────────────────────────────────────
  //
  // Voice -> speech-to-text (on-device, via [_speech]) -> a small offline
  // keyword/number parser ([parseVoiceCommand], no LLM) -> for
  // BUY_ELECTRICITY, POST /voice/prepare (the only intent where the
  // backend knows something the client doesn't: the saved meter) -> the
  // result drives the REAL wizard screens via [AppState.voiceNavigationTarget]
  // (consumed by ResidentShell, which does the actual `go()`). A purchase
  // never executes from here — it always ends on the real Pay/Buy Airtime
  // button, gated by [AppState.pendingAuthorizationFor] (biometrics or PIN,
  // see AuthorizationSheet), same as a manual tap would be. Voice is a new
  // front door onto that already-real transaction engine, not a parallel
  // one, and it never accepts a spoken PIN — authorization is always typed.

  Future<void> startVoiceListening() async {
    if (state.voiceStage == VoiceStage.listening) return;
    // initialize() is safe to call repeatedly, but it's a real (if small)
    // async platform-channel round trip each time, so only re-attempt it if
    // it hasn't succeeded yet (including retrying after an earlier
    // failure). The onError callback registered here is persistent for the
    // plugin's whole lifetime, not just this one call —
    // it fires for every later listen() session too, which is exactly why
    // _handleSpeechError has to cope with more than just init-time failures.
    if (!_speechInitialized) {
      _speechInitialized = await _speech.initialize(onError: _handleSpeechError);
    }
    if (!_speechInitialized) {
      state = state.copyWith(
        voiceStage: VoiceStage.error,
        voiceResponse: 'Speech recognition is not available on this device.',
      );
      return;
    }
    state = state.copyWith(voiceStage: VoiceStage.listening, voiceTranscript: '');
    // A meter number is 10-13 digits, often read out slowly digit-by-digit
    // with brief natural pauses between groups — the default pauseFor was
    // cutting that off mid-number and finalizing "meter number is" on its
    // own, before any digits, which then failed to parse as anything. Same
    // condition _handleVoiceTranscript uses to know it's expecting a meter
    // number, so this only relaxes timing further exactly where needed.
    //
    // The general default itself moved from 3s/15s to 5s/25s — real
    // questions ("what were the key decisions made at the meeting held on
    // the 30th of July") have a natural mid-sentence pause (recalling a
    // date, choosing a word) that 3s was finalizing on early, cutting the
    // resident off before they'd finished speaking.
    final awaitingMeterNumber = _voiceContext == _VoiceFlow.electricity &&
        state.elecDiscoCode.isNotEmpty &&
        state.elecVerifiedName == null;
    _analytics.track('voice_listening_started', {
      'voice_mode': awaitingMeterNumber ? 'meter_number' : 'command',
    });
    await _speech.listen(
      onResult: (result) {
        state = state.copyWith(voiceTranscript: result.recognizedWords);
        if (result.finalResult) _handleVoiceTranscript(result.recognizedWords);
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        pauseFor: Duration(seconds: awaitingMeterNumber ? 7 : 5),
        listenFor: Duration(seconds: awaitingMeterNumber ? 30 : 25),
      ),
    );
  }

  /// `error.permanent == false` covers the routine, expected stuff — no
  /// speech detected in the window, a recognition timeout — which is NOT
  /// the same as "can't access the microphone" and shouldn't be shown as
  /// an alarming failure. Only a `permanent` error (denied permission, no
  /// recognizer available) is a real failure.
  void _handleSpeechError(SpeechRecognitionError error) {
    // `permanent` turned out not to mean "real failure" in practice — it's
    // true for the routine end of pretty much any listen() session,
    // including plain silence, since that one session can't be resumed (a
    // fresh listen() call is always needed either way). The actual error
    // code is the reliable signal — only a real permission problem is
    // genuinely "can't access the microphone"; everything else (no speech
    // heard, a timeout, a transient network/server hiccup) isn't a
    // hardware/access failure and shouldn't be shown as one.
    if (error.errorMsg.contains('permission')) {
      _speechInitialized = false;
      state = state.copyWith(
        voiceStage: VoiceStage.error,
        voiceResponse: "Couldn't access the microphone. Check the microphone permission in Settings.",
      );
      return;
    }
    // No speech detected / a routine timeout — just go quiet and wait for
    // the resident to tap the mic again rather than re-arming automatically.
    state = state.copyWith(voiceStage: VoiceStage.idle, voiceResponse: '');
  }

  Future<void> stopVoiceListening() => _speech.stop();

  /// Stops listening and returns to a clean slate — the mic overlay's
  /// dismiss (✕) and the electricity/airtime forms' own reset methods both
  /// route through here (indirectly, via `_voiceContext = none`) so a voice
  /// session never lingers past the flow it was driving.
  void dismissVoice() {
    if (_speech.isListening) _speech.stop();
    unawaited(_tts.stop());
    _voiceContext = _VoiceFlow.none;
    _pendingMeterChoices = null;
    _pendingMeterChoiceAmount = null;
    _pendingDuesBreakdown = false;
    state = state.copyWith(voiceStage: VoiceStage.idle, voiceResponse: '', voiceTranscript: '');
  }

  // ── Assistant voice (TTS) settings ───────────────────────────────────

  /// Without this, [_tts] inherits whatever `AVAudioSession` category
  /// [_speech] (speech_to_text) last set while listening — which is a
  /// *record* category, not a playback one. iOS then silently drops the
  /// synthesizer's audio some of the time instead of erroring, which is
  /// exactly why the assistant's spoken reply was intermittent: it
  /// depended on whatever audio-session state happened to be left over
  /// from the last time the mic was used. Explicitly claiming a playback
  /// category before ever speaking makes every reply audible regardless of
  /// what STT did beforehand. No-ops harmlessly on Android.
  Future<void> _configureTts() async {
    try {
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.duckOthers,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {
      // iOS-only configuration — safe to ignore on platforms/plugin
      // versions where these calls aren't supported.
    }
  }

  /// The one path everything speaks through. [_speech]'s listen() sessions
  /// switch the shared `AVAudioSession` to a record category — re-asserting
  /// the playback category right before every single speak() call (not just
  /// once at startup) is what makes the reply audible every time regardless
  /// of whether the mic was just used.
  Future<void> _speak(String text) async {
    await _configureTts();
    await _tts.stop();
    await _tts.speak(text);
  }

  // ── Meeting report read-aloud ────────────────────────────────────────
  //
  // A meeting report can be several paragraphs — much longer than a normal
  // voice reply — so it gets its own pause/resume rather than the
  // one-shot speak-and-forget [_speak] uses. flutter_tts's own pause() is
  // unreliable across platforms (well-supported on iOS, patchy on
  // Android), so "pause" here just stops playback and remembers how far
  // in [_tts]'s progress handler got; "resume" re-speaks from that same
  // point. That works identically everywhere instead of depending on
  // native pause/resume support.

  Future<void> playMeetingReport(String meetingId, String text) async {
    _reportText = text;
    _reportOffset = 0;
    await _configureTts();
    await _tts.stop();
    _tts.setProgressHandler((text, start, end, word) => _reportOffset = start);
    state = state.copyWith(
      reportPlaybackState: ReportPlaybackState.playing,
      activeReportMeetingId: meetingId,
    );
    await _tts.speak(text);
    _handleReportSpeakSettled(meetingId);
  }

  Future<void> pauseMeetingReport() async {
    if (_reportText == null) return;
    await _tts.stop();
    state = state.copyWith(reportPlaybackState: ReportPlaybackState.paused);
  }

  Future<void> resumeMeetingReport() async {
    final text = _reportText;
    final meetingId = state.activeReportMeetingId;
    if (text == null || meetingId == null) return;
    await _configureTts();
    state = state.copyWith(reportPlaybackState: ReportPlaybackState.playing);
    await _tts.speak(text.substring(_reportOffset.clamp(0, text.length)));
    _handleReportSpeakSettled(meetingId);
  }

  /// `awaitSpeakCompletion(true)` (see [_configureTts]) makes `speak()`'s
  /// own Future resolve whenever speech ends, for *any* reason — including
  /// a deliberate stop() from pause/stop, not just reaching the end of the
  /// text. So finishing speak() only means "read to completion" if nothing
  /// else already moved playback out of "playing" in the meantime (pause
  /// and stop both do that themselves before this ever runs).
  void _handleReportSpeakSettled(String meetingId) {
    if (state.reportPlaybackState == ReportPlaybackState.playing &&
        state.activeReportMeetingId == meetingId) {
      _reportText = null;
      _reportOffset = 0;
      state = state.copyWith(
        reportPlaybackState: ReportPlaybackState.stopped,
        activeReportMeetingId: null,
      );
    }
  }

  Future<void> stopMeetingReport() async {
    await _tts.stop();
    _reportText = null;
    _reportOffset = 0;
    state = state.copyWith(
      reportPlaybackState: ReportPlaybackState.stopped,
      activeReportMeetingId: null,
    );
  }

  Future<void> _restoreSavedVoice() async {
    final saved = await _voiceSettingsStorage.readVoice();
    if (saved == null) return;
    final voice = TtsVoiceOption(name: saved.name, locale: saved.locale);
    try {
      await _tts.setVoice(voice.toVoiceMap());
      state = state.copyWith(selectedVoice: voice);
    } catch (_) {
      // The saved voice may no longer exist on this device (OS update,
      // different device) — fall back silently to the system default
      // rather than surfacing an error for a cosmetic preference.
    }
  }

  /// Lazy — only called when the voice-settings row is actually opened, not
  /// at bootstrap, since most residents will never change this.
  Future<void> loadAvailableVoices() async {
    try {
      final raw = await _tts.getVoices as List<dynamic>;
      final voices = raw
          .cast<Map<dynamic, dynamic>>()
          .map(TtsVoiceOption.fromMap)
          .where((v) => v.locale.toLowerCase().startsWith('en'))
          .toList();
      state = state.copyWith(availableVoices: voices);
    } catch (_) {
      state = state.copyWith(availableVoices: const []);
    }
  }

  Future<void> selectVoice(TtsVoiceOption voice) async {
    await _tts.setVoice(voice.toVoiceMap());
    await _voiceSettingsStorage.setVoice(voice.name, voice.locale);
    state = state.copyWith(selectedVoice: voice);
    await _speak("This is how I'll sound from now on.");
  }

  /// Speaks [message] and stops — the resident taps the mic again if they
  /// want to try once more, rather than the app re-arming itself.
  Future<void> _registerVoiceFailure(String message) async {
    state = state.copyWith(voiceStage: VoiceStage.error, voiceResponse: message);
  }

  // ── Voice interaction logs ───────────────────────────────────────────
  /// Produces a shareable JSON file of every recorded voice turn (see
  /// [VoiceLogEntry]) for offline analysis. Null means there's nothing
  /// logged yet.
  Future<File?> exportVoiceLogs() => _voiceLog.exportForSharing();

  /// Uploads all on-device voice logs to the estate server for central
  /// collection. Returns how many entries were sent.
  Future<int> uploadVoiceLogs() async {
    final entries = await _voiceLog.readAll();
    if (entries.isEmpty) return 0;
    await _api.uploadVoiceLogs(entries.map((e) => e.toJson()).toList());
    return entries.length;
  }

  /// Wraps every spoken turn with logging AND analytics: records the
  /// transcript up front, then once the turn has settled captures the
  /// parser's decision (intent + matched keywords), the assistant's reply,
  /// and any navigation target — one complete VoiceLogEntry plus a Mixpanel
  /// event per interaction. Best-effort: neither may break the voice flow.
  Future<void> _handleVoiceTranscript(String transcript) async {
    _turnParseResult = null;
    _turnLatency..reset()..start();
    _analytics.track('voice_transcript_received', {
      'transcript_length': transcript.length,
      'language': Platform.localeName,
    });
    try {
      await _processVoiceTranscript(transcript);
    } finally {
      final parsed = _turnParseResult;
      final latencyMs = _turnLatency.elapsedMilliseconds;
      if (parsed != null) {
        _analytics.track('voice_intent_detected', {
          'intent': parsed.intent.name,
          'parser_version': kParserVersion,
          'matched_rule': parsed.matchedBy.join(','),
          if (parsed.amount != null) 'amount': parsed.amount!,
          if (parsed.network != null) 'network': parsed.network!,
          if (parsed.month != null) 'month': parsed.month!,
          if (parsed.weekCount != null) 'weekCount': parsed.weekCount!,
        });
      } else {
        _analytics.track('voice_intent_unrecognized', {
          'parser_version': kParserVersion,
          'transcript_length': transcript.length,
        });
      }
      unawaited(_voiceLog.append(VoiceLogEntry(
        timestamp: DateTime.now(),
        transcript: transcript,
        intent: parsed?.intent.name,
        matchedBy: parsed?.matchedBy ?? const [],
        parameters: parsed == null
            ? const {}
            : {
                if (parsed.amount != null) 'amount': parsed.amount!,
                if (parsed.network != null) 'network': parsed.network!,
                if (parsed.month != null) 'month': parsed.month!,
                if (parsed.weekCount != null) 'weekCount': parsed.weekCount!,
                if (parsed.meetingDate != null)
                  'meetingDate': parsed.meetingDate!.toIso8601String(),
              },
        response: state.voiceResponse,
        navigationTarget: state.voiceNavigationTarget,
      )));
      if (state.voiceNavigationTarget != null) {
        _analytics.track('voice_command_executed', {
          'intent': parsed?.intent.name ?? 'none',
          'success': true,
          'duration_ms': latencyMs,
        });
      }
    }
  }

  Future<void> _processVoiceTranscript(String transcript) async {
    final text = transcript.trim();
    if (text.isEmpty) {
      state = state.copyWith(voiceStage: VoiceStage.idle);
      return;
    }
    state = state.copyWith(voiceStage: VoiceStage.processing);

    // Awaiting a yes/no on "would you like a breakdown?" — checked before
    // absolutely everything else, same reasoning as the meter-choice check
    // below: it pre-empts generic parsing entirely for this one turn.
    if (_pendingDuesBreakdown) {
      _pendingDuesBreakdown = false;
      if (looksLikeConfirmation(text)) {
        final payments = state.duesHistory.where((e) => e.type == DuesEntryType.payment);
        final totalPaid = payments.fold<int>(0, (sum, e) => sum + e.amount);
        state = state.copyWith(
          voiceResponse: "You've made ${payments.length} payment${payments.length == 1 ? '' : 's'} "
              'totaling ${formatNaira(totalPaid)}. Your current outstanding balance is '
              "${state.duesBalanceLabel}. Here's the full breakdown.",
          voiceNavigationTarget: '/resident/dues',
        );
      } else {
        state = state.copyWith(voiceStage: VoiceStage.idle, voiceResponse: '');
      }
      return;
    }

    // Awaiting a choice among more than one saved meter — checked before
    // anything else electricity-related, since it pre-empts the normal
    // /voice/prepare round trip entirely (see _resolveElectricityIntent).
    if (_voiceContext == _VoiceFlow.electricity && _pendingMeterChoices != null) {
      if (looksLikeCancellation(text)) {
        // "None of these" / "cancel" here means the meter they want isn't
        // saved yet — same as tapping "Add New Meter" on the select-meter
        // screen — not "abandon the purchase entirely".
        final amount = _pendingMeterChoiceAmount!;
        _pendingMeterChoices = null;
        _pendingMeterChoiceAmount = null;
        resetElectricityForm();
        _voiceContext = _VoiceFlow.electricity;
        prefillElectricityAmountOnly(amount);
        state = state.copyWith(voiceStage: VoiceStage.idle, voiceNavigationTarget: '/resident/electricity');
        return;
      }
      final chosen = matchMeterChoice(text, _pendingMeterChoices!);
      if (chosen != null) {
        final amount = _pendingMeterChoiceAmount!;
        _pendingMeterChoices = null;
        _pendingMeterChoiceAmount = null;
        applyVoiceElectricityMeter(chosen, amount);
        state = state.copyWith(
          voiceStage: VoiceStage.idle,
          voiceResponse: '',
          voiceNavigationTarget: '/resident/electricity/confirm',
        );
        return;
      }
      await _registerVoiceFailure('Sorry, which meter — say the provider name, or tap one below.');
      return;
    }

    // Mid-electricity-flow, awaiting a meter number (a disco's been picked,
    // nothing verified yet) — spoken digits go straight into the field and
    // auto-trigger verification, same as tapping "Verify Meter" would. The
    // resident taps the mic again to speak the yes/no that follows on the
    // Confirm screen.
    if (_voiceContext == _VoiceFlow.electricity &&
        state.elecDiscoCode.isNotEmpty &&
        state.elecVerifiedName == null) {
      final digits = extractDigitsOnly(text);
      if (digits != null) {
        onElecMeterNumber(digits);
        final verified = await verifyElecMeter();
        if (verified) {
          state = state.copyWith(
            voiceStage: VoiceStage.idle,
            voiceResponse: '',
            voiceNavigationTarget: '/resident/electricity/confirm',
          );
        } else {
          await _registerVoiceFailure("I couldn't verify that meter. Please say it again.");
        }
        return;
      }
      // Not digits (e.g. "cancel") — fall through to generic handling below.
    }

    // Mid-electricity-flow, awaiting the meter-confirm yes/no — a spoken
    // "yes" behaves exactly like tapping Proceed, "no" like "Not this meter?".
    if (_voiceContext == _VoiceFlow.electricity &&
        state.elecVerifiedName != null &&
        state.elecAmount.trim().isNotEmpty) {
      if (looksLikeConfirmation(text)) {
        final amount = int.tryParse(state.elecAmount.trim()) ?? 0;
        final skipToPayment = state.elecAmountPrefilled && amount >= 500;
        _voiceContext = _VoiceFlow.none;
        state = state.copyWith(
          voiceStage: VoiceStage.idle,
          voiceResponse: '',
          voiceNavigationTarget: skipToPayment
              ? '/resident/electricity/payment'
              : '/resident/electricity/amount',
          pendingAuthorizationFor: skipToPayment ? 'electricity' : null,
        );
        return;
      }
      if (looksLikeCancellation(text)) {
        final amount = state.elecAmount;
        resetElectricityForm();
        _voiceContext = _VoiceFlow.electricity;
        prefillElectricityAmountOnly(int.tryParse(amount.trim()) ?? 0);
        state = state.copyWith(voiceStage: VoiceStage.idle, voiceNavigationTarget: '/resident/electricity');
        return;
      }
      state = state.copyWith(voiceStage: VoiceStage.idle, voiceResponse: 'Sorry, was that a yes or a no?');
      return;
    }

    // Mid-electricity-flow, awaiting a spoken DISCO (amount is already
    // known — this is the "no saved meter" branch — but no provider has
    // been picked yet, so meter entry can't start).
    if (_voiceContext == _VoiceFlow.electricity &&
        state.elecDiscoCode.isEmpty &&
        state.elecVerifiedName == null &&
        state.elecAmount.trim().isNotEmpty) {
      if (looksLikeCancellation(text)) {
        dismissVoice();
        return;
      }
      final disco = extractDisco(text, state.discos);
      if (disco != null) {
        onElecDisco(disco.code, disco.name);
        state = state.copyWith(
          voiceStage: VoiceStage.idle,
          voiceResponse: '',
          voiceNavigationTarget: '/resident/electricity/meter',
        );
        return;
      }
      await _registerVoiceFailure('Sorry, which provider — for example Ikeja Electric or Eko Electric?');
      return;
    }

    // Mid-electricity-flow, still waiting on an amount (BUY_ELECTRICITY was
    // recognized but no meter lookup has happened yet).
    if (_voiceContext == _VoiceFlow.electricity &&
        state.elecDiscoCode.isEmpty &&
        state.elecVerifiedName == null &&
        state.elecAmount.trim().isEmpty) {
      if (looksLikeCancellation(text)) {
        dismissVoice();
        return;
      }
      final amount = parseVoiceCommand(text)?.amount ?? extractAmount(text);
      if (amount != null) {
        await _resolveElectricityIntent(amount, disco: extractDisco(text, state.discos));
        return;
      }
      await _registerVoiceFailure('Sorry, how much electricity would you like to buy?');
      return;
    }

    // Mid-airtime-flow — corrections fill the real screen's fields live;
    // once everything needed is known, a confirmation utterance authorizes.
    if (_voiceContext == _VoiceFlow.airtime) {
      if (looksLikeCancellation(text)) {
        resetAirtimeForm();
        state = state.copyWith(voiceStage: VoiceStage.idle, voiceResponse: '');
        return;
      }
      final amount = extractAmount(text);
      final network = extractNetwork(text);
      if (amount != null) onAirtimeAmount(amount.toString());
      if (network != null) onAirtimeNetwork(network);
      final readyToConfirm = state.airtimeNetwork.isNotEmpty &&
          state.airtimePhone.trim().isNotEmpty &&
          (int.tryParse(state.airtimeAmount.trim()) ?? 0) > 0;
      if (readyToConfirm && looksLikeConfirmation(text)) {
        _voiceContext = _VoiceFlow.none;
        state = state.copyWith(
          voiceStage: VoiceStage.idle,
          voiceResponse: '',
          pendingAuthorizationFor: 'airtime',
        );
        return;
      }
      if (amount != null || network != null) {
        state = state.copyWith(voiceStage: VoiceStage.idle, voiceResponse: '');
        return;
      }
      // Neither a correction nor "confirm" — fall through to generic
      // handling below (lets a resident pivot to an unrelated command).
    }

    // Generic top-level intent recognition.
    final parsed = parseVoiceCommand(text);
    _turnParseResult = parsed;
    if (parsed == null) {
      await _registerVoiceFailure(
        'Sorry, I didn\'t understand that. Try "buy electricity" or "what\'s my balance".',
      );
      return;
    }
    switch (parsed.intent) {
      case VoiceIntent.buyElectricity:
        resetElectricityForm();
        _voiceContext = _VoiceFlow.electricity;
        await _resolveElectricityIntent(parsed.amount, disco: extractDisco(text, state.discos));
      case VoiceIntent.buyAirtime:
        _startAirtimeVoice(amount: parsed.amount, network: parsed.network);
      case VoiceIntent.checkBalance:
        await _answerReadOnlyVoiceIntent('CHECK_BALANCE');
      case VoiceIntent.transactionHistory:
        await _answerReadOnlyVoiceIntent('TRANSACTION_HISTORY');
      case VoiceIntent.fundWallet:
        await _answerFundWallet();
      case VoiceIntent.checkDues:
        await _answerCheckDues();
      case VoiceIntent.duesMonthsPaid:
        await _answerDuesMonthsPaid();
      case VoiceIntent.electricitySpendByMonth:
        await _answerElectricitySpendByMonth(parsed.month);
      case VoiceIntent.nextMeeting:
        await _answerNextMeeting();
      case VoiceIntent.lastMeetingReport:
        await _answerLastMeetingReport(text, parsed.meetingDate);
      case VoiceIntent.meetingDecisions:
        await _answerMeetingDecisions(text, parsed.meetingDate);
      case VoiceIntent.meetingActionItems:
        await _answerMeetingActionItems(text, parsed.meetingDate);
      case VoiceIntent.visitorCount:
        await _answerVisitorCount(parsed.weekCount);
      case VoiceIntent.newUpdates:
        await _answerNewUpdates();
    }
  }

  /// Speaks the dues balance and asks whether the resident wants a
  /// breakdown — the answer only comes (and only then does this navigate
  /// anywhere) once `_pendingDuesBreakdown`'s check at the top of
  /// [_handleVoiceTranscript] sees the follow-up yes/no.
  Future<void> _answerCheckDues() async {
    _pendingDuesBreakdown = true;
    // Levies are a separate concept from dues (one-off named charges), but
    // "what are my outstanding levies" routes here too (see the parser) —
    // mention them so that phrasing gets a complete answer, not just dues.
    final unpaidLevies = state.levies.where((l) => l.status == LevyStatus.unpaid).toList();
    final leviesClause = unpaidLevies.isEmpty
        ? ''
        : ' You also have ${unpaidLevies.length} unpaid ${unpaidLevies.length == 1 ? 'levy' : 'levies'} '
            'totaling ${formatNaira(unpaidLevies.fold<int>(0, (sum, l) => sum + l.amount))}.';
    state = state.copyWith(
      voiceStage: VoiceStage.idle,
      voiceResponse:
          'You currently owe ${state.duesBalanceLabel} in estate dues.$leviesClause Would you like a breakdown?',
    );
  }

  Future<void> _answerDuesMonthsPaid() async {
    _showTerminalResponse(
      "You've paid dues for ${state.duesMonthsPaid} month${state.duesMonthsPaid == 1 ? '' : 's'} this year.",
      navigateTo: '/resident/dues',
    );
  }

  static const _monthLabels = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  Future<void> _answerElectricitySpendByMonth(int? month) async {
    final resolvedMonth = month ?? DateTime.now().month;
    final year = DateTime.now().year;
    final total = state.utilityPurchases
        .where((p) =>
            p.type == 'ELECTRICITY' &&
            p.status == UtilityPurchaseStatus.successful &&
            p.createdAt.month == resolvedMonth &&
            p.createdAt.year == year)
        .fold<int>(0, (sum, p) => sum + p.amount);
    state = state.copyWith(
      voiceStage: VoiceStage.idle,
      voiceResponse: 'You spent ${formatNaira(total)} on electricity in ${_monthLabels[resolvedMonth - 1]}.',
      voiceNavigationTarget: '/resident/utility-history',
      historyFilterMonth: resolvedMonth,
      historyFilterYear: year,
    );
  }

  Future<void> _answerNextMeeting() async {
    final upcoming = state.meetings.where((m) => m.scheduledAt.isAfter(DateTime.now())).toList();
    if (upcoming.isEmpty) {
      _showTerminalResponse('You have no upcoming meetings scheduled.');
    } else {
      final next = upcoming.first;
      _showTerminalResponse(
        'Your next meeting is "${next.title}" on ${next.date} at ${next.time}, ${next.location}.',
        navigateTo: '/resident/meetings/${next.id}',
      );
    }
  }

  /// The most recent meeting whose scheduled time has already passed —
  /// shared by every "what happened at the last meeting"-style voice
  /// answer. `null` means no past meeting exists at all yet.
  Meeting? _lastPastMeeting() {
    final past = state.meetings.where((m) => m.scheduledAt.isBefore(DateTime.now())).toList();
    return past.isEmpty ? null : past.last;
  }

  /// A meeting named by a specific calendar date (see
  /// [extractMeetingDate]) — compared in local time, since that's how a
  /// resident thinks of "the meeting held on the 30th", not UTC. `null`
  /// means no meeting is scheduled on that date at all.
  Meeting? _meetingOnDate(DateTime date) {
    for (final m in state.meetings) {
      final local = m.scheduledAt.toLocal();
      if (local.year == date.year && local.month == date.month && local.day == date.day) {
        return m;
      }
    }
    return null;
  }

  // Generic words that show up in nearly every meeting title/query and so
  // shouldn't count as evidence of a match — same idea as
  // extractDisco/matchMeterChoice's own stop-word filtering elsewhere in
  // the voice pipeline.
  static const _meetingTitleStopWords = {
    'meeting', 'the', 'a', 'held', 'on', 'at', 'in', 'of', 'for',
    'last', 'next', 'general', 'committee',
  };

  /// A meeting named by (part of) its title rather than a date — "the
  /// security committee meeting", "the landscaping meeting" — so a
  /// resident doesn't have to remember or say an exact date. Scored by how
  /// many of the title's distinctive words appear in the utterance; ties
  /// and zero matches both return null (too ambiguous to guess).
  Meeting? _meetingByTitle(String text) {
    final t = text.toLowerCase();
    Meeting? best;
    var bestScore = 0;
    for (final m in state.meetings) {
      final words = m.title
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty && !_meetingTitleStopWords.contains(w));
      final score = words.where(t.contains).length;
      if (score > bestScore) {
        bestScore = score;
        best = m;
      }
    }
    return best;
  }

  /// The meeting a voice question is actually about — checked in order: a
  /// named date (see [extractMeetingDate]), then a named title (see
  /// [_meetingByTitle]), falling back to the most recent past meeting when
  /// neither is mentioned — shared by all three "what happened at [the/
  /// that] meeting"-style voice answers below.
  Meeting? _resolveTargetMeeting(String text, DateTime? targetDate) {
    if (targetDate != null) {
      final byDate = _meetingOnDate(targetDate);
      if (byDate != null) return byDate;
    }
    return _meetingByTitle(text) ?? _lastPastMeeting();
  }

  /// Reads the secretary's actual report verbatim — never an AI
  /// interpretation of it — for either the meeting on [targetDate] (if the
  /// resident named one) or the most recent meeting that's already
  /// happened. [state.meetings] only carries list-summary fields, so the
  /// report text itself is fetched fresh from the detail endpoint.
  Future<void> _answerLastMeetingReport(String text, DateTime? targetDate) async {
    final meeting = _resolveTargetMeeting(text, targetDate);
    if (meeting == null) {
      _showTerminalResponse("You don't have any past meetings recorded yet.");
      return;
    }
    state = state.copyWith(voiceStage: VoiceStage.idle, voiceNavigationTarget: '/resident/meetings/${meeting.id}');
    try {
      final detail = await _api.meeting(meeting.id);
      final report = (detail['report'] as String?)?.trim();
      if (report == null || report.isEmpty) {
        await _speak('The meeting "${meeting.title}" on ${meeting.date} has no report added yet.');
        return;
      }
      await _speak(
        'The meeting on ${meeting.date} — here is the report documented by the secretary.',
      );
      await playMeetingReport(meeting.id, report);
    } catch (e) {
      await _speak("Sorry, I couldn't load the meeting report right now.");
    }
  }

  /// These two never call an LLM — they just fetch whatever
  /// `MeetingsService.get()` already computed once, offline, when the
  /// report was submitted (see Meeting.aiDecisions/aiActionItems), and are
  /// withheld entirely by the backend until an admin approves them. If the
  /// question also names one of that meeting's topics (e.g. "what was
  /// decided about security"), only matching entries are read back instead
  /// of the whole list.
  Future<void> _answerMeetingDecisions(String text, DateTime? targetDate) async {
    final meeting = _resolveTargetMeeting(text, targetDate);
    if (meeting == null) {
      _showTerminalResponse("You don't have any past meetings recorded yet.");
      return;
    }
    try {
      final detail = await _api.meeting(meeting.id);
      final decisions = (detail['aiDecisions'] as List).cast<String>();
      if (decisions.isEmpty) {
        _showTerminalResponse(
          'No decisions have been recorded for that meeting yet.',
          navigateTo: '/resident/meetings/${meeting.id}',
        );
        return;
      }
      final topics = (detail['aiTopics'] as List).cast<String>();
      // Excludes a topic word that's also part of the meeting's own title
      // (e.g. "security" in "the security committee meeting") — naming
      // which meeting to ask about isn't the same as asking to filter its
      // decisions/action items down to that one topic, and treating it as
      // one wrongly narrowed a plain "what were the decisions" down to
      // nothing just because the resident named the meeting by title.
      final topic = topics.firstWhere(
        (t) => text.toLowerCase().contains(t) && !meeting.title.toLowerCase().contains(t),
        orElse: () => '',
      );
      final matching = topic.isEmpty
          ? decisions
          : decisions.where((d) => d.toLowerCase().contains(topic)).toList();
      if (matching.isEmpty) {
        _showTerminalResponse(
          "I didn't find a decision about that at that meeting.",
          navigateTo: '/resident/meetings/${meeting.id}',
        );
        return;
      }
      final intro = topic.isEmpty
          ? "Here's what was decided at the ${meeting.title}:"
          : 'Regarding $topic, the meeting resolved:';
      _showTerminalResponse('$intro ${matching.join(' ')}', navigateTo: '/resident/meetings/${meeting.id}');
    } catch (e) {
      _showTerminalResponse("Sorry, I couldn't load the meeting decisions right now.");
    }
  }

  Future<void> _answerMeetingActionItems(String text, DateTime? targetDate) async {
    final meeting = _resolveTargetMeeting(text, targetDate);
    if (meeting == null) {
      _showTerminalResponse("You don't have any past meetings recorded yet.");
      return;
    }
    try {
      final detail = await _api.meeting(meeting.id);
      final actionItems = (detail['aiActionItems'] as List).cast<String>();
      if (actionItems.isEmpty) {
        _showTerminalResponse(
          'No action items have been recorded for that meeting yet.',
          navigateTo: '/resident/meetings/${meeting.id}',
        );
        return;
      }
      final topics = (detail['aiTopics'] as List).cast<String>();
      // Excludes a topic word that's also part of the meeting's own title
      // (e.g. "security" in "the security committee meeting") — naming
      // which meeting to ask about isn't the same as asking to filter its
      // decisions/action items down to that one topic, and treating it as
      // one wrongly narrowed a plain "what were the decisions" down to
      // nothing just because the resident named the meeting by title.
      final topic = topics.firstWhere(
        (t) => text.toLowerCase().contains(t) && !meeting.title.toLowerCase().contains(t),
        orElse: () => '',
      );
      final matching = topic.isEmpty
          ? actionItems
          : actionItems.where((a) => a.toLowerCase().contains(topic)).toList();
      if (matching.isEmpty) {
        _showTerminalResponse(
          "I didn't find an action item about that at that meeting.",
          navigateTo: '/resident/meetings/${meeting.id}',
        );
        return;
      }
      final intro = topic.isEmpty ? 'Here are the action items from the ${meeting.title}:' : 'On $topic:';
      _showTerminalResponse('$intro ${matching.join(' ')}', navigateTo: '/resident/meetings/${meeting.id}');
    } catch (e) {
      _showTerminalResponse("Sorry, I couldn't load the meeting action items right now.");
    }
  }

  Future<void> _answerVisitorCount(int? weekCount) async {
    final weeks = weekCount ?? 1;
    final since = DateTime.now().subtract(Duration(days: 7 * weeks));
    // enteredAt is when the visitor actually arrived, not createdAt (when
    // the pass was merely issued) — a resident could issue a pass that's
    // never used, which shouldn't count as "having had" that visitor.
    final count = state.visitorPasses.where((p) => p.enteredAt?.isAfter(since) ?? false).length;
    _showTerminalResponse(
      'You\'ve had $count visitor${count == 1 ? '' : 's'} in the past $weeks week${weeks == 1 ? '' : 's'}.',
      navigateTo: '/resident/visitor',
    );
  }

  Future<void> _answerNewUpdates() async {
    final unread = state.announcements.where((a) => a.unread).length;
    final speech = state.announcements.isEmpty
        ? 'No new updates right now.'
        : unread > 0
            ? 'You have $unread new update${unread == 1 ? '' : 's'}. The latest is: ${state.announcements.first.title}.'
            : 'No new updates — the latest was: ${state.announcements.first.title}.';
    _showTerminalResponse(speech, navigateTo: '/resident/announcements');
  }

  void clearHistoryFilter() => state = state.copyWith(historyFilterMonth: null, historyFilterYear: null);

  /// Calls /voice/prepare for BUY_ELECTRICITY — the one intent where the
  /// backend knows something the client doesn't (the saved meter). Branches
  /// three ways: still missing an amount (asks and waits for the resident
  /// to tap the mic again), a meter was resolved (jump to Confirm,
  /// pre-filled), or none exists (jump to the start of the wizard, keeping
  /// the amount so it's never asked twice).
  ///
  /// [disco] is whatever [extractDisco] found in the SAME utterance that
  /// gave the amount (e.g. "500 naira from IBEDC") — a resident who names a
  /// specific provider is never assumed to mean whichever meter happens to
  /// be saved, even if there's only one. It takes priority over both the
  /// single-saved-meter shortcut and the multi-meter "which one?" question.
  Future<void> _resolveElectricityIntent(int? amount, {Disco? disco}) async {
    _voiceContext = _VoiceFlow.electricity;
    if (amount != null && disco != null) {
      final matchingMeter = state.utilityMeters
          .cast<UtilityMeter?>()
          .firstWhere((m) => m?.discoCode == disco.code, orElse: () => null);
      if (matchingMeter != null) {
        applyVoiceElectricityMeter(matchingMeter, amount);
        state = state.copyWith(
          voiceStage: VoiceStage.idle,
          voiceResponse: '',
          voiceNavigationTarget: '/resident/electricity/confirm',
        );
      } else {
        // Named a provider with no saved meter on it — the provider is
        // already known, so skip straight to entering a meter number
        // instead of also asking "which provider?".
        prefillElectricityDiscoAndAmount(disco, amount);
        state = state.copyWith(
          voiceStage: VoiceStage.idle,
          voiceResponse: '',
          voiceNavigationTarget: '/resident/electricity/meter',
        );
      }
      return;
    }
    // More than one saved meter — a resident is never assumed to mean "the"
    // meter, so ask which one instead of letting the backend silently pick
    // its own most-recent fallback (only reachable once the amount is
    // actually known, otherwise this would ask before the amount question).
    if (amount != null && state.utilityMeters.length > 1) {
      _pendingMeterChoices = state.utilityMeters;
      _pendingMeterChoiceAmount = amount;
      state = state.copyWith(
        voiceStage: VoiceStage.idle,
        voiceResponse: 'Which meter would you like to use?',
        voiceNavigationTarget: '/resident/electricity/select-meter',
      );
      return;
    }
    try {
      final result = await _api.voicePrepare(intent: 'BUY_ELECTRICITY', amount: amount);
      final speech = result['speech'] as String? ?? '';

      if (result['needsClarification'] != null) {
        state = state.copyWith(voiceStage: VoiceStage.idle, voiceResponse: speech);
        return;
      }
      if (result['needsConfirmation'] == true) {
        final command = result['command'] as Map<String, dynamic>?;
        final meterId = command?['meterId'] as String?;
        final resolvedAmount = command?['amount'] as int? ?? amount ?? 0;
        final meter = state.utilityMeters
            .cast<UtilityMeter?>()
            .firstWhere((m) => m?.id == meterId, orElse: () => null);
        if (meter != null) {
          applyVoiceElectricityMeter(meter, resolvedAmount);
          state = state.copyWith(
            voiceStage: VoiceStage.idle,
            voiceResponse: '',
            voiceNavigationTarget: '/resident/electricity/confirm',
          );
        } else {
          prefillElectricityAmountOnly(resolvedAmount);
          state = state.copyWith(
            voiceStage: VoiceStage.idle,
            voiceResponse: '',
            voiceNavigationTarget: '/resident/electricity',
          );
        }
        return;
      }
      // ok:false — no saved meter at all (client already knows this from
      // utilityMeters, more reliable than matching the backend's message
      // text) is a "start the wizard" case; anything else (e.g.
      // insufficient balance) is a flat, terminal rejection.
      if (state.utilityMeters.isEmpty && amount != null) {
        prefillElectricityAmountOnly(amount);
        state = state.copyWith(
          voiceStage: VoiceStage.idle,
          voiceResponse: speech,
          voiceNavigationTarget: '/resident/electricity',
        );
        return;
      }
      _voiceContext = _VoiceFlow.none;
      await _registerVoiceFailure(speech);
    } catch (e) {
      _voiceContext = _VoiceFlow.none;
      await _registerVoiceFailure(extractMessage(e));
    }
  }

  /// BUY_AIRTIME resolves fully client-side — the real endpoint already
  /// validates everything server-side, so there's no round trip before
  /// landing on the real screen with whatever's already known filled in.
  void _startAirtimeVoice({int? amount, String? network}) {
    _voiceContext = _VoiceFlow.airtime;
    state = state.copyWith(
      airtimeNetwork: network ?? '',
      airtimePhone: state.currentUser?.phone ?? '',
      airtimeAmount: amount != null ? amount.toString() : '',
      utilityError: '',
      voiceStage: VoiceStage.idle,
      voiceResponse: '',
      voiceNavigationTarget: '/resident/airtime',
    );
  }

  /// CHECK_BALANCE/TRANSACTION_HISTORY both answer AND land the resident on
  /// the real transactions screen — voice isn't just a talking speaker here,
  /// it's a front door onto the same page a tap would reach.
  /// Backs both CHECK_BALANCE and TRANSACTION_HISTORY — both are wallet
  /// concepts server-side (see VoiceService), so both hand off to the
  /// wallet screen, which shows the balance and the full history together
  /// rather than splitting them across two destinations.
  Future<void> _answerReadOnlyVoiceIntent(String intentApi) async {
    try {
      final result = await _api.voicePrepare(intent: intentApi);
      _showTerminalResponse(
        result['speech'] as String? ?? '',
        navigateTo: '/resident/wallet',
      );
    } catch (e) {
      await _registerVoiceFailure(extractMessage(e));
    }
  }

  /// "How do I fund my wallet" and similar — purely a hand-off to the
  /// wallet screen (where the actual "Fund Wallet" action lives), no
  /// backend round-trip needed.
  Future<void> _answerFundWallet() async {
    _showTerminalResponse(
      'Sure — here\'s your wallet. You can fund it from here.',
      navigateTo: '/resident/wallet',
    );
  }

  /// Shows a spoken/text answer that isn't itself a real-screen hand-off
  /// (unlike the electricity/airtime flows, which clear voiceResponse the
  /// instant they navigate) — and clears it a few seconds later so it
  /// doesn't linger on screen indefinitely. Guarded so a newer response or
  /// stage change in the meantime isn't clobbered.
  void _showTerminalResponse(String message, {String? navigateTo}) {
    state = state.copyWith(
      voiceStage: VoiceStage.idle,
      voiceResponse: message,
      voiceNavigationTarget: navigateTo,
    );
    Future.delayed(const Duration(seconds: 6), () {
      if (state.voiceResponse == message && state.voiceStage == VoiceStage.idle) {
        state = state.copyWith(voiceResponse: '');
      }
    });
  }

  void clearVoiceNavigationTarget() => state = state.copyWith(voiceNavigationTarget: null);

  /// Set by voice OR by the real Pay/Buy Airtime buttons — ResidentShell is
  /// the single consumer, so both paths run through identical authorization
  /// + execution + navigation logic.
  void requestAuthorization(String kind) =>
      state = state.copyWith(pendingAuthorizationFor: kind);

  void clearPendingAuthorization() => state = state.copyWith(pendingAuthorizationFor: null);

  /// Used by AuthorizationSheet's biometric branch — distinct from
  /// [unlockWithBiometrics] (which additionally flips authStage): this one
  /// only proves presence for a single purchase.
  Future<bool> authenticateForPurchase() async {
    // Same spurious-resume risk as unlockWithBiometrics: without this
    // guard, a resident with app-lock biometrics enabled would find the
    // app locking itself mid-purchase, right as this prompt closes.
    _biometricPromptActive = true;
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Confirm this purchase',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    } finally {
      _biometricPromptActive = false;
    }
  }

  Future<bool> setTransactionPin(String pin) async {
    try {
      await _api.setPin(pin);
      final user = CurrentUser.fromJson(await _api.me());
      state = state.copyWith(currentUser: user);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyTransactionPin(String pin) async {
    try {
      return await _api.verifyPin(pin);
    } catch (_) {
      return false;
    }
  }
}

final appStateProvider = StateNotifierProvider<AppNotifier, AppState>(
  (ref) => AppNotifier(
    MyCoveApi(),
    const TokenStorage(),
    const EstateStorage(),
    ref,
    const BiometricStorage(),
  ),
);
