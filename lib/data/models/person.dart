/// The signed-in user — residents and guards share one shape (from
/// `GET /users/me`); `house` is only ever set for residents.
class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.role,
    required this.initials,
    this.house,
  });

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      id: json['id'] as String,
      phone: json['phone'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String,
      initials: json['initials'] as String,
      house: json['house'] as String?,
    );
  }

  final String id;
  final String phone;
  final String fullName;
  final String role; // RESIDENT | GUARD
  final String initials;
  final String? house;

  String get first => fullName.split(' ').first;
}
