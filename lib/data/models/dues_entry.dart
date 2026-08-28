enum DuesEntryType { charge, payment }

class DuesEntry {
  const DuesEntry({
    required this.id,
    required this.date,
    required this.desc,
    required this.type,
    required this.amount,
    required this.createdAt,
  });

  factory DuesEntry.fromJson(Map<String, dynamic> json) {
    return DuesEntry(
      id: json['id'] as String,
      date: json['date'] as String,
      desc: json['desc'] as String,
      type: json['type'] == 'PAYMENT' ? DuesEntryType.payment : DuesEntryType.charge,
      amount: json['amount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String date;
  final String desc;
  final DuesEntryType type;
  final int amount;

  /// Real timestamp behind [date]'s display string — used to decide
  /// whether a payment counts as "recent" (e.g. the dashboard's Recent
  /// Activity card), since [date] itself is a pre-formatted label, not a
  /// parseable one.
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'desc': desc,
        'type': type == DuesEntryType.payment ? 'PAYMENT' : 'CHARGE',
        'amount': amount,
        'createdAt': createdAt.toIso8601String(),
      };
}
