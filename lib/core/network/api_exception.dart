import 'package:dio/dio.dart';

/// NestJS's default exception filter returns `{statusCode, message, error}`;
/// `message` is a `List<String>` for class-validator DTO failures and a
/// plain `String` for everything else (thrown `HttpException`s).
String extractMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'];
      if (message is List) return message.join(', ');
      return message.toString();
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection and try again.';
    }
  }
  return 'Something went wrong. Please try again.';
}

/// Machine-readable error identifier some 401s carry alongside `message`
/// (e.g. `ACCOUNT_DEACTIVATED`) — for reacting programmatically, where
/// matching on human-readable message text would be fragile.
String? extractErrorCode(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['code'] != null) return data['code'].toString();
  }
  return null;
}
