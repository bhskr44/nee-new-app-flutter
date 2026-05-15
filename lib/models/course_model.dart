class CourseModel {
  final int id;
  final String name, provider, duration, mode;
  final double fee;
  final String? description, certification;

  const CourseModel({
    required this.id,
    required this.name,
    required this.provider,
    required this.duration,
    required this.mode,
    required this.fee,
    this.description,
    this.certification,
  });

  factory CourseModel.fromJson(Map<String, dynamic> j) => CourseModel(
        id: j['id'],
        name: j['name'] ?? '',
        provider: j['provider'] ?? '',
        duration: j['duration'] ?? '',
        mode: j['mode'] ?? 'offline',
        fee: (j['fee'] as num).toDouble(),
        description: j['description'],
        certification: j['certification'],
      );
}
