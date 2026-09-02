import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'api_exception.dart';
import 'estate_storage.dart';
import 'token_storage.dart';

const _redactedKeys = {
  'password',
  'newPassword',
  'pin',
  'accessToken',
  'refreshToken',
  'resetToken',
};

Object? _redact(Object? data) {
  if (data is Map) {
    return data.map(
      (k, v) => MapEntry(k, _redactedKeys.contains(k) ? '[redacted]' : v),
    );
  }
  return data;
}

bool _isMutating(String method) => method == 'POST' || method == 'PUT';

/// Logs every mutating request/response/error (POST/PUT only — the
/// actions that actually change something; GETs are excluded on purpose,
/// they're too frequent — the resident/guard bootstrap alone fires ~17 of
/// them — to be useful noise here) to the console (`flutter logs` / Xcode
/// console / `adb logcat`). Headers' Authorization value is redacted,
/// request/response bodies have password-shaped fields redacted. Left
/// permanently on: this is a native mobile app console, not something an
/// end user (or a browser devtools tab) ever sees.
class _VerboseLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isMutating(options.method)) {
      developer.log(
        '--> ${options.method} ${options.uri}\n'
        '    headers: ${options.headers.map((k, v) => MapEntry(k, k.toLowerCase() == 'authorization' ? '[redacted]' : v))}\n'
        '    body: ${jsonEncode(_redact(options.data))}',
        name: 'ApiClient',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_isMutating(response.requestOptions.method)) {
      developer.log(
        '<-- ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}\n'
        '    body: ${jsonEncode(_redact(response.data))}',
        name: 'ApiClient',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_isMutating(err.requestOptions.method)) {
      developer.log(
        '<-- ERROR ${err.type} ${err.requestOptions.method} ${err.requestOptions.uri}\n'
        '    message: ${err.message}\n'
        '    response status: ${err.response?.statusCode}\n'
        '    response body: ${err.response?.data}',
        name: 'ApiClient',
        level: 1000,
      );
    }
    handler.next(err);
  }
}

/// A release build (`flutter build`/`flutter run --release`, i.e. the only
/// way a binary reaches a real user's device) ALWAYS talks to production,
/// no matter what — this is unconditional, deliberately ignoring even an
/// `API_BASE_URL` override, so there is no way to accidentally ship a
/// binary wired to a developer's laptop.
///
/// A debug/profile run (a simulator, or `flutter run` during local
/// development) instead defaults to the LOCAL backend — `npm run
/// start:dev` in mycove-api, listening on 0.0.0.0:3000 — since that's what
/// you're almost always testing against day to day. On the iOS Simulator
/// `localhost` reaches the Mac directly; the Android emulator needs
/// `10.0.2.2` instead (its alias for the host machine), handled below.
///
/// Override either default with `--dart-define` when you need to:
/// - A physical device in debug mode can't reach `localhost` — point it at
///   your Mac's LAN IP instead (`ipconfig getifaddr en0`):
///   flutter run --dart-define=API_BASE_URL=http://192.168.100.175:3000/api
/// - To debug-test against production instead of local:
///   flutter run --dart-define=API_BASE_URL=https://api.mycove.ng/api
/// - For remote testers without LAN access, a Cloudflare quick tunnel:
///   cloudflared tunnel --url http://localhost:3000
///   flutter run --dart-define=API_BASE_URL=https://`<tunnel-host>`/api
const _baseUrlOverride = String.fromEnvironment('API_BASE_URL');
const _productionUrl = 'https://api.mycove.ng/api';

String get _localDefaultUrl => Platform.isAndroid
    ? 'http://10.0.2.2:3000/api'
    : 'http://localhost:3000/api';

String get _baseUrl {
  if (kReleaseMode) return _productionUrl;
  if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
  return _localDefaultUrl;
}

class ApiClient {
  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        // 10s was cutting it too close: right after login the resident/
        // guard bootstrap fires ~17 requests concurrently, and on a modest
        // production VM under real network conditions (as opposed to
        // simulator-over-localhost) that burst can genuinely take longer
        // than 10s for the slowest of them to come back — especially with
        // cold DB connections right after a fresh login. That showed up as
        // a receiveTimeout DioException, which extractMessage (see
        // api_exception.dart) didn't even have a specific message for, so
        // it silently fell through to a useless "Something went wrong."
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    dio.interceptors.add(_VerboseLogInterceptor());

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.read();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // A revoked/deactivated account is a dead end, not a "try to
          // refresh" case — the resident (or guard) may no longer belong
          // to this estate at all, so the local session and the
          // remembered estate both get wiped. This check runs first and
          // unconditionally (even for /auth/login and /auth/refresh
          // themselves) so it's caught however it's discovered: a live
          // in-app request, a silent background refresh, or a fresh
          // login attempt.
          if (extractErrorCode(error) == 'ACCOUNT_DEACTIVATED') {
            await _tokenStorage.clear();
            await _estateStorage.clear();
            onAccountDeactivated?.call();
            return handler.next(error);
          }

          // Only the genuinely unauthenticated /auth/* endpoints skip
          // retry — they establish identity themselves and never carried a
          // Bearer token that could be stale in the first place. Every
          // *other* /auth/* endpoint (complete-force-reset, logout,
          // sessions, pin/set, pin/verify) DOES require a valid access
          // token and can go just as stale as any non-auth endpoint — e.g.
          // a resident who spends a few minutes filling out the force-reset
          // profile form past the 15-minute access-token lifetime must
          // still get the same silent-refresh-and-retry treatment,
          // otherwise "Save & Continue" fails with a raw "Invalid token"
          // instead of quietly refreshing and succeeding.
          const noRetryPaths = {
            '/auth/login',
            '/auth/forgot-password',
            '/auth/verify-otp',
            '/auth/reset-password',
            '/auth/refresh',
          };
          final skipsRetry = noRetryPaths.contains(error.requestOptions.path);
          final alreadyRetried =
              error.requestOptions.extra['retriedAfterRefresh'] == true;
          if (error.response?.statusCode != 401 ||
              skipsRetry ||
              alreadyRetried) {
            return handler.next(error);
          }

          final newAccessToken = await _refreshAccessToken();
          if (newAccessToken == null) {
            await _tokenStorage.clear();
            return handler.next(error);
          }

          try {
            final retryOptions = error.requestOptions;
            retryOptions.extra['retriedAfterRefresh'] = true;
            retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            final response = await dio.fetch<dynamic>(retryOptions);
            return handler.resolve(response);
          } catch (_) {
            return handler.next(error);
          }
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();

  final _tokenStorage = const TokenStorage();
  final _estateStorage = const EstateStorage();
  late final Dio dio;

  /// Set by AppNotifier so it can react in-memory (route back to the
  /// estate-code screen) the instant a deactivation is detected, instead
  /// of only taking effect on the next app launch.
  void Function()? onAccountDeactivated;

  Future<String?>? _refreshing;

  /// Shared across concurrent 401s so a burst of requests (e.g. the
  /// resident bootstrap's `Future.wait` of 9 calls) triggers exactly one
  /// refresh instead of racing to rotate the same refresh token N times.
  Future<String?> _refreshAccessToken() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) return null;
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data!;
      final newAccessToken = data['accessToken'] as String;
      await _tokenStorage.save(newAccessToken);
      await _tokenStorage.saveRefreshToken(data['refreshToken'] as String);
      return newAccessToken;
    } catch (_) {
      return null;
    }
  }
}
