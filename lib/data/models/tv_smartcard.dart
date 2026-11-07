/// A resident's verified decoder, saved so it doesn't need re-verifying on
/// every subscription payment — the TV equivalent of [UtilityMeter].
class TvSmartcard {
  const TvSmartcard({
    required this.id,
    required this.provider,
    required this.providerName,
    required this.smartcardNumber,
    this.customerName,
    this.currentBouquet,
    this.dueDate,
  });

  factory TvSmartcard.fromJson(Map<String, dynamic> json) {
    return TvSmartcard(
      id: json['id'] as String,
      provider: json['provider'] as String,
      providerName: json['providerName'] as String,
      smartcardNumber: json['smartcardNumber'] as String,
      customerName: json['customerName'] as String?,
      currentBouquet: json['currentBouquet'] as String?,
      dueDate: json['dueDate'] as String?,
    );
  }

  final String id;
  final String provider; // VTpass serviceID: dstv / gotv / startimes
  final String providerName; // display name, e.g. "DStv"
  final String smartcardNumber;
  final String? customerName;
  final String? currentBouquet;
  final String? dueDate;

  Map<String, dynamic> toJson() => {
        'id': id,
        'provider': provider,
        'providerName': providerName,
        'smartcardNumber': smartcardNumber,
        'customerName': customerName,
        'currentBouquet': currentBouquet,
        'dueDate': dueDate,
      };
}

/// The fixed list of TV providers this app supports — VTpass's live-access
/// list has no "list providers" endpoint the way DISCOs do, so this is a
/// small enough, stable enough set to hardcode (same approach the backend's
/// [BuyTvDto] takes).
const tvProviders = [
  ('dstv', 'DStv'),
  ('gotv', 'GOtv'),
  ('startimes', 'StarTimes'),
];
