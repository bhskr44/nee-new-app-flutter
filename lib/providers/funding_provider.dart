import 'package:flutter/material.dart';
import '../models/funding_scheme_model.dart';
import '../services/api_service.dart';

class FundingProvider extends ChangeNotifier {
  List<FundingSchemeModel> _schemes = [];
  bool _loading = false;
  String _type = 'All';

  List<FundingSchemeModel> get schemes => _schemes;
  bool get loading => _loading;
  String get type => _type;

  List<FundingSchemeModel> get filtered => _type == 'All'
      ? _schemes
      : _schemes.where((s) => s.type == _type).toList();

  Future<void> fetch() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      final data = await apiService.getFunding();
      _schemes = data.map((e) => FundingSchemeModel.fromJson(e)).toList();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  void setType(String t) {
    _type = t;
    notifyListeners();
  }
}
