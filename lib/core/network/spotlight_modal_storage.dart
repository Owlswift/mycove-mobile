import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tracks how many times the Spotlight image popup has already been shown
/// on this device today, so it can be capped at [maxPerDay] instead of
/// nagging the resident on every single app open. The counter resets itself
/// the first time it's checked on a new calendar day.
class SpotlightModalStorage {
  const SpotlightModalStorage();

  static const maxPerDay = 3;

  static const _dateKey = 'spotlight_modal_date';
  static const _countKey = 'spotlight_modal_count';
  static const _storage = FlutterSecureStorage();

  Future<bool> shouldShow() async {
    final today = _today();
    final storedDate = await _readKey(_dateKey);
    if (storedDate != today) return true;
    final count = int.tryParse(await _readKey(_countKey) ?? '') ?? 0;
    return count < maxPerDay;
  }

  Future<void> recordShown() async {
    final today = _today();
    final storedDate = await _readKey(_dateKey);
    final priorCount = storedDate == today
        ? (int.tryParse(await _readKey(_countKey) ?? '') ?? 0)
        : 0;
    await _writeKey(_dateKey, today);
    await _writeKey(_countKey, '${priorCount + 1}');
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
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
      // Best-effort — worst case the popup just shows a bit more than
      // intended on this device.
    }
  }
}
