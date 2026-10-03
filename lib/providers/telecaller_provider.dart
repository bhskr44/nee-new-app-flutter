import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/field_visit_model.dart';
import '../models/lead_project_details_model.dart';
import '../models/telecaller_lead_model.dart';
import '../services/api_service.dart';

class TelecallerProvider extends ChangeNotifier {
  List<TelecallerLeadModel> _pool = [];
  List<TelecallerLeadModel> _myLeads = [];
  List<TelecallerLeadModel> _processedLeads = [];
  bool _poolLoading = false;
  bool _myLeadsLoading = false;
  bool _processedLoading = false;
  bool _poolHasMore = true;
  bool _processedHasMore = true;
  int _poolPage = 1;
  int _processedPage = 1;
  String? _error;
  int? _batchSize;
  DateTime? _nextBatchAt;

  List<TelecallerLeadModel> get pool => _pool;

  /// Set only when the admin's per-hour lead limit is on (see
  /// TelecallerLeadBatchService) — the pool then holds just this batch.
  int? get batchSize => _batchSize;
  DateTime? get nextBatchAt => _nextBatchAt;
  List<TelecallerLeadModel> get myLeads => _myLeads;
  List<TelecallerLeadModel> get processedLeads => _processedLeads;
  bool get poolLoading => _poolLoading;
  bool get myLeadsLoading => _myLeadsLoading;
  bool get processedLoading => _processedLoading;
  bool get poolHasMore => _poolHasMore;
  bool get processedHasMore => _processedHasMore;
  String? get error => _error;

  /// Every lead this telecaller has ever logged a call outcome for — the
  /// only place they show up again once storeCallLog() clears the claim
  /// (see TelecallerLeadController::processedLeads). [status] filters to one
  /// outcome (hot/cold/callback/archive/closed); null/empty means all.
  Future<void> fetchProcessedLeads({bool refresh = false, String? status}) async {
    if (_processedLoading) return;
    if (refresh) {
      _processedPage = 1;
      _processedHasMore = true;
      _processedLeads = [];
    }
    if (!_processedHasMore) return;

    _processedLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiService.getProcessedTelecallerLeads(status: status, page: _processedPage);
      final items = (data['data'] as List).map((e) => TelecallerLeadModel.fromJson(e)).toList();
      _processedLeads = refresh ? items : [..._processedLeads, ...items];
      _processedHasMore = data['next_page_url'] != null;
      _processedPage++;
    } on DioException catch (e) {
      _error = _describeError(e);
    } catch (_) {
      _error = 'Failed to load processed leads.';
    }

