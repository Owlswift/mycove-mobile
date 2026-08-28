class RulesSection {
  const RulesSection({required this.title, required this.items});

  factory RulesSection.fromJson(Map<String, dynamic> json) {
    return RulesSection(
      title: json['title'] as String,
      items: (json['items'] as List).cast<String>(),
    );
  }

  final String title;
  final List<String> items;

  Map<String, dynamic> toJson() => {'title': title, 'items': items};
}
