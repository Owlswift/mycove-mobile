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
  const VisitorPass({
    required this.id,
    required this.name,
    required this.phone,
    required this.plate,
    required this.window,
    required this.code,
    required this.status,
  });

  factory VisitorPass.fromJson(Map<String, dynamic> json) {
    return VisitorPass(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      plate: (json['plate'] as String?) ?? '—',
      window: json['window'] as String,
      code: json['code'] as String,
      status: _statusFromJson(json['status'] as String),
    );
  }

  final String id;
  final String name;
  final String phone;
  final String plate;
  final String window;
  final String code;
  final VisitorPassStatus status;
}
