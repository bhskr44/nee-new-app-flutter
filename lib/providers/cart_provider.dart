import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  final Map<int, CartItemModel> _items = {};

  List<CartItemModel> get items => _items.values.toList();
  int get itemCount => _items.length;
  double get subtotal => _items.values.fold(0, (sum, i) => sum + i.lineTotal);
  bool get isEmpty => _items.isEmpty;

  void add(ProductModel product, {int quantity = 1}) {
    final existing = _items[product.id];
    _items[product.id] = CartItemModel(
      product: product,
      quantity: (existing?.quantity ?? 0) + quantity,
    );
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    final existing = _items[productId];
    if (existing == null) return;
    if (quantity <= 0) {
      _items.remove(productId);
    } else {
      _items[productId] = existing.copyWith(quantity: quantity);
    }
    notifyListeners();
  }

  void remove(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
