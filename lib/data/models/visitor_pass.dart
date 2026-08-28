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
    this.enteredAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory VisitorPass.fromJson(Map<String, dynamic> json) {
    // A pass is single-use (visitor-passes.service.ts rejects a second
    // entry), so there's at most one access-log row — its entryAt is the
    // real "when did they actually arrive" moment, distinct from
    // createdAt (when the pass itself was issued).
    final accessLogEntries = json['accessLogEntries'] as List<dynamic>?;
    final firstEntry = (accessLogEntries != null && accessLogEntries.isNotEmpty)
        ? accessLogEntries.first as Map<String, dynamic>
        : null;
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
      enteredAt: firstEntry != null ? DateTime.parse(firstEntry['entryAt'] as String) : null,
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

  /// When this visitor actually entered — null until [hasEntered] is true.
  final DateTime? enteredAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'plate': plate,
        'code': code,
        'status': status.name.toUpperCase(),
        'checkedIn': checkedIn,
        'hasEntered': hasEntered,
        'isInside': isInside,
        'visitLabel': visitLabel,
        'createdAt': createdAt.toIso8601String(),
        // Mirrors fromJson's nested accessLogEntries[0].entryAt shape.
        if (enteredAt != null)
          'accessLogEntries': [
            {'entryAt': enteredAt!.toIso8601String()},
          ],
      };
}
