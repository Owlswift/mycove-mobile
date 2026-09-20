/// Wording for a domestic staff member's days and hours, shared by the list,
/// the review page and the success page.
const _shortDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/// "Mon–Fri", "Tue, Thu", or "Any day". 0 = Sunday … 6 = Saturday.
String daysLabel(List<int> days) {
  final sorted = [...{...days}]..sort();
  if (sorted.isEmpty || sorted.length == 7) return 'Any day';
  final contiguous = sorted.length >= 3 && sorted.last - sorted.first == sorted.length - 1;
  if (contiguous) return '${_shortDays[sorted.first]}–${_shortDays[sorted.last]}';
  return sorted.map((d) => _shortDays[d]).join(', ');
}

/// "7:00 AM" from "07:00".
String timeLabel(String hhmm) {
  final h = int.parse(hhmm.substring(0, 2));
  final m = hhmm.substring(3, 5);
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:$m ${h < 12 ? 'AM' : 'PM'}';
}

/// "7:00 AM – 6:00 PM" or "Any time".
String hoursLabel(String? start, String? end) =>
    (start == null || end == null) ? 'Any time' : '${timeLabel(start)} – ${timeLabel(end)}';

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  final first = parts.first[0];
  final last = parts.length > 1 ? parts.last[0] : '';
  return (first + last).toUpperCase();
}
