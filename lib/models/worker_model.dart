class WorkerModel {
  final int id;
  final String trade, location, phone, experience;
  final double dailyRate;
  final double? rating;
  final bool available, isVerified;
  final List<String> skills;
  final String? bio, userName;

  const WorkerModel({
    required this.id,
    required this.trade,
    required this.location,
    required this.phone,
    required this.experience,
    required this.dailyRate,
    this.rating,
    required this.available,
    required this.isVerified,
    required this.skills,
    this.bio,
    this.userName,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> j) => WorkerModel(
        id: j['id'],
        trade: j['trade'] ?? '',
        location: j['location'] ?? '',
        phone: j['phone'] ?? '',
        experience: j['experience'] ?? '',
        dailyRate: (j['daily_rate'] as num).toDouble(),
        rating: j['rating'] != null ? (j['rating'] as num).toDouble() : null,
        available: j['available'] == true || j['available'] == 1,
        isVerified: j['is_verified'] == true || j['is_verified'] == 1,
        skills: (j['skills'] as List?)?.map((e) => e.toString()).toList() ?? [],
        bio: j['bio'],
        userName: j['user']?['name'],
      );
}
