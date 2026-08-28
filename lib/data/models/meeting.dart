/// "Today" / "Tomorrow" / "Aug 25" style label for compact display (e.g.
/// the dashboard's "Next Meeting" stat tile) — distinct from [Meeting]'s
/// own `countdown` field ("2 days away"), which reads as a full sentence
/// and is meant for the meetings list instead.
String meetingWhenLabel(DateTime scheduledAt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
  final diff = day.difference(today).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[scheduledAt.month - 1]} ${scheduledAt.day}';
}

class Meeting {
  const Meeting({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.countdown,
    required this.location,
    required this.scheduledAt,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'] as String,
      title: json['title'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      countdown: json['countdown'] as String,
      location: json['location'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
    );
  }

  final String id;
  final String title;
  final String date;
  final String time;
  final String countdown;
  final String location;
  final DateTime scheduledAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'time': time,
        'countdown': countdown,
        'location': location,
        'scheduledAt': scheduledAt.toIso8601String(),
      };
}
