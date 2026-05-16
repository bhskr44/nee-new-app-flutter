import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  String _search = '';
  String _category = 'All';

  List<ProductModel> get products => _products;
  bool get loading => _loading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String get category => _category;

  Future<void> fetch({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _products = [];
    }
    if (!_hasMore) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiService.getProducts(
        category: _category == 'All' ? null : _category,
        search: _search.isEmpty ? null : _search,
        page: _page,
      );
      final items = (data['data'] as List).map((e) => ProductModel.fromJson(e)).toList();
      _products = refresh ? items : [..._products, ...items];
      _hasMore = data['next_page_url'] != null;
      _page++;
    } catch (e) {
      _error = 'Failed to load products.';
    }

    _loading = false;
    notifyListeners();
  }

  void setCategory(String cat) {
    if (_category == cat) return;
    _category = cat;
    fetch(refresh: true);
  }

  void setSearch(String q) {
    _search = q;
    fetch(refresh: true);
  }

  Future<String?> create(Map<String, dynamic> data, {List<XFile>? images}) async {
    try {
      final res = await apiService.createProduct(data, images: images);
      return res['message'] as String?;
    } catch (e) {
      return null;
    }
  }
}
