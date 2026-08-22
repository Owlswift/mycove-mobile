/// A resident with an outstanding estate-dues balance, as seen from the
/// security desk (`GET /dues/owing`, guard-only) — deliberately just dues,
/// not project donations/pledges, since that's the obligation a guard is
/// actually asked about at the gate.
class OwingResident {
  const OwingResident({
    required this.userId,
    required this.fullName,
    required this.house,
    required this.balance,
    required this.monthsOwed,
    required this.lastPaidAt,
  });

  factory OwingResident.fromJson(Map<String, dynamic> json) {
    return OwingResident(
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      house: json['house'] as String?,
      balance: json['balance'] as int,
      monthsOwed: json['monthsOwed'] as int,
      lastPaidAt: json['lastPaidAt'] == null ? null : DateTime.parse(json['lastPaidAt'] as String),
    );
  }

  final String userId;
  final String fullName;
  final String? house;
  final int balance;
  final int monthsOwed;
  final DateTime? lastPaidAt;
}
