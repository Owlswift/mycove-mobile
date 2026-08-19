import 'dart:convert';

/// Reads the `jti` claim out of a JWT's payload segment without verifying
/// its signature — used only to compare "is this the session I'm running
/// on" for display, never for anything security-sensitive (the backend is
/// the one actually enforcing/verifying tokens).
String? jwtJti(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final normalized = base64Url.normalize(parts[1]);
    final payload =
        jsonDecode(utf8.decode(base64Url.decode(normalized)))
            as Map<String, dynamic>;
    return payload['jti'] as String?;
  } catch (_) {
    return null;
  }
}
