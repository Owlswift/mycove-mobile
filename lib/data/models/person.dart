/// The signed-in user — residents and guards share one shape (from
/// `GET /users/me`); `house` and the documentation fields below are only
/// ever meaningfully set for residents.
class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.role,
    required this.initials,
    this.house,
    this.email,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.vehiclePlates = const [],
  });

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      id: json['id'] as String,
      phone: json['phone'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String,
      initials: json['initials'] as String,
      house: json['house'] as String?,
      email: json['email'] as String?,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      vehiclePlates: (json['vehiclePlates'] as List?)?.cast<String>() ?? const [],
    );
  }

  final String id;
  final String phone;
  final String fullName;
  final String role; // RESIDENT | GUARD | ADMIN
  final String initials;
  final String? house;
  final String? email;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final List<String> vehiclePlates;

  String get first => fullName.split(' ').first;
}
