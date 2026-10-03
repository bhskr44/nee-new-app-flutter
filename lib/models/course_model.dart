class CourseModel {
  final int id;
  final String name, provider, duration, mode;
  final double fee;
  final String? description, certification, applyUrl;

  const CourseModel({
    required this.id,
    required this.name,
    required this.provider,
    required this.duration,
    required this.mode,
    required this.fee,
    this.description,
    this.certification,
    this.applyUrl,
  });

  factory CourseModel.fromJson(Map<String, dynamic> j) => CourseModel(
        id: j['id'],
        name: j['name'] ?? '',
        provider: j['provider'] ?? '',
        duration: j['duration'] ?? '',
        mode: j['mode'] ?? 'offline',
        fee: double.tryParse(j['fee'].toString()) ?? 0,
        description: j['description'],
        certification: j['certification'],
        applyUrl: j['apply_url'],
      );
}
