/// A purchasable plan/bouquet — DATA bundle, TV subscription package, or
/// WAEC product — fetched live from `GET /utilities/variations`. [amount]
/// is what the resident pays; [fixedPrice] means the price can't be
/// overridden (true for almost everything VTpass sells this way).
class VariationCode {
  const VariationCode({
    required this.code,
    required this.name,
    required this.amount,
    required this.fixedPrice,
  });

  factory VariationCode.fromJson(Map<String, dynamic> json) {
    return VariationCode(
      code: json['code'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).round(),
      fixedPrice: json['fixedPrice'] as bool? ?? false,
    );
  }

  final String code;
  final String name;
  final int amount;
  final bool fixedPrice;

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'amount': amount,
        'fixedPrice': fixedPrice,
      };
}
