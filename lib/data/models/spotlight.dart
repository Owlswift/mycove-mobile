class Spotlight {
  const Spotlight({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.imageBase64,
    required this.phone,
  });

  factory Spotlight.fromJson(Map<String, dynamic> json) {
    return Spotlight(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      imageBase64: json['imageBase64'] as String?,
      phone: json['phone'] as String?,
    );
  }

  final String id;
  final String name;
  final String category; // PERSON | BUSINESS
  final String description;
  final String? imageBase64;
  final String? phone;

  bool get isBusiness => category == 'BUSINESS';
}
