import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// One recorded voice-assistant turn — the full decision trail the offline
/// analysis loop needs:
///
/// ```text
/// Transcript → Parser result → Intent selected → Parameters extracted
///            → Matched rule(s) → Assistant response → Navigation target
/// ```
///
/// Batches of these are periodically reviewed (by hand or with an LLM) to
/// find misclassifications, repeated STT variants ("owing"→"going",
/// "debt"→"date"), confused intents, and false-positive rules — which then
/// become reviewed, tested parser changes rather than silent auto-edits.
class VoiceLogEntry {
  const VoiceLogEntry({
    required this.timestamp,
    required this.transcript,
    this.intent,
    this.matchedBy = const [],
    this.parameters = const {},
    this.response,
    this.navigationTarget,
  });

  final DateTime timestamp;
  /// The raw speech-to-text output exactly as recognized — mishearings and
  /// all. This is the most valuable field: it's what residents *actually*
  /// say (or what the recognizer thought they said).
  final String transcript;
  /// The intent the parser selected, or null when nothing matched (the
  /// "Sorry, I didn't understand" path).
  final String? intent;
  /// Which keyword(s) fired for [intent] — the parser's explanation of its
  /// choice. Empty for unparsed turns.
  final List<String> matchedBy;
  /// Extracted parameters (amount, network, month, weekCount, meetingDate).
  final Map<String, Object?> parameters;
  /// What the assistant replied (or was about to reply) after this turn.
  final String? response;
  /// Where the assistant navigated, if the turn drove navigation.
  final String? navigationTarget;

  Map<String, Object?> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'transcript': transcript,
    'intent': intent,
    'matchedBy': matchedBy,
    'parameters': parameters,
    'response': response,
    'navigationTarget': navigationTarget,
  };

  factory VoiceLogEntry.fromJson(Map<String, Object?> json) => VoiceLogEntry(
    timestamp: DateTime.parse(json['timestamp']! as String),
    transcript: json['transcript']! as String,
    intent: json['intent'] as String?,
    matchedBy: ((json['matchedBy'] as List?) ?? const []).cast<String>(),
    parameters: ((json['parameters'] as Map?) ?? const {}).cast<String, Object?>(),
    response: json['response'] as String?,
    navigationTarget: json['navigationTarget'] as String?,
  );
}

/// Persists voice-turn logs as a JSON file in the app's documents directory.
///
/// A file (rather than secure storage) because these logs exist to be
/// exported — share_plus shares a file directly, no re-encoding needed.
/// Capped at [maxEntries] (newest kept) so it can't grow unbounded on a
/// resident's device; every write is best-effort so logging can never break
/// the voice flow itself.
class VoiceLogStorage {
  static const maxEntries = 500;
  static const _fileName = 'voice_interaction_logs.json';

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<VoiceLogEntry>> readAll() async {
    try {
      final file = await _file;
      if (!await file.exists()) return [];
      final decoded = jsonDecode(await file.readAsString()) as List<dynamic>;
      return decoded
          .map((e) => VoiceLogEntry.fromJson((e as Map).cast<String, Object?>()))
          .toList();
    } catch (_) {
      // Corrupt or unreadable log — start fresh rather than failing.
      return [];
    }
  }

  Future<void> append(VoiceLogEntry entry) async {
    try {
      final entries = await readAll();
      entries.add(entry);
      final trimmed = entries.length > maxEntries
          ? entries.sublist(entries.length - maxEntries)
          : entries;
      final file = await _file;
      await file.writeAsString(jsonEncode(trimmed.map((e) => e.toJson()).toList()));
    } catch (_) {
      // Best-effort — logging must never break the voice flow.
    }
  }

  /// Writes a fresh export copy (timestamped name) into the temp directory
  /// and returns it — ready to hand straight to share_plus. Null means the
  /// export couldn't be produced (or there's nothing to export).
  Future<File?> exportForSharing() async {
    try {
      final entries = await readAll();
      if (entries.isEmpty) return null;
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('${dir.path}/voice_logs_$stamp.json');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(entries.map((e) => e.toJson()).toList()),
      );
      return file;
    } catch (_) {
      return null;
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