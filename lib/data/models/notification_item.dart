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
    // A cached toJson() has 'time'/'read' directly (this class doesn't
    // store the raw createdAt/readAt needed to recompute them) — real API
    // responses have 'createdAt'/'readAt' instead. 'time' will read stale
    // ("3 hours ago" said yesterday) until the next real bootstrap, same
    // as any other cached relative-time label; that's expected, not a bug.
    if (json.containsKey('time')) {
      return NotificationItem(
        id: json['id'] as String,
        title: json['title'] as String,
        time: json['time'] as String,
        type: json['type'] as String,
        read: json['read'] as bool,
      );
    }
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'time': time,
        'type': type,
        'read': read,
      };
}
