import 'package:dio/dio.dart';
import 'api_exception.dart';
import 'estate_storage.dart';
import 'token_storage.dart';

/// Defaults to the real production API (Oracle Cloud) so a release build
/// only ever talks to it by accident-proof default — a build/run
/// forgetting to pass an override must never end up shipping a binary
/// wired to a developer's laptop. For LOCAL DEV, override with your Mac's
/// LAN IP instead (update it when the Mac's DHCP lease changes —
/// `ipconfig getifaddr en0` — `npm run start:dev` in mycove-api listens
/// on 0.0.0.0:3000):
/// flutter run --dart-define=API_BASE_URL=http://192.168.100.175:3000/api
/// For remote testers without LAN access, use a Cloudflare quick tunnel
/// instead:
/// cloudflared tunnel --url http://localhost:3000
/// flutter run --dart-define=API_BASE_URL=https://`<tunnel-host>`/api
const _baseUrlOverride = String.fromEnvironment('API_BASE_URL');
const _productionUrl = 'https://api.mycove.ng/api';

String get _baseUrl {
  if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
  return _productionUrl;
}

class ApiClient {
  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

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

          final isAuthEndpoint = error.requestOptions.path.startsWith('/auth/');
          final alreadyRetried = error.requestOptions.extra['retriedAfterRefresh'] == true;
          if (error.response?.statusCode != 401 || isAuthEndpoint || alreadyRetried) {
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
