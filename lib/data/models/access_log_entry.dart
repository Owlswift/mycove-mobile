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
    this.residentName,
    this.residentHouse,
    DateTime? entryAt,
  }) : entryAt = entryAt ?? DateTime.now();

  factory AccessLogEntry.fromJson(Map<String, dynamic> json) {
    final resident = (json['resident'] as Map?)?.cast<String, dynamic>();
    return AccessLogEntry(
      residentName: resident?['fullName'] as String?,
      residentHouse: resident?['house'] as String?,
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

  /// Who the visitor came to see — sent by the API but only shown to the chairman.
  final String? residentName;
  final String? residentHouse;
  final DateTime entryAt;
}