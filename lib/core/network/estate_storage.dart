import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists which estate this install has been set up for, so the
/// estate-code screen only ever shows once per install rather than on
/// every launch.
class EstateStorage {
  const EstateStorage();

  static const _codeKey = 'estate_code';
  static const _nameKey = 'estate_name';
  static const _storage = FlutterSecureStorage();

  Future<String?> readCode() => _readKey(_codeKey);
  Future<String?> readName() => _readKey(_nameKey);

  Future<void> save({required String code, required String name}) async {
    await Future.wait([_writeKey(_codeKey, code), _writeKey(_nameKey, name)]);
  }

  Future<void> clear() async {
    await Future.wait([_deleteKey(_codeKey), _deleteKey(_nameKey)]);
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
      // Best-effort — this session still works even if it can't be
      // persisted across restarts, it'll just ask for the code again.
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
