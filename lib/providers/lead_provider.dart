import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/lead_model.dart';
import '../services/api_service.dart';

class LeadProvider extends ChangeNotifier {
  List<LeadModel> _leads = [];
  bool _loading = false;
  int _requestVersion = 0;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  String _search = '';
  String? _typeFilter; // 'buy', 'sell', or null for all
  bool _assignedToMe = false;
  // Lead-pack unlocks the user has left; null until loaded (or logged out)
  int? _unlocksLeft;

  List<LeadModel> get leads => _leads;
  bool get loading => _loading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String? get typeFilter => _typeFilter;
  bool get assignedToMe => _assignedToMe;
  int? get unlocksLeft => _unlocksLeft;

  List<LeadModel> get buyLeads => _leads.where((l) => l.isBuy).toList();
  List<LeadModel> get sellLeads => _leads.where((l) => !l.isBuy).toList();

  Future<void> loadUnlocks() async {
    try {
      final data = await apiService.getMyLeadSubscription();
      _unlocksLeft = (data['unlocks_left'] as num?)?.toInt() ?? 0;
    } catch (_) {
      _unlocksLeft = null; // not logged in / no access — just hide the count
    }
    notifyListeners();
  }

  Future<void> fetch({bool refresh = false}) async {
    if (_loading && !refresh) return;
    final version = ++_requestVersion;
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _leads = [];
      // After a purchase or an unlock, callers refresh — keep the count current
      loadUnlocks();
    }
    if (!_hasMore) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiService.getLeads(
        type: _typeFilter,
        search: _search.isEmpty ? null : _search,
        page: _page,
        assignedToMe: _assignedToMe ? true : null,
      );
      if (version != _requestVersion) return;
      final items =
          (data['data'] as List).map((e) => LeadModel.fromJson(e)).toList();
      _leads = refresh ? items : [..._leads, ...items];
      _hasMore = data['next_page_url'] != null;
      _page++;
    } catch (e) {
      if (version != _requestVersion) return;
      _error = 'Failed to load leads.';
    }

    _loading = false;
    notifyListeners();
  }

  String get search => _search;

  void setSearch(String q) {
    if (_search == q) return;
    _search = q;
    fetch(refresh: true);
  }

  void setTypeFilter(String? type) {
    _typeFilter = type;
    _assignedToMe = false;
    fetch(refresh: true);
  }

  void setAssignedToMe(bool value) {
    _assignedToMe = value;
    if (value) _typeFilter = null;
    fetch(refresh: true);
  }

  Future<bool> createLead(
    Map<String, dynamic> data, {
    List<XFile>? images,
    List<PlatformFile>? documents,
  }) async {
    try {
      await apiService.createLead(data, images: images, documents: documents);
      fetch(refresh: true);
      return true;
    } catch (_) {
      return false;
    }
  }
}
