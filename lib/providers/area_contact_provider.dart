import 'package:flutter/material.dart';
import '../models/area_contact_model.dart';
import '../services/api_service.dart';

class AreaContactProvider extends ChangeNotifier {
  List<AreaContactModel> _contacts = [];
  bool _loading = false;
  String _region = 'All';
  String _search = '';

  List<AreaContactModel> get contacts => _contacts;
  bool get loading => _loading;
  String get region => _region;
  String get search => _search;

  List<AreaContactModel> get filtered {
    return _contacts.where((c) {
      final matchRegion = _region == 'All' || c.region == _region;
      final q = _search.toLowerCase();
      final matchSearch = q.isEmpty ||
          c.name.toLowerCase().contains(q) ||
          c.district.toLowerCase().contains(q) ||
          c.designation.toLowerCase().contains(q);
      return matchRegion && matchSearch;
    }).toList();
  }

  Map<String, List<AreaContactModel>> get grouped {
    final Map<String, List<AreaContactModel>> m = {};
    for (final c in filtered) {
      m.putIfAbsent(c.region, () => []).add(c);
    }
    return m;
  }

  Future<void> fetch() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      final data = await apiService.getAreaContacts();
      _contacts = data.map((e) => AreaContactModel.fromJson(e)).toList();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  void setRegion(String r) {
    _region = r;
    notifyListeners();
  }

  void setSearch(String q) {
    _search = q;
    notifyListeners();
  }
}
