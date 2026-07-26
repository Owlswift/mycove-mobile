import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps secure storage so platform-level read/write failures (a flaky
/// Keychain/Keystore, or no plugin binding at all in widget tests) degrade
/// to "not persisted" instead of crashing the app.
class TokenStorage {
  const TokenStorage();

  static const _key = 'access_token';
  static const _storage = FlutterSecureStorage();

  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String token) async {
    try {
      await _storage.write(key: _key, value: token);
    } catch (_) {
      // Best-effort — this session still works even if the token can't
      // be persisted across restarts.
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      // Best-effort.
    }
  }
}
