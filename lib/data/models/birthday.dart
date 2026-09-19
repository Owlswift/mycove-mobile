/// A resident's own birthday (day and month only) and, once it is within a
/// week, this year's celebration to answer — see BirthdaysService on the API.
class MyBirthday {
  const MyBirthday({
    this.birthMonth,
    this.birthDay,
    this.daysUntil,
    this.needsResponse = false,
  });

  factory MyBirthday.fromJson(Map<String, dynamic> json) => MyBirthday(
        birthMonth: json['birthMonth'] as int?,
        birthDay: json['birthDay'] as int?,
        daysUntil: json['daysUntil'] as int?,
        needsResponse: json['needsResponse'] as bool? ?? false,
      );

  final int? birthMonth;
  final int? birthDay;
  final int? daysUntil;

  /// True in the week before the birthday until they answer the photo + party prompt.
  final bool needsResponse;

  bool get hasBirthday => birthMonth != null && birthDay != null;

  static const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// "12 March"
  String? get label => hasBirthday ? '$birthDay ${monthNames[birthMonth! - 1]}' : null;

  /// "today", "tomorrow" or "in 5 days".
  String get whenLabel {
    final d = daysUntil ?? 0;
    if (d <= 0) return 'today';
    if (d == 1) return 'tomorrow';
    return 'in $d days';
  }
}