    _processedLoading = false;
    notifyListeners();
  }

  Future<void> fetchPool({bool refresh = false, String? search}) async {
    if (_poolLoading) return;
    if (refresh) {
      _poolPage = 1;
      _poolHasMore = true;
      _pool = [];
    }
    if (!_poolHasMore) return;

    _poolLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiService.getTelecallerLeadPool(page: _poolPage, search: search);
      final items = (data['data'] as List).map((e) => TelecallerLeadModel.fromJson(e)).toList();
      _pool = refresh ? items : [..._pool, ...items];
      _poolHasMore = data['next_page_url'] != null;
      _poolPage++;
      final batch = data['batch'];
      _batchSize = batch is Map ? batch['leads_per_batch'] as int? : null;
      _nextBatchAt = batch is Map ? DateTime.tryParse(batch['next_batch_at'] ?? '')?.toLocal() : null;
    } on DioException catch (e) {
      _error = _describeError(e);
    } catch (_) {
      _error = 'Failed to load leads.';
    }

    _poolLoading = false;
    notifyListeners();
  }

  Future<void> fetchMyLeads() async {
    _myLeadsLoading = true;
    notifyListeners();

    try {
      final data = await apiService.getMyTelecallerLeads();
      _myLeads = (data['data'] as List).map((e) => TelecallerLeadModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _error = _describeError(e);
    } catch (_) {
      _error = 'Failed to load your leads.';
    }

    _myLeadsLoading = false;
    notifyListeners();
  }

  /// Surfaces *why* a request failed instead of a generic message — a 403
  /// here almost always means the account's telecaller role didn't make it
  /// through (e.g. the backend the app is pointed at is missing a migration
  /// or role assignment), which looks identical to "no leads" otherwise.
  String _describeError(DioException e) {
    final status = e.response?.statusCode;
    final serverMessage = e.response?.data is Map ? e.response?.data['message']?.toString() : null;
    if (status == 401) return 'Session expired — please log in again.';
    if (status == 403) {
      return serverMessage ?? 'Telecaller access required — your account may not have Area Manager access yet.';
    }
    if (status != null && status >= 500) {
      return 'Server error ($status) — the backend may not be fully set up yet.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Could not reach the server. Check your connection.';
    }
    return serverMessage ?? 'Failed to load leads.';
  }

  /// Claims a lead from the pool. Returns null on success, or an error
  /// message (e.g. someone else just took it) on failure.
  Future<String?> claim(int leadId) async {
    try {
      await apiService.claimTelecallerLead(leadId);
      _pool.removeWhere((l) => l.id == leadId);
      notifyListeners();
      await fetchMyLeads();
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        // Lead fell out of this telecaller's hourly batch (cycle ended) — drop it
        // and surface the server's message rather than the generic 403 text.
        _pool.removeWhere((l) => l.id == leadId);
        notifyListeners();
        return _describeError(e);
      }
      if (e.response?.statusCode == 409) {
        _pool.removeWhere((l) => l.id == leadId);
        notifyListeners();
        return 'This lead is already being called by another telecaller.';
      }
      return _describeError(e);
    }
  }

  Future<bool> release(int leadId) async {
    try {
      await apiService.releaseTelecallerLead(leadId);
      _myLeads.removeWhere((l) => l.id == leadId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> submitCallLog(
    int leadId, {
    required String status,
    String? nextFollowUpAt,
    String? comment,
    Map<String, dynamic>? projectDetails,
  }) async {
    try {
      await apiService.submitTelecallerCallLog(
        leadId,
        status: status,
        nextFollowUpAt: nextFollowUpAt,
        comment: comment,
        projectDetails: projectDetails,
      );
      _myLeads.removeWhere((l) => l.id == leadId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<LeadCallHistoryResult> fetchHistory(int leadId) async {
    final data = await apiService.getLeadCallHistory(leadId);
    final logs = (data['logs'] as List).map((e) => TelecallerCallLog.fromJson(e)).toList();
    final projectDetailsJson = data['project_details'] as Map<String, dynamic>?;
    final fieldVisitReports = (data['field_visit_reports'] as List? ?? [])
        .map((e) => FieldVisitModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return LeadCallHistoryResult(
      logs: logs,
      projectDetails: projectDetailsJson == null ? null : LeadProjectDetailsModel.fromJson(projectDetailsJson),
      fieldVisitReports: fieldVisitReports,
    );
  }

  /// Offers a hot/cold lead for a site visit on [scheduledDate] (yyyy-MM-dd), open to
  /// anyone unless [leadManagerId] assigns it to one specific lead manager.
  /// Returns null on success, or an error message on failure.
  Future<String?> scheduleFieldVisit(int leadId, String scheduledDate, {int? leadManagerId}) async {
    try {
      await apiService.scheduleFieldVisit(leadId, scheduledDate, leadManagerId: leadManagerId);
      return null;
    } on DioException catch (e) {
      final body = e.response?.data;
      return (body is Map ? body['message']?.toString() : null) ?? 'Could not schedule the field visit.';
    }
  }

  /// Lead managers who could take this lead's visit — district-matched ones first.
  Future<List<EligibleLeadManager>> fetchEligibleLeadManagers(int leadId) async {
    final data = await apiService.getEligibleLeadManagers(leadId);
    return data.map((e) => EligibleLeadManager.fromJson(e)).toList();
  }
}

class EligibleLeadManager {
  final int id;
  final String name;
  final String? phone;
  final String? address;
  final List<String> districts;
  final bool districtMatch;

  const EligibleLeadManager({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    required this.districts,
    required this.districtMatch,
  });

  factory EligibleLeadManager.fromJson(Map<String, dynamic> j) => EligibleLeadManager(
        id: j['id'],
        name: j['name'] ?? '',
        phone: j['phone'],
        address: j['address'],
        districts: (j['districts'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        districtMatch: j['district_match'] == true,
      );
}

/// Everything an Area Manager has found out about a lead over the phone —
/// every call log entry plus the shared project-details questionnaire.
class LeadCallHistoryResult {
  final List<TelecallerCallLog> logs;
  final LeadProjectDetailsModel? projectDetails;
  final List<FieldVisitModel> fieldVisitReports;

  const LeadCallHistoryResult({
    required this.logs,
    this.projectDetails,
    this.fieldVisitReports = const [],
  });
}
