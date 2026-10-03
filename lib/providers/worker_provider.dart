import 'package:flutter/material.dart';
import '../models/worker_model.dart';
import '../services/api_service.dart';

class WorkerProvider extends ChangeNotifier {
  List<WorkerModel> _workers = [];
  bool _loading = false;
  int _requestVersion = 0;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  String _search = '';
  String _trade = 'All';

  WorkerModel? _myWorker;
  bool _myWorkerLoaded = false;

  List<WorkerModel> get workers => _workers;
  bool get loading => _loading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String get trade => _trade;
  WorkerModel? get myWorker => _myWorker;

  Future<void> fetch({bool refresh = false}) async {
    if (_loading && !refresh) return;
    final version = ++_requestVersion;
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
      if (version != _requestVersion) return;
      final items =
          (data['data'] as List).map((e) => WorkerModel.fromJson(e)).toList();
      _workers = refresh ? items : [..._workers, ...items];
      _hasMore = data['next_page_url'] != null;
      _page++;
    } catch (e) {
      if (version != _requestVersion) return;
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

  String get search => _search;

  void setSearch(String q) {
    if (_search == q) return;
    _search = q;
    fetch(refresh: true);
  }

  /// Fetches the current user's own worker profile. Cached after first load.
  Future<void> fetchMyProfile({bool force = false}) async {
    if (_myWorkerLoaded && !force) return;
    try {
      final data = await apiService.getMyWorker();
      _myWorker = data != null ? WorkerModel.fromJson(data) : null;
      _myWorkerLoaded = true;
      notifyListeners();
    } catch (_) {
      // unauthenticated or network error — leave _myWorker as null
    }
  }

  Future<String?> register(Map<String, dynamic> data) async {
    try {
      await apiService.createWorker(data);
      // Invalidate cached profile so next open re-fetches updated data
      _myWorkerLoaded = false;
      _myWorker = null;
      return null; // success
    } catch (e) {
      return e.toString().contains('422')
          ? 'Validation error. Check your inputs.'
          : 'Registration failed. Try again.';
    }
  }
}
