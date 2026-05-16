import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/lead_model.dart';
import '../services/api_service.dart';

class LeadProvider extends ChangeNotifier {
  List<LeadModel> _leads = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  String _search = '';
  String? _typeFilter; // 'buy', 'sell', or null for all

  List<LeadModel> get leads => _leads;
  bool get loading => _loading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String? get typeFilter => _typeFilter;

  List<LeadModel> get buyLeads => _leads.where((l) => l.isBuy).toList();
  List<LeadModel> get sellLeads => _leads.where((l) => !l.isBuy).toList();

  Future<void> fetch({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _leads = [];
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
      );
      final items = (data['data'] as List).map((e) => LeadModel.fromJson(e)).toList();
      _leads = refresh ? items : [..._leads, ...items];
      _hasMore = data['next_page_url'] != null;
      _page++;
    } catch (e) {
      _error = 'Failed to load leads.';
    }

    _loading = false;
    notifyListeners();
  }

  void setSearch(String q) {
    _search = q;
    fetch(refresh: true);
  }

  void setTypeFilter(String? type) {
    _typeFilter = type;
    fetch(refresh: true);
  }

  Future<bool> createLead(Map<String, dynamic> data, {List<XFile>? images}) async {
    try {
      await apiService.createLead(data, images: images);
      fetch(refresh: true);
      return true;
    } catch (_) {
      return false;
    }
  }
}
