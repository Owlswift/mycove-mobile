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
    // The request reached the server and started a response, but it took
    // too long to finish (or too long to send, for a large upload) — a
    // real, distinct case from "never connected at all" above. Previously
    // fell through to the generic fallback below, which hid a genuine
    // slow-server/slow-network condition behind a useless message.
    if (error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'The server is taking longer than expected to respond. Please try again.';
    }
  }
  return 'Something went wrong. Please try again.';
}

/// The raw JSON error body, for callers that need fields beyond
/// `message`/`code` (e.g. the amount owed on a `DUES_OUTSTANDING` refusal).
Map<String, dynamic>? extractErrorBody(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) return Map<String, dynamic>.from(data);
  }
  return null;
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
