import 'dart:io';

import 'package:dio/dio.dart';
import 'token_storage.dart';

/// iOS Simulator shares the Mac's localhost, so it reaches the API
/// directly. Android emulators don't — 10.0.2.2 is the standard alias an
/// Android emulator uses to reach the host machine's localhost.
String get _baseUrl => Platform.isAndroid ? 'http://10.0.2.2:3000/api' : 'http://localhost:3000/api';

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
  late final Dio dio;

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
