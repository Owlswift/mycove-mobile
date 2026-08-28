import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Persists a snapshot of `AppState`'s data-domain fields (announcements,
/// meetings, dues, etc. — NOT auth/tokens/form fields, see AppNotifier's
/// `_cacheSnapshot`/`_hydrateFromCache`) as a JSON file in the app's
/// documents directory, following the same convention as
/// `lib/core/voice/voice_log_storage.dart` — plain file rather than secure
/// storage since this is cached read data, not a credential, and every
/// operation is best-effort so a cache failure can never break the app.
///
/// This is deliberately generic (`Map<String, dynamic>` in/out) rather than
/// coupled to `AppState` itself — encoding/decoding the actual state shape
/// is `AppNotifier`'s job, keeping this a dumb read/write layer.
class AppStateCache {
  static const _fileName = 'app_state_cache.json';

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<Map<String, dynamic>?> read() async {
    try {
      final file = await _file;
      if (!await file.exists()) return null;
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      // Corrupt or unreadable cache — treat as no cache rather than crash.
      return null;
    }
  }

  Future<void> write(Map<String, dynamic> snapshot) async {
    try {
      final file = await _file;
      await file.writeAsString(jsonEncode(snapshot));
    } catch (_) {
      // Best-effort — a failed cache write must never break the app.
    }
  }

  Future<void> clear() async {
    try {
      final file = await _file;
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best-effort.
    }
  }
}
