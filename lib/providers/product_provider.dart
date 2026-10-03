import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

typedef ProductPageLoader =
    Future<Map<String, dynamic>> Function({
      String? category,
      String? search,
      required int page,
    });

class ProductProvider extends ChangeNotifier {
  final ProductPageLoader _loadPage;

  ProductProvider({ProductPageLoader? loadPage})
    : _loadPage = loadPage ?? apiService.getProducts;

  List<ProductModel> _products = [];
  bool _loading = false;
  int _requestVersion = 0;
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
    if (_loading && !refresh) return;
    final version = ++_requestVersion;
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _products = [];
    }
    if (!_hasMore && !refresh) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _loadPage(
        category: _category == 'All' ? null : _category,
        search: _search.isEmpty ? null : _search,
        page: _page,
      );
      if (version != _requestVersion) return;
      final rawList = data['data'];
      final items =
          (rawList is List ? rawList : [])
              .map(
                (e) =>
                    ProductModel.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
      _products = refresh ? items : [..._products, ...items];
      _hasMore = data['next_page_url'] != null;
      _page++;
    } catch (e) {
      if (version != _requestVersion) return;
      _error = 'Failed to load products. Pull down to retry.';
    }

    _loading = false;
    notifyListeners();
  }

  void setCategory(String cat) {
    if (_category == cat) return;
    _category = cat;
    fetch(refresh: true);
  }

  String get search => _search;

  void setSearch(String q) {
    if (_search == q) return;
    _search = q;
    fetch(refresh: true);
  }

  Future<String?> create(
    Map<String, dynamic> data, {
    List<XFile>? images,
    List<PlatformFile>? documents,
  }) async {
    final res = await apiService.createProduct(
      data,
      images: images,
      documents: documents,
    );
    return res['message'] as String?;
  }
}
