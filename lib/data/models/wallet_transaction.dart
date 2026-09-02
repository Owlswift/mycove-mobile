enum WalletTransactionType { topup, purchaseDebit, refund }

WalletTransactionType _typeFromApi(String type) => switch (type) {
  'TOPUP' => WalletTransactionType.topup,
  'PURCHASE_DEBIT' => WalletTransactionType.purchaseDebit,
  'REFUND' => WalletTransactionType.refund,
  _ => WalletTransactionType.purchaseDebit,
};

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.reference,
    required this.createdAt,
    this.description,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String,
      type: _typeFromApi(json['type'] as String),
      amount: json['amount'] as int,
      balanceAfter: json['balanceAfter'] as int,
      reference: json['reference'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final WalletTransactionType type;
  final int amount;
  final int balanceAfter;
  final String reference;
  final String? description;
  final DateTime createdAt;

  /// A top-up/refund adds money (shown "+"), a purchase debit removes it.
  bool get isCredit => type != WalletTransactionType.purchaseDebit;
}
