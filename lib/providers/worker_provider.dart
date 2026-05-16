import 'package:flutter/material.dart';
import '../models/worker_model.dart';
import '../services/api_service.dart';

class WorkerProvider extends ChangeNotifier {
  List<WorkerModel> _workers = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  String _search = '';
  String _trade = 'All';

  List<WorkerModel> get workers => _workers;
  bool get loading => _loading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String get trade => _trade;

  Future<void> fetch({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _workers = [];
    }
    if (!_hasMore) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiService.getWorkers(
        trade: _trade == 'All' ? null : _trade,
        search: _search.isEmpty ? null : _search,
        page: _page,
      );
      final items = (data['data'] as List).map((e) => WorkerModel.fromJson(e)).toList();
      _workers = refresh ? items : [..._workers, ...items];
      _hasMore = data['next_page_url'] != null;
      _page++;
    } catch (e) {
      _error = 'Failed to load workers.';
    }

    _loading = false;
    notifyListeners();
  }

  void setTrade(String t) {
    if (_trade == t) return;
    _trade = t;
    fetch(refresh: true);
  }

  void setSearch(String q) {
    _search = q;
    fetch(refresh: true);
  }

  Future<String?> register(Map<String, dynamic> data) async {
    try {
      await apiService.createWorker(data);
      return null; // success
    } catch (e) {
      return e.toString().contains('422') ? 'Validation error. Check your inputs.' : 'Registration failed. Try again.';
    }
  }
}
