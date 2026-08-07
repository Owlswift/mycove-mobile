enum VisitorPassStatus { active, expired, revoked }

VisitorPassStatus _statusFromJson(String value) {
  switch (value) {
    case 'ACTIVE':
      return VisitorPassStatus.active;
    case 'REVOKED':
      return VisitorPassStatus.revoked;
    default:
      return VisitorPassStatus.expired;
  }
}

class VisitorPass {
  VisitorPass({
    required this.id,
    required this.name,
    required this.phone,
    required this.plate,
    required this.code,
    required this.status,
    this.checkedIn = false,
    this.hasEntered = false,
    this.isInside = false,
    this.visitLabel = 'Not yet arrived',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory VisitorPass.fromJson(Map<String, dynamic> json) {
    return VisitorPass(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      plate: (json['plate'] as String?) ?? '—',
      code: json['code'] as String,
      status: _statusFromJson(json['status'] as String),
      checkedIn: json['checkedIn'] as bool? ?? false,
      hasEntered: json['hasEntered'] as bool? ?? false,
      isInside: json['isInside'] as bool? ?? false,
      visitLabel: json['visitLabel'] as String? ?? 'Not yet arrived',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  final String id;
  final String name;
  final String phone;
  final String plate;
  final String code;
  final VisitorPassStatus status;
  final bool checkedIn;
  final bool hasEntered;
  final bool isInside;
  final String visitLabel;
  final DateTime createdAt;
}
