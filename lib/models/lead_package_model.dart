class LeadPackageModel {
  final int id;
  final String name;
  /// Leads the pack unlocks; null for an old time-based plan
  final int? leadCount;
  final int durationDays;
  final int price;
  final String? description;

  const LeadPackageModel({
    required this.id,
    required this.name,
    this.leadCount,
    required this.durationDays,
    required this.price,
    this.description,
  });

  factory LeadPackageModel.fromJson(Map<String, dynamic> j) => LeadPackageModel(
        id: j['id'],
        name: j['name'] ?? '',
        leadCount: (j['lead_count'] as num?)?.toInt(),
        durationDays: (j['duration_days'] as num?)?.toInt() ?? 0,
        price: (j['price'] as num?)?.toInt() ?? 0,
        description: j['description'],
      );

  String get summary =>
      leadCount != null ? 'Unlock any $leadCount leads' : 'Valid for $durationLabel';

  String get durationLabel {
    if (durationDays >= 365) return '12 months';
    if (durationDays >= 180) return '6 months';
    if (durationDays >= 28) return '${(durationDays / 30).round()} month${durationDays >= 60 ? 's' : ''}';
    if (durationDays % 7 == 0) return '${durationDays ~/ 7} week${durationDays > 7 ? 's' : ''}';
    return '$durationDays days';
  }
}
