import 'lead_project_details_model.dart';

class TelecallerCallLog {
  final String status;
  final String? nextFollowUpAt;
  final String? comment;
  final String? telecallerName;
  final String createdAt;

  TelecallerCallLog({
    required this.status,
    this.nextFollowUpAt,
    this.comment,
    this.telecallerName,
    required this.createdAt,
  });

  factory TelecallerCallLog.fromJson(Map<String, dynamic> j) =>
      TelecallerCallLog(
        status: j['status'] ?? '',
        nextFollowUpAt: j['next_follow_up_at'],
        comment: j['comment'],
        telecallerName: j['telecaller']?['name'],
        createdAt: j['created_at'] ?? '',
      );
}

class TelecallerLeadModel {
  final int id;
  final String title, projectType, location, contact;
  final String? description;
  final double value;
  final bool isBuy;
  final String? telecallerStatus;
  final String? nextFollowUpAt;
  final LeadProjectDetailsModel? projectDetails;
  final String? createdAt;
  final String? claimedAt;
  /// Ad-sheet tab the lead came from (null for user-posted leads)
  final String? source;
  /// When the customer submitted the ad form
  final String? submittedAt;

  const TelecallerLeadModel({
    required this.id,
    required this.title,
    required this.projectType,
    required this.location,
    required this.contact,
    this.description,
    required this.value,
    required this.isBuy,
    this.telecallerStatus,
    this.nextFollowUpAt,
    this.projectDetails,
    this.createdAt,
    this.claimedAt,
    this.source,
    this.submittedAt,
  });

  factory TelecallerLeadModel.fromJson(Map<String, dynamic> j) {
    return TelecallerLeadModel(
      id: j['id'],
      title: j['title'] ?? '',
      projectType: j['project_type'] ?? '',
      location: j['location'] ?? '',
      contact: j['contact'] ?? '',
      description: j['description'],
      value: (j['value'] as num?)?.toDouble() ?? 0,
      isBuy: j['is_buy'] == true || j['is_buy'] == 1,
      telecallerStatus: j['telecaller_status'],
      nextFollowUpAt: j['next_follow_up_at'],
      projectDetails: LeadProjectDetailsModel.fromLeadJson(j),
      createdAt: j['created_at'],
      claimedAt: j['claimed_by_telecaller_at'],
      source: j['source'],
      submittedAt: j['submitted_at'],
    );
  }

  /// True when this lead has already been screened once and is showing up
  /// again because its follow-up date arrived, rather than being brand new.
  bool get isFollowUp => telecallerStatus != null;
}
