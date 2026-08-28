class MyPledge {
  const MyPledge({required this.id, required this.amount, required this.projectId, required this.projectTitle});

  factory MyPledge.fromJson(Map<String, dynamic> json) {
    return MyPledge(
      id: json['id'] as String,
      amount: json['amount'] as int,
      projectId: json['projectId'] as String,
      projectTitle: json['projectTitle'] as String,
    );
  }

  final String id;
  final int amount;
  final String projectId;
  final String projectTitle;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'projectId': projectId,
        'projectTitle': projectTitle,
      };
}
