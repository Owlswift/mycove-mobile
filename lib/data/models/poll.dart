class PollOption {
  const PollOption({required this.id, required this.label, required this.pct});

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(id: json['id'] as String, label: json['label'] as String, pct: json['pct'] as int);
  }

  final String id;
  final String label;
  final int pct;

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'pct': pct};
}

class Poll {
  const Poll({
    required this.id,
    required this.question,
    required this.closesIn,
    required this.voted,
    required this.selectedOptionId,
    required this.voteCountLabel,
    required this.options,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'] as String,
      question: json['question'] as String,
      closesIn: json['closesIn'] as String,
      voted: json['voted'] as bool,
      selectedOptionId: json['selectedOptionId'] as String?,
      voteCountLabel: json['voteCountLabel'] as String,
      options: (json['options'] as List).map((o) => PollOption.fromJson(o as Map<String, dynamic>)).toList(),
    );
  }

  final String id;
  final String question;
  final String closesIn;
  final bool voted;
  final String? selectedOptionId;
  final String voteCountLabel;
  final List<PollOption> options;

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'closesIn': closesIn,
        'voted': voted,
        'selectedOptionId': selectedOptionId,
        'voteCountLabel': voteCountLabel,
        'options': options.map((o) => o.toJson()).toList(),
      };
}
