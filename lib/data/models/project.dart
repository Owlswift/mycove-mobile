class BudgetLine {
  const BudgetLine({required this.label, required this.amount});

  final String label;
  final int amount;
}

class ProjectReport {
  const ProjectReport({required this.author, required this.date, required this.text});

  final String author;
  final String date;
  final String text;
}

class Project {
  const Project({
    required this.id,
    required this.title,
    required this.status,
    required this.progress,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      title: json['title'] as String,
      status: json['status'] == 'COMPLETED' ? 'Completed' : 'In Progress',
      progress: json['progress'] as int,
    );
  }

  final String id;
  final String title;
  final String status; // 'In Progress' | 'Completed'
  final int progress; // 0-100

  bool get isCompleted => status == 'Completed';
}
