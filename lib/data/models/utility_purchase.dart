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

class UtilityPurchaseMeter {
  const UtilityPurchaseMeter({
    required this.meterNumber,
    required this.discoName,
    required this.discoCode,
    required this.meterType,
  });

  factory UtilityPurchaseMeter.fromJson(Map<String, dynamic> json) {
    return UtilityPurchaseMeter(
      meterNumber: json['meterNumber'] as String? ?? '',
      discoName: json['discoName'] as String? ?? '',
      discoCode: json['discoCode'] as String? ?? '',
      meterType: json['meterType'] as String? ?? '',
    );
  }

  final String meterNumber;
  final String discoName;
  final String discoCode;
  final String meterType;

  Map<String, dynamic> toJson() => {
        'meterNumber': meterNumber,
        'discoName': discoName,
        'discoCode': discoCode,
        'meterType': meterType,
      };
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
    this.meter,
    this.network,
    this.phone,
  });

  factory UtilityPurchase.fromJson(Map<String, dynamic> json) {
    final meterJson = json['meter'] as Map<String, dynamic>?;
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
      meter:
          meterJson == null ? null : UtilityPurchaseMeter.fromJson(meterJson),
      network: json['network'] as String?,
      phone: json['phone'] as String?,
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

  /// Meter details (electricity only) — included by the API so receipts can
  /// show which meter/DISCO a token belongs to without another lookup.
  final UtilityPurchaseMeter? meter;

  /// AIRTIME only: mtn / airtel / glo / etisalat.
  final String? network;

  /// AIRTIME recipient, or electricity contact phone.
  final String? phone;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'status': status.name.toUpperCase(),
        'createdAt': createdAt.toIso8601String(),
        'provider': provider,
        'token': token,
        'units': units,
        'tariff': tariff,
        'failureReason': failureReason,
        'meter': meter?.toJson(),
        'network': network,
        'phone': phone,
      };
}
