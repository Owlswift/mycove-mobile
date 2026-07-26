enum DuesEntryType { charge, payment }

class DuesEntry {
  const DuesEntry({
    required this.id,
    required this.date,
    required this.desc,
    required this.type,
    required this.amount,
  });

  factory DuesEntry.fromJson(Map<String, dynamic> json) {
    return DuesEntry(
      id: json['id'] as String,
      date: json['date'] as String,
      desc: json['desc'] as String,
      type: json['type'] == 'PAYMENT' ? DuesEntryType.payment : DuesEntryType.charge,
      amount: json['amount'] as int,
    );
  }

  final String id;
  final String date;
  final String desc;
  final DuesEntryType type;
  final int amount;
}
