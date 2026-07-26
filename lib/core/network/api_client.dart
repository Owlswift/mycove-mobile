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
          if (error.response?.statusCode == 401) {
            await _tokenStorage.clear();
          }
          return handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();

  final _tokenStorage = const TokenStorage();
  late final Dio dio;
}
