import 'lead_project_details_model.dart';

/// A telecaller-offered site visit shown on a lead ("pending"), or one the
/// current user has accepted ("accepted_by_me") — see LeadModel.fieldVisit.
class LeadFieldVisitInfo {
  final int id;
  final String scheduledDate;
  final String status; // 'pending' | 'accepted_by_me'

  const LeadFieldVisitInfo({required this.id, required this.scheduledDate, required this.status});

  factory LeadFieldVisitInfo.fromJson(Map<String, dynamic> j) => LeadFieldVisitInfo(
        id: j['id'],
        scheduledDate: j['scheduled_date'] ?? '',
        status: j['status'] ?? 'pending',
      );
}

/// A full field-visit record — used for "My Field Visits" (accepted/completed).
class FieldVisitModel {
  final int id;
  final int leadId;
  final String leadTitle, leadLocation;
  final String? leadContact;
  final String scheduledDate;
  final String status; // pending | accepted | declined | completed | cancelled
  final String? outcome;
  final String? comments;
  final String? declineReason;
  final bool? clientMet;
  final bool? decisionMakerPresent;
  final double? budgetConfirmed;
  final String? timelineConfirmed;
  final List<String> photoUrls;
  final LeadProjectDetailsModel? projectDetails;
  final String? assignedLeadManagerName;
  final String? acceptedByName;

  const FieldVisitModel({
    required this.id,
    required this.leadId,
    required this.leadTitle,
    required this.leadLocation,
    this.leadContact,
    required this.scheduledDate,
    required this.status,
    this.outcome,
    this.comments,
    this.declineReason,
    this.clientMet,
    this.decisionMakerPresent,
    this.budgetConfirmed,
    this.timelineConfirmed,
    this.photoUrls = const [],
    this.projectDetails,
    this.assignedLeadManagerName,
    this.acceptedByName,
  });

  /// An Area Manager assigned this directly and it's still waiting for this
  /// user to accept it (as opposed to an open offer nobody's claimed).
  bool get isPendingAcceptance => status == 'pending';

  bool get isCompleted => status == 'completed';

  bool get isDeclined => status == 'declined';

  factory FieldVisitModel.fromJson(Map<String, dynamic> j) {
    final lead = j['lead'] as Map<String, dynamic>?;
    final assignedLeadManager = j['assigned_lead_manager'] as Map<String, dynamic>?;
    final acceptedBy = j['accepted_by'] as Map<String, dynamic>?;
    return FieldVisitModel(
      id: j['id'],
      leadId: j['lead_id'] ?? lead?['id'] ?? 0,
      leadTitle: lead?['title'] ?? '',
      leadLocation: lead?['location'] ?? '',
      leadContact: lead?['contact'],
      scheduledDate: j['scheduled_date'] ?? '',
      status: j['status'] ?? 'pending',
      outcome: j['outcome'],
      comments: j['comments'],
      declineReason: j['decline_reason'],
      clientMet: j['client_met'],
      decisionMakerPresent: j['decision_maker_present'],
      budgetConfirmed: (j['budget_confirmed'] as num?)?.toDouble(),
      timelineConfirmed: j['timeline_confirmed'],
      photoUrls: (j['photo_urls'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      projectDetails: LeadProjectDetailsModel.fromLeadJson(lead),
      assignedLeadManagerName: assignedLeadManager?['name'],
      acceptedByName: acceptedBy?['name'],
    );
  }
}
