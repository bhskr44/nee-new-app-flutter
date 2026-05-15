import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/worker_model.dart';
import '../models/lead_model.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  int totalProducts = 0;
  int totalWorkers = 0;
  int totalLeads = 0;

  List<ProductModel> featuredProducts = [];
  List<WorkerModel> featuredWorkers = [];
  List<LeadModel> recentLeads = [];

  bool _loading = false;
  bool get loading => _loading;

  Future<void> fetchStats() async {
    try {
      final data = await apiService.getDashboardStats();
      totalProducts = data['total_products'] ?? 0;
      totalWorkers = data['total_workers'] ?? 0;
      totalLeads = data['total_leads'] ?? 0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchFeatured() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();

    try {
      final data = await apiService.getFeatured();
      featuredProducts = (data['featured_products'] as List)
          .map((e) => ProductModel.fromJson(e))
          .toList();
      featuredWorkers = (data['featured_workers'] as List)
          .map((e) => WorkerModel.fromJson(e))
          .toList();
      recentLeads = (data['recent_leads'] as List)
          .map((e) => LeadModel.fromJson(e))
          .toList();
    } catch (_) {}

    _loading = false;
    notifyListeners();
  }

  Future<void> init() async {
    await Future.wait([fetchStats(), fetchFeatured()]);
  }
}
