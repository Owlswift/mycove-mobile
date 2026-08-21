enum UtilityPurchaseStatus { pending, successful, failed }

UtilityPurchaseStatus _statusFromJson(String value) {
  switch (value) {
    case 'SUCCESSFUL':
      return UtilityPurchaseStatus.successful;
    case 'FAILED':
      return UtilityPurchaseStatus.failed;
    default:
      return UtilityPurchaseStatus.pending;
  }
}

class UtilityPurchase {
  const UtilityPurchase({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.provider,
    this.token,
    this.units,
    this.tariff,
    this.failureReason,
  });

  factory UtilityPurchase.fromJson(Map<String, dynamic> json) {
    return UtilityPurchase(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: json['amount'] as int,
      status: _statusFromJson(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      provider: json['provider'] as String?,
      token: json['token'] as String?,
      units: json['units'] as String?,
      tariff: json['tariff'] as String?,
      failureReason: json['failureReason'] as String?,
    );
  }

  final String id;
  final String type; // ELECTRICITY | AIRTIME
  final int amount;
  final UtilityPurchaseStatus status;
  final DateTime createdAt;
  final String? provider;
  final String? token;
  final String? units;
  final String? tariff;
  final String? failureReason;
}
