import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/network/biometric_storage.dart';
import '../core/network/estate_storage.dart';
import '../core/network/jwt_decode.dart';
import '../core/network/token_storage.dart';
import '../core/push/push_service.dart';
import '../data/community_hub_api.dart';
import '../data/models/access_log_entry.dart';
import '../data/models/announcement.dart';
import '../data/models/complaint_item.dart';
import '../data/models/dues_entry.dart';
import '../data/models/levy.dart';
import '../data/models/meeting.dart';
import '../data/models/my_pledge.dart';
import '../data/models/notification_item.dart';
import '../data/models/person.dart';
import '../data/models/poll.dart';
import '../data/models/project.dart';
import '../data/models/rules_section.dart';
import '../data/models/session_info.dart';
import '../data/models/spotlight.dart';
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
    _bootstrap();
  }

  final CommunityHubApi _api;
  final TokenStorage _tokenStorage;
  final EstateStorage _estateStorage;
  final BiometricStorage _biometricStorage;
  final Ref _ref;
  final _random = Random();
  final _localAuth = LocalAuthentication();

  /// Gate on a validated estate code before anything else — this app is
  /// shared across estates, so a fresh install doesn't know which estate's
  /// backend data it should even be logging into. Once an estate has been
  /// validated once, it's remembered and this step is skipped on future
  /// launches (see submitEstateCode).
  Future<void> _bootstrap() async {
    unawaited(_checkBiometricAvailability());
    final estateName = await _estateStorage.readName();
    // TEMP: diagnostic only
    print('[DIAG] estateName=$estateName');
    if (estateName == null) {
      state = state.copyWith(authStage: AuthStage.welcome);
      return;
    }
    final estateAddress = await _estateStorage.readAddress();
    final estateLocked = await _estateStorage.readLocked();
    // TEMP: diagnostic only
    print('[DIAG] estateLocked=$estateLocked');
    state = state.copyWith(
      estateName: estateName,
      estateAddress: estateAddress,
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
        pendingEstateManagedBy: result['managedBy'] as String?,
        pendingEstateResidentCount: result['residentCount'] as int?,
        authStage: AuthStage.estateFound,
      );
    } catch (e) {
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
    await _estateStorage.save(code: code, name: name, address: address);
    state = state.copyWith(
      estateName: name,
      estateAddress: address,
      pendingEstateCode: null,
      pendingEstateName: null,
      pendingEstateAddress: null,
      pendingEstateManagedBy: null,
      pendingEstateResidentCount: null,
    );
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
    // TEMP: diagnostic only
    print('[DIAG] accessToken present=${token != null}');
    if (token == null) {
      state = state.copyWith(authStage: AuthStage.login);
      return;
    }
    try {
      final user = CurrentUser.fromJson(await _api.me());
      final role = _roleFromApi(user.role);
      state = state.copyWith(
        currentUser: user,
        role: role,
        estateName: user.estateName ?? state.estateName,
        estateAddress: user.estateAddress ?? state.estateAddress,
      );
      if (user.role == 'GUARD') {
        await _bootstrapGuard();
      } else {
        await _bootstrapResident();
      }
      await _enterApp();
      unawaited(_registerPushToken());
      // TEMP: diagnostic only
      print('[DIAG] auto-login succeeded');
    } catch (e) {
      // TEMP: diagnostic only
      print('[DIAG] auto-login FAILED: $e');
      await _tokenStorage.clear();
      state = state.copyWith(authStage: AuthStage.login);
    }
  }

  /// Data is already loaded by the time this runs (called after bootstrap)
  /// — biometric lock, when enabled, sits in front of an already-ready app
  /// rather than blocking the data fetch behind it.
  Future<void> _enterApp() async {
    final biometricEnabled = await _biometricStorage.readEnabled();
    state = state.copyWith(
      authStage: biometricEnabled ? AuthStage.locked : AuthStage.app,
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
    try {
      final (platform, deviceName) = await _deviceInfo();
      final result = await _api.login(
        phone: _digitsOnly(state.loginPhone),
        password: state.loginPassword,
        role: _roleToApi(state.role),
        platform: platform,
        deviceName: deviceName,
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
        state = state.copyWith(
          authStage: AuthStage.forceReset,
          setupFullName: user.fullName,
          setupHouse: user.house ?? '',
          setupEmail: user.email ?? '',
          setupEmergencyContactName: user.emergencyContactName ?? '',
          setupEmergencyContactPhone: user.emergencyContactPhone ?? '',
          setupVehiclePlates: user.vehiclePlates.join(', '),
        );
        return;
      }
      if (user.role == 'GUARD') {
        await _bootstrapGuard();
      } else {
        await _bootstrapResident();
      }
      // Straight to `app`, not through the biometric lock — typing the
      // password just now already was the authentication event. The lock
      // only guards *silent* session restoration (see _tryAutoLogin).
      state = state.copyWith(
        authStage: AuthStage.app,
        biometricEnabled: await _biometricStorage.readEnabled(),
      );
      unawaited(_registerPushToken());
    } catch (e) {
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
      state = state.copyWith(
        authStage: AuthStage.otp,
        isLoading: false,
        devOtp: result['devOtp'] as String?,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, resetMsg: extractMessage(e));
    }
  }

  void onOtpChange(String v) {
    final digits = _digitsOnly(v);
    state = state.copyWith(otpCode: digits.substring(0, min(6, digits.length)));
  }

  Future<void> verifyOtp() async {
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
      state = state.copyWith(
        authStage: AuthStage.newPassword,
        resetToken: result['resetToken'] as String,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, resetMsg: extractMessage(e));
    }
  }

  void onNewPass1(String v) => state = state.copyWith(newPass1: v);
  void onNewPass2(String v) => state = state.copyWith(newPass2: v);
  void onSetupFullName(String v) => state = state.copyWith(setupFullName: v);
  void onSetupHouse(String v) => state = state.copyWith(setupHouse: v);
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
    if (state.setupHouse.trim().isEmpty) {
      state = state.copyWith(resetMsg: 'House address is required.');
      return;
    }
    state = state.copyWith(isLoading: true, resetMsg: '');
    try {
      final plates = state.setupVehiclePlates
          .split(',')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
      await _api.completeForceReset(
        newPassword: state.newPass1,
        fullName: state.setupFullName.trim(),
        house: state.setupHouse.trim(),
        email: state.setupEmail.trim().isEmpty ? null : state.setupEmail.trim(),
        emergencyContactName: state.setupEmergencyContactName.trim().isEmpty
            ? null
            : state.setupEmergencyContactName.trim(),
        emergencyContactPhone: state.setupEmergencyContactPhone.trim().isEmpty
            ? null
            : state.setupEmergencyContactPhone.trim(),
        vehiclePlates: plates,
      );

      // The role driving which bootstrap runs is whatever the admin set
      // this account up as — not assumed to always be a resident, since
      // guard accounts can need first-time setup too.
      final role = state.currentUser?.role == 'GUARD'
          ? Role.guard
          : Role.resident;
      if (role == Role.guard) {
        await _bootstrapGuard();
      } else {
        await _bootstrapResident();
      }
      // Data's already loaded (bootstrap just ran above) — the success
      // screen sits in front of an app that's ready to go the moment
      // finishOnboarding flips authStage to app, same as the biometric
      // lock screen does for a silently-restored session.
      state = state.copyWith(
        authStage: AuthStage.onboardingComplete,
        role: role,
        newPass1: '',
        newPass2: '',
        resetMsg: '',
        isLoading: false,
      );
    } catch (e) {
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
    state = AppState(
      authStage: AuthStage.login,
      biometricAvailable: state.biometricAvailable,
      estateName: state.estateName,
      estateAddress: state.estateAddress,
      estateLocked: state.estateLocked,
    );
  }

  /// Pull-to-refresh for any resident list screen — re-runs the same
  /// batched fetch bootstrap used at login, so every screen it feeds stays
  /// in sync with whatever it refetches.
  Future<void> refreshResident() => _bootstrapResident();

  /// Pull-to-refresh for the guard access-log screen — re-runs the same
  /// fetch bootstrap used at guard login, so the log stays in sync with
  /// whatever it refetches.
  Future<void> refreshGuard() => _bootstrapGuard();

  /// Re-fetches whenever the app comes back to the foreground (opened from
  /// the app switcher, or from tapping a push notification) — otherwise the
  /// screen just shows whatever was last fetched, possibly stale by then.
  /// No-ops outside the logged-in app state (e.g. mid-login) since there's
  /// nothing to refresh yet.
  Future<void> refreshOnResume() async {
    if (state.authStage != AuthStage.app) return;
    if (state.biometricEnabled) {
      state = state.copyWith(authStage: AuthStage.locked);
      return;
    }
    if (state.role == Role.guard) {
      await _bootstrapGuard();
    } else {
      await _bootstrapResident();
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
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Unlock CommunityHub',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!ok) return false;
      state = state.copyWith(authStage: AuthStage.app);
      if (state.role == Role.guard) {
        await _bootstrapGuard();
      } else {
        await _bootstrapResident();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Called from the profile toggle — requires a successful auth right
  /// then, before persisting the flag, so turning it on always proves the
  /// device's biometrics actually work for this user.
  Future<bool> enableBiometrics() async {
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Confirm to enable biometric unlock',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!ok) return false;
      await _biometricStorage.setEnabled(true);
      state = state.copyWith(biometricEnabled: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> disableBiometrics() async {
    await _biometricStorage.setEnabled(false);
    state = state.copyWith(biometricEnabled: false);
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
      _api.currentSpotlight(),
      _api.myPledges(),
    ]);

    final announcements = (results[0] as List)
        .map((j) => Announcement.fromJson(j as Map<String, dynamic>))
        .toList();
    final meetings = (results[1] as List)
        .map((j) => Meeting.fromJson(j as Map<String, dynamic>))
        .toList();
    final dues = results[2] as Map<String, dynamic>;
    final levies = (results[3] as List)
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
    final spotlightJson = results[9] as Map<String, dynamic>?;
    final spotlight = spotlightJson == null
        ? null
        : Spotlight.fromJson(spotlightJson);
    final myPledges = (results[10] as List)
        .map((j) => MyPledge.fromJson(j as Map<String, dynamic>))
        .toList();

    state = state.copyWith(
      announcements: announcements,
      meetings: meetings,
      duesBalance: dues['balance'] as int,
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
      myPledges: myPledges,
    );
  }

  Future<void> _bootstrapGuard() async {
    final accessLog = (await _api.accessLog())
        .map((j) => AccessLogEntry.fromJson(j as Map<String, dynamic>))
        .toList();
    state = state.copyWith(accessLog: accessLog);
  }

  // ── Meetings ──────────────────────────────────────────────────────────
  Future<void> addToCalendar(String id) => _api.addToCalendar(id);

  // ── Announcements ────────────────────────────────────────────────────
  Future<void> openAnnouncement(String id) async {
    try {
      await _api.markAnnouncementRead(id);
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
  void resetPayment() => state = state.copyWith(
    paymentStep: PaymentStep.idle,
    paymentReference: null,
  );

  Future<void> confirmPayment() async {
    state = state.copyWith(paymentStep: PaymentStep.processing);
    try {
      final amount = state.duesBalance;
      final initiated = await _api.initiatePayment(
        amount: amount,
        purpose: 'DUES',
      );
      final reference = initiated['reference'] as String;

      var status = 'PENDING';
      for (var attempt = 0; attempt < 5 && status == 'PENDING'; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        status = (await _api.verifyPayment(reference))['status'] as String;
      }

      if (status == 'SUCCESS') {
        final dues = await _api.dues();
        state = state.copyWith(
          paymentStep: PaymentStep.success,
          paymentReference: reference,
          duesBalance: dues['balance'] as int,
          duesHistory: (dues['history'] as List)
              .map((j) => DuesEntry.fromJson(j as Map<String, dynamic>))
              .toList(),
        );
      } else {
        state = state.copyWith(paymentStep: PaymentStep.idle);
      }
    } catch (_) {
      state = state.copyWith(paymentStep: PaymentStep.idle);
    }
  }

  Future<String?> payLevy(String id) async {
    try {
      await _api.payLevy(id);
      final levies = (await _api.levies())
          .map((j) => Levy.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(levies: levies);
      return null;
    } catch (e) {
      return extractMessage(e);
    }
  }

  // ── Visitor passes ───────────────────────────────────────────────────
  void resetVisitorForm() =>
      state = state.copyWith(vfName: '', vfPhone: '', vfPlate: '', vfError: '');
  void onVfName(String v) => state = state.copyWith(vfName: v);
  void onVfPhone(String v) => state = state.copyWith(vfPhone: v);
  void onVfPlate(String v) => state = state.copyWith(vfPlate: v);

  /// Returns the new pass's id on success, or null if it failed.
  Future<String?> createVisitorPass() async {
    if (state.vfName.trim().isEmpty || state.vfPhone.trim().isEmpty) {
      state = state.copyWith(
        vfError: 'Visitor name and phone number are required.',
      );
      return null;
    }
    try {
      final json = await _api.createVisitorPass(
        name: state.vfName.trim(),
        phone: state.vfPhone.trim(),
        plate: state.vfPlate.trim().isEmpty ? null : state.vfPlate.trim(),
      );
      final pass = VisitorPass.fromJson(json);
      state = state.copyWith(
        visitorPasses: [pass, ...state.visitorPasses],
        vfName: '',
        vfPhone: '',
        vfPlate: '',
        vfError: '',
      );
      return pass.id;
    } catch (e) {
      state = state.copyWith(vfError: extractMessage(e));
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
      state = state.copyWith(
        guardResult: GuardResult(
          pass: passJson == null ? null : VisitorPass.fromJson(passJson),
          valid: json['valid'] as bool,
          reason: json['reason'] as String?,
        ),
      );
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
    } catch (_) {
      // Fall through — still refresh the log below.
    }
    await _bootstrapGuard();
  }

  /// See `recordEntry` — same reasoning for leaving `guardResult` untouched.
  Future<void> recordExit() async {
    final pass = state.guardResult?.pass;
    if (pass == null) return;
    try {
      await _api.recordExit(pass.id);
    } catch (_) {
      // Fall through — still refresh the log below.
    }
    await _bootstrapGuard();
  }

  // ── Notifications / polls / rules / complaints ──────────────────────
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
      state = state.copyWith(complaintRef: ref, complaintError: '');
      await loadComplaints();
      return ref;
    } catch (e) {
      state = state.copyWith(complaintError: extractMessage(e));
      return null;
    }
  }
}

final appStateProvider = StateNotifierProvider<AppNotifier, AppState>(
  (ref) => AppNotifier(
    CommunityHubApi(),
    const TokenStorage(),
    const EstateStorage(),
    ref,
    const BiometricStorage(),
  ),
);
