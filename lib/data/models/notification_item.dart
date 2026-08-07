/// "3 hours ago" / "2 days ago" style label — the API gives a real
/// timestamp, not a canned string, so this replaces what used to be
/// static mock text.
String relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min${diff.inMinutes == 1 ? '' : 's'} ago';
  if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
  return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.time,
    required this.type,
    required this.read,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      time: relativeTime(DateTime.parse(json['createdAt'] as String)),
      type: json['type'] as String,
      read: json['readAt'] != null,
    );
  }

  final String id;
  final String title;
  final String time;
  final String type; // announcement | meeting | visitor | project | payment
  final bool read;
}
