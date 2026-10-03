/// Shared project-tracking questionnaire for a lead — filled in by either an
/// Area Manager over the phone (call outcome) or a Lead Manager on a site
/// visit (visit report). Whichever fills it in first, the other sees the
/// same record and can add to it; every field is optional and only the ones
/// actually provided in a submission get updated (see the backend's
/// LeadProjectDetails::upsertForLead).
class LeadProjectDetailsModel {
  final String? projectName;
  final String? projectNumber;
  final String? locationMapUrl;
  final List<String> workStage;
  final List<String> interiorStage;
  final String? roomRequirement;
  final String? workStartDate;
  final String? workCompletionDate;
  final int? progressPercent;
  final String? googleReviewUrl;
  final String? facebookReviewUrl;
  final String? instagramReviewUrl;
  final String? siteVisitFrequency;
  final int? workStartingWindowDays;
  final double? advanceReceived;
  final String? balancePaymentNotes;

  const LeadProjectDetailsModel({
    this.projectName,
    this.projectNumber,
    this.locationMapUrl,
    this.workStage = const [],
    this.interiorStage = const [],
    this.roomRequirement,
    this.workStartDate,
    this.workCompletionDate,
    this.progressPercent,
    this.googleReviewUrl,
    this.facebookReviewUrl,
    this.instagramReviewUrl,
    this.siteVisitFrequency,
    this.workStartingWindowDays,
    this.advanceReceived,
    this.balancePaymentNotes,
  });

  factory LeadProjectDetailsModel.fromJson(Map<String, dynamic> j) => LeadProjectDetailsModel(
        projectName: j['project_name'],
        projectNumber: j['project_number'],
        locationMapUrl: j['location_map_url'],
        workStage: (j['work_stage'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        interiorStage: (j['interior_stage'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        roomRequirement: j['room_requirement'],
        workStartDate: j['work_start_date'],
        workCompletionDate: j['work_completion_date'],
        progressPercent: j['progress_percent'],
        googleReviewUrl: j['google_review_url'],
        facebookReviewUrl: j['facebook_review_url'],
        instagramReviewUrl: j['instagram_review_url'],
        siteVisitFrequency: j['site_visit_frequency'],
        workStartingWindowDays: j['work_starting_window_days'],
        advanceReceived: (j['advance_received'] as num?)?.toDouble(),
        balancePaymentNotes: j['balance_payment_notes'],
      );

  /// Parses the nested `project_details` key some lead/visit JSON responses
  /// carry — null-safe for leads that don't have one yet.
  static LeadProjectDetailsModel? fromLeadJson(Map<String, dynamic>? leadJson) {
    final raw = leadJson?['project_details'];
    return raw is Map<String, dynamic> ? LeadProjectDetailsModel.fromJson(raw) : null;
  }
}

/// The fixed option sets the questionnaire offers — kept alongside the model
/// so both the call-outcome and visit-report forms stay in sync.
class ProjectDetailsOptions {
  static const workStage = [
    ('civil_foundation', 'Civil Foundation'),
    ('brick_work', 'Brick Work'),
    ('paint', 'Paint'),
    ('tiles', 'Tiles'),
    ('roof', 'Roof'),
  ];

  static const interiorStage = [
    ('electrical', 'Electrical'),
    ('plumbing', 'Plumbing'),
    ('complete_interior', 'Complete Interior'),
    ('floor_tiles', 'Floor Tiles'),
  ];

  static const roomRequirement = [
    ('2bhk', '2 BHK'),
    ('3bhk', '3 BHK'),
    ('4bhk', '4 BHK'),
  ];

  static const progressPercent = [10, 20, 30, 50, 80, 100];

  static const siteVisitFrequency = [
    ('not_required', 'Not Required'),
    ('bi_weekly', 'Bi-Weekly'),
  ];

  static const workStartingWindowDays = [15, 30, 60];
}
