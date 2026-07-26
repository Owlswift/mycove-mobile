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
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      date: DateFormat('d MMM').format(DateTime.parse(json['publishedAt'] as String)),
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
}
