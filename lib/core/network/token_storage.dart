import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps secure storage so platform-level read/write failures (a flaky
/// Keychain/Keystore, or no plugin binding at all in widget tests) degrade
/// to "not persisted" instead of crashing the app.
class TokenStorage {
  const TokenStorage();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _storage = FlutterSecureStorage();

  Future<String?> read() => _readKey(_accessKey);
  Future<void> save(String token) => _writeKey(_accessKey, token);

  Future<String?> readRefreshToken() => _readKey(_refreshKey);
  Future<void> saveRefreshToken(String token) => _writeKey(_refreshKey, token);

  Future<void> clear() async {
    await Future.wait([_deleteKey(_accessKey), _deleteKey(_refreshKey)]);
  }

  Future<String?> _readKey(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeKey(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // Best-effort — this session still works even if the token can't
      // be persisted across restarts.
    }
  }

  Future<void> _deleteKey(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      // Best-effort.
    }
  }
}
