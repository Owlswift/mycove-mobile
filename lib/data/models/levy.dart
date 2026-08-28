enum LevyStatus { unpaid, paid }

class Levy {
  const Levy({
    required this.id,
    required this.label,
    required this.amount,
    required this.dueDate,
    required this.status,
  });

  factory Levy.fromJson(Map<String, dynamic> json) {
    return Levy(
      id: json['id'] as String,
      label: json['label'] as String,
      amount: json['amount'] as int,
      dueDate: json['dueDate'] as String,
      status: (json['paid'] as bool) ? LevyStatus.paid : LevyStatus.unpaid,
    );
  }

  final String id;
  final String label;
  final int amount;
  final String dueDate;
  final LevyStatus status;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'amount': amount,
        'dueDate': dueDate,
        'paid': status == LevyStatus.paid,
      };
}
