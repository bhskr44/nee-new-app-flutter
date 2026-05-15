class JobModel {
  final int id;
  final String title, company, location, jobType;
  final double? minSalary, maxSalary;
  final String? description, deadline;
  final List<String> requirements;

  const JobModel({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.jobType,
    this.minSalary,
    this.maxSalary,
    this.description,
    this.deadline,
    required this.requirements,
  });

  String get jobTypeLabel => switch (jobType) {
        'full_time' => 'Full Time',
        'part_time' => 'Part Time',
        'contract' => 'Contract',
        'freelance' => 'Freelance',
        _ => jobType,
      };

  factory JobModel.fromJson(Map<String, dynamic> j) => JobModel(
        id: j['id'],
        title: j['title'] ?? '',
        company: j['company'] ?? '',
        location: j['location'] ?? '',
        jobType: j['job_type'] ?? 'full_time',
        minSalary: j['min_salary'] != null ? (j['min_salary'] as num).toDouble() : null,
        maxSalary: j['max_salary'] != null ? (j['max_salary'] as num).toDouble() : null,
        description: j['description'],
        deadline: j['deadline'],
        requirements: (j['requirements'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );
}
