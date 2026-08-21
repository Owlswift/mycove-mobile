import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists which estate this install has been set up for, so the
/// estate-code screen only ever shows once per install rather than on
/// every launch.
class EstateStorage {
  const EstateStorage();

  static const _codeKey = 'estate_code';
  static const _nameKey = 'estate_name';
  static const _addressKey = 'estate_address';
  static const _imageKey = 'estate_image';
  static const _lockedKey = 'estate_locked';
  static const _storage = FlutterSecureStorage();

  Future<String?> readCode() => _readKey(_codeKey);
  Future<String?> readName() => _readKey(_nameKey);
  Future<String?> readAddress() => _readKey(_addressKey);

  /// This estate's own photo, as the same base64 data URL the backend
  /// returns — cached here on confirm so every screen that shows it
  /// (login, dashboard, onboarding) reads the real photo for *this*
  /// estate instead of a generic placeholder, without refetching it.
  Future<String?> readImage() => _readKey(_imageKey);

  /// Whether this device has actually authenticated against the saved
  /// estate (login, onboarding, or password reset) rather than just having
  /// entered/confirmed an estate code.
  Future<bool> readLocked() async => (await _readKey(_lockedKey)) == 'true';

  Future<void> markLocked() => _writeKey(_lockedKey, 'true');

  Future<void> save({
    required String code,
    required String name,
    String? address,
    String? image,
  }) async {
    await Future.wait([
      _writeKey(_codeKey, code),
      _writeKey(_nameKey, name),
      if (address != null)
        _writeKey(_addressKey, address)
      else
        _deleteKey(_addressKey),
      if (image != null)
        _writeKey(_imageKey, image)
      else
        _deleteKey(_imageKey),
    ]);
  }

  Future<void> clear() async {
    await Future.wait([
      _deleteKey(_codeKey),
      _deleteKey(_nameKey),
      _deleteKey(_addressKey),
      _deleteKey(_imageKey),
      _deleteKey(_lockedKey),
    ]);
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
