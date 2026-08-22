/// A resident who joined this account's household via an accepted
/// invitation — see HouseholdInvite for the pending/pre-account stage.
class HouseholdMember {
  const HouseholdMember({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.joinedAt,
  });

  factory HouseholdMember.fromJson(Map<String, dynamic> json) {
    return HouseholdMember(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }

  final String id;
  final String fullName;
  final String phone;
  final DateTime joinedAt;
}
