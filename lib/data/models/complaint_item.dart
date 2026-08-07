/// A resident's submitted complaint with its ticket reference and status.
class ComplaintItem {
  const ComplaintItem({
    required this.id,
    required this.category,
    required this.description,
    required this.ref,
    required this.status,
    required this.createdAt,
  });

  factory ComplaintItem.fromJson(Map<String, dynamic> json) {
    return ComplaintItem(
      id: json['id'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      ref: json['ref'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String category;
  final String description;
  final String ref;
  final String status; // SUBMITTED | IN_REVIEW | RESOLVED
  final DateTime createdAt;

  String get statusLabel {
    switch (status) {
      case 'SUBMITTED':
        return 'Submitted';
      case 'IN_REVIEW':
        return 'In Review';
      case 'RESOLVED':
        return 'Resolved';
      default:
        return status;
    }
  }

  String get timeLabel {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min${diff.inMinutes == 1 ? '' : 's'} ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inDays < 30) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}