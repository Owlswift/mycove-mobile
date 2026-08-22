import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the resident's chosen text-to-speech voice (name + locale, the
/// two fields `flutter_tts`'s `setVoice` needs) — null means "no preference
/// set yet, use whatever the device's default TTS voice is."
class VoiceSettingsStorage {
  const VoiceSettingsStorage();

  static const _nameKey = 'tts_voice_name';
  static const _localeKey = 'tts_voice_locale';
  static const _storage = FlutterSecureStorage();

  Future<({String name, String locale})?> readVoice() async {
    final name = await _readKey(_nameKey);
    final locale = await _readKey(_localeKey);
    if (name == null || locale == null) return null;
    return (name: name, locale: locale);
  }

  Future<void> setVoice(String name, String locale) async {
    await _writeKey(_nameKey, name);
    await _writeKey(_localeKey, locale);
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
      // Best-effort — worst case the voice choice isn't remembered.
    }
  }
}
