import 'package:intl/intl.dart';

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.unread,
    this.body = '',
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    // 'date' (this class's own already-formatted field) takes priority so a
    // cached toJson()->fromJson() round-trip reproduces the exact original
    // string — 'publishedAt' is a real ISO timestamp but 'date' isn't
    // recoverable from it (day+month only, no year), so re-deriving from a
    // re-cached 'publishedAt' would silently drift from what was cached.
    final cachedDate = json['date'] as String?;
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      date: cachedDate ??
          DateFormat('d MMM').format(DateTime.parse(json['publishedAt'] as String)),
      unread: json['unread'] as bool? ?? false,
      body: json['body'] as String? ?? '',
    );
  }

  final String id;
  final String title;
  final String category;
  final String date;
  final bool unread;
  final String body;

  Announcement copyWith({bool? unread}) {
    return Announcement(
      id: id,
      title: title,
      category: category,
      date: date,
      unread: unread ?? this.unread,
      body: body,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'date': date,
        'unread': unread,
        'body': body,
      };
}
