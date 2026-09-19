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
    this.street,
    this.houseNumber,
    this.email,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.vehiclePlates = const [],
    this.estateName,
    this.estateAddress,
    this.hasPin = false,
    this.duesLiable = true,
    this.invitedByName,
    this.moveInMonth,
  });

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      id: json['id'] as String,
      phone: json['phone'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String,
      initials: json['initials'] as String,
      house: json['house'] as String?,
      street: json['street'] as String?,
      houseNumber: json['houseNumber'] as String?,
      email: json['email'] as String?,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      vehiclePlates: (json['vehiclePlates'] as List?)?.cast<String>() ?? const [],
      estateName: json['estateName'] as String?,
      estateAddress: json['estateAddress'] as String?,
      hasPin: json['hasPin'] as bool? ?? false,
      duesLiable: json['duesLiable'] as bool? ?? true,
      invitedByName: json['invitedByName'] as String?,
      moveInMonth: json['moveInMonth'] as String?,
    );
  }

  final String id;
  final String phone;
  final String fullName;
  final String role; // RESIDENT | GUARD | ADMIN
  final String initials;
  final String? house;
  final String? street;
  final String? houseNumber;
  final String? email;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final List<String> vehiclePlates;
  final String? estateName;
  final String? estateAddress;
  final bool hasPin;
  /// False for a resident who joined via a household invitation — their
  /// household's dues/levy obligation is already covered by whoever
  /// invited them (see [invitedByName]).
  final bool duesLiable;
  final String? invitedByName;
  /// 'YYYY-MM' the estate admin recorded as when the resident moved in. Read-only here.
  final String? moveInMonth;

  String get first => fullName.split(' ').first;
}
