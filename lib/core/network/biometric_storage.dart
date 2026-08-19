import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists whether this install has opted into biometric unlock, so the
/// lock screen only shows up for residents who turned it on.
class BiometricStorage {
  const BiometricStorage();

  static const _enabledKey = 'biometric_enabled';
  static const _storage = FlutterSecureStorage();

  Future<bool> readEnabled() async => (await _readKey(_enabledKey)) == 'true';

  Future<void> setEnabled(bool value) =>
      _writeKey(_enabledKey, value.toString());

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
      // Best-effort — worst case biometric lock silently stays off.
    }
  }
}
