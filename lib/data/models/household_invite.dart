enum HouseholdInviteStatus { pendingAdminApproval, approved, rejected, accepted }

HouseholdInviteStatus _statusFromApi(String value) => switch (value) {
  'PENDING_ADMIN_APPROVAL' => HouseholdInviteStatus.pendingAdminApproval,
  'APPROVED' => HouseholdInviteStatus.approved,
  'REJECTED' => HouseholdInviteStatus.rejected,
  'ACCEPTED' => HouseholdInviteStatus.accepted,
  _ => HouseholdInviteStatus.pendingAdminApproval,
};

/// An invitation a resident has sent to bring someone else into the app as
/// their own, independent account — see HouseholdMember for once it's been
/// accepted and an account actually exists. [accessCode] is the one-time
/// login password the invitee uses (relayed by the inviter out-of-band, no
/// SMS) — only ever non-null while [status] is [HouseholdInviteStatus.approved];
/// it's cleared server-side the moment they log in and set their own
/// password.
class HouseholdInvite {
  const HouseholdInvite({
    required this.id,
    required this.invitedFullName,
    required this.invitedPhone,
    required this.status,
    required this.createdAt,
    this.accessCode,
  });

  factory HouseholdInvite.fromJson(Map<String, dynamic> json) {
    return HouseholdInvite(
      id: json['id'] as String,
      invitedFullName: json['invitedFullName'] as String,
      invitedPhone: json['invitedPhone'] as String,
      status: _statusFromApi(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      accessCode: json['accessCode'] as String?,
    );
  }

  final String id;
  final String invitedFullName;
  final String invitedPhone;
  final HouseholdInviteStatus status;
  final DateTime createdAt;
  final String? accessCode;

  String get statusLabel => switch (status) {
    HouseholdInviteStatus.pendingAdminApproval => 'Pending admin approval',
    HouseholdInviteStatus.approved => 'Approved — share the access code',
    HouseholdInviteStatus.rejected => 'Rejected',
    HouseholdInviteStatus.accepted => 'Joined',
  };

  Map<String, dynamic> toJson() => {
        'id': id,
        'invitedFullName': invitedFullName,
        'invitedPhone': invitedPhone,
        'status': status.name == 'pendingAdminApproval'
            ? 'PENDING_ADMIN_APPROVAL'
            : status.name.toUpperCase(),
        'createdAt': createdAt.toIso8601String(),
        'accessCode': accessCode,
      };
}
