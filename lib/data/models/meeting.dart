class Meeting {
  const Meeting({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.countdown,
    required this.location,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'] as String,
      title: json['title'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      countdown: json['countdown'] as String,
      location: json['location'] as String,
    );
  }

  final String id;
  final String title;
  final String date;
  final String time;
  final String countdown;
  final String location;
}
