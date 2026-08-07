import 'package:intl/intl.dart';

String _formatLogTime(String? iso) {
  if (iso == null) return '';
  return DateFormat('MMM d, h:mm a').format(DateTime.parse(iso));
}

class AccessLogEntry {
  AccessLogEntry({
    required this.id,
    required this.visitor,
    required this.entry,
    this.exit,
    DateTime? entryAt,
  }) : entryAt = entryAt ?? DateTime.now();

  factory AccessLogEntry.fromJson(Map<String, dynamic> json) {
    return AccessLogEntry(
      id: json['id'] as String,
      visitor: json['visitor'] as String,
      entry: _formatLogTime(json['entryAt'] as String?),
      exit: json['exitAt'] == null ? null : _formatLogTime(json['exitAt'] as String),
      entryAt: json['entryAt'] != null ? DateTime.parse(json['entryAt'] as String) : null,
    );
  }

  final String id;
  final String visitor;
  final String entry;
  final String? exit;
  final DateTime entryAt;
}