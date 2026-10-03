/// A buyer's request for a full construction-project estimate — a
/// structured brief plus free-text notes and an optional voice memo,
/// distinct from EstimateModel (which prices a cart of products).
class BuildingEstimateRequestModel {
  final int id;
  final String? projectType;
  final int? plotSizeSqft;
  final int? floors;
  final String? roomRequirement;
  final int? budgetMin;
  final int? budgetMax;
  final String? location;
  final String? timeline;
  final String? notes;
  final String? voiceMemoUrl;
  final String status; // open | closed
  final bool remindersEnabled;
  final String createdAt;

  const BuildingEstimateRequestModel({
    required this.id,
    this.projectType,
    this.plotSizeSqft,
    this.floors,
    this.roomRequirement,
    this.budgetMin,
    this.budgetMax,
    this.location,
    this.timeline,
    this.notes,
    this.voiceMemoUrl,
    required this.status,
    required this.remindersEnabled,
    required this.createdAt,
  });

  bool get isOpen => status == 'open';

  factory BuildingEstimateRequestModel.fromJson(Map<String, dynamic> j) => BuildingEstimateRequestModel(
        id: j['id'],
        projectType: j['project_type'],
        plotSizeSqft: (j['plot_size_sqft'] as num?)?.toInt(),
        floors: (j['floors'] as num?)?.toInt(),
        roomRequirement: j['room_requirement'],
        budgetMin: (j['budget_min'] as num?)?.toInt(),
        budgetMax: (j['budget_max'] as num?)?.toInt(),
        location: j['location'],
        timeline: j['timeline'],
        notes: j['notes'],
        voiceMemoUrl: j['voice_memo_url'],
        status: j['status'] ?? 'open',
        remindersEnabled: j['reminders_enabled'] ?? true,
        createdAt: j['created_at'] ?? '',
      );
}
