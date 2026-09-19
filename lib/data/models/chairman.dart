// Read-only oversight data for the estate chairman account — assembled from
// `GET /finance/dues`, `/finance/summary` and `/complaints/admin/all`, which
// the API opens up to the CHAIRMAN role (see the `@Roles` on those routes).

class DuesRosterRow {
  const DuesRosterRow({
    required this.id,
    required this.fullName,
    required this.house,
    required this.duesBalance,
    required this.monthsPaid,
  });

  factory DuesRosterRow.fromJson(Map<String, dynamic> json) => DuesRosterRow(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    house: json['house'] as String?,
    duesBalance: (json['duesBalance'] as num?)?.toInt() ?? 0,
    monthsPaid: (json['monthsPaid'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String fullName;
  final String? house;
  final int duesBalance;
  final int monthsPaid;
}

class DuesOverview {
  const DuesOverview({
    this.monthlyAmount,
    this.expected = 0,
    this.collected = 0,
    this.outstanding = 0,
    this.residents = const [],
  });

  factory DuesOverview.fromJson(Map<String, dynamic> json) {
    final totals = (json['totals'] as Map?)?.cast<String, dynamic>() ?? const {};
    return DuesOverview(
      monthlyAmount: (json['monthlyAmount'] as num?)?.toInt(),
      expected: (totals['expected'] as num?)?.toInt() ?? 0,
      collected: (totals['collected'] as num?)?.toInt() ?? 0,
      outstanding: (totals['outstanding'] as num?)?.toInt() ?? 0,
      residents: (json['residents'] as List? ?? const [])
          .map((r) => DuesRosterRow.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Null when the estate hasn't set a monthly rate yet, so nothing accrues.
  final int? monthlyAmount;
  final int expected;
  final int collected;
  final int outstanding;
  final List<DuesRosterRow> residents;

  /// Residents with an unpaid balance, biggest debt first.
  List<DuesRosterRow> get owing =>
      residents.where((r) => r.duesBalance > 0).toList()
        ..sort((a, b) => b.duesBalance.compareTo(a.duesBalance));

  /// 0–1 share of what's been billed so far that has actually been paid.
  double get collectionRate => expected <= 0 ? 0 : (collected / expected).clamp(0, 1).toDouble();
}

class ProjectFunds {
  const ProjectFunds({
    required this.id,
    required this.title,
    required this.allocated,
    required this.spent,
    required this.remaining,
    required this.donated,
    required this.pledged,
  });

  factory ProjectFunds.fromJson(Map<String, dynamic> json) => ProjectFunds(
    id: json['id'] as String,
    title: json['title'] as String,
    allocated: (json['allocated'] as num?)?.toInt() ?? 0,
    spent: (json['spent'] as num?)?.toInt() ?? 0,
    remaining: (json['remaining'] as num?)?.toInt() ?? 0,
    donated: (json['donated'] as num?)?.toInt() ?? 0,
    pledged: (json['pledged'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String title;
  final int allocated;
  final int spent;
  final int remaining;
  final int donated;
  final int pledged;
}

class TreasurySummary {
  const TreasurySummary({
    this.totalCollected = 0,
    this.totalAllocated = 0,
    this.treasuryBalance = 0,
    this.projects = const [],
  });

  factory TreasurySummary.fromJson(Map<String, dynamic> json) => TreasurySummary(
    totalCollected: (json['totalCollected'] as num?)?.toInt() ?? 0,
    totalAllocated: (json['totalAllocated'] as num?)?.toInt() ?? 0,
    treasuryBalance: (json['treasuryBalance'] as num?)?.toInt() ?? 0,
    projects: (json['projects'] as List? ?? const [])
        .map((p) => ProjectFunds.fromJson(p as Map<String, dynamic>))
        .toList(),
  );

  final int totalCollected;
  final int totalAllocated;
  final int treasuryBalance;
  final List<ProjectFunds> projects;

  ProjectFunds? fundsFor(String projectId) {
    for (final p in projects) {
      if (p.id == projectId) return p;
    }
    return null;
  }
}

/// A resident complaint as the chairman sees it — includes who raised it.
class AdminComplaint {
  const AdminComplaint({
    required this.id,
    required this.ref,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.residentName,
    this.house,
  });

  factory AdminComplaint.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map?)?.cast<String, dynamic>() ?? const {};
    return AdminComplaint(
      id: json['id'] as String,
      ref: json['ref'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      residentName: (user['fullName'] as String?) ?? 'Resident',
      house: user['house'] as String?,
    );
  }

  final String id;
  final String ref;
  final String category;
  final String description;

  /// SUBMITTED | IN_REVIEW | RESOLVED
  final String status;
  final DateTime createdAt;
  final String residentName;
  final String? house;

  bool get isOpen => status != 'RESOLVED';

  String get statusLabel => switch (status) {
    'SUBMITTED' => 'Submitted',
    'IN_REVIEW' => 'In review',
    'RESOLVED' => 'Resolved',
    _ => status,
  };
}

class ChairmanData {
  const ChairmanData({
    this.dues = const DuesOverview(),
    this.treasury = const TreasurySummary(),
    this.complaints = const [],
    this.loaded = false,
  });

  final DuesOverview dues;
  final TreasurySummary treasury;
  final List<AdminComplaint> complaints;

  /// False until the first successful fetch, so screens can tell "nothing
  /// yet" apart from "loaded, and genuinely empty".
  final bool loaded;

  int get openComplaints => complaints.where((c) => c.isOpen).length;
}
