import 'package:go_router/go_router.dart';
import '../widgets/app_empty_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../widgets/quantity_stepper.dart';
import 'my_estimates_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Matches the backend's GST_RATE (config('services.gst.rate')) — this is
  // just a preview; the server computes the authoritative tax on submit.
  static const _gstRate = 0.18;

  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  final _billingCtrl = TextEditingController();
  final _billingPincodeCtrl = TextEditingController();
  final _shippingCtrl = TextEditingController();
  final _shippingPincodeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _shipSameAsBilling = true;
  bool _submitting = false;

  static final _pincodeRegex = RegExp(r'^[1-9][0-9]{5}$');
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    // Pre-fill from the buyer's account + whatever they used last time.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      final profile = user?.profile;
      _phoneCtrl.text = user?.phone ?? profile?.phone ?? '';
      _emailCtrl.text = user?.email ?? '';
      if (profile?.defaultBillingAddress != null) {
        _billingCtrl.text = profile!.defaultBillingAddress!;
      }
      if (profile?.defaultBillingPincode != null) {
        _billingPincodeCtrl.text = profile!.defaultBillingPincode!;
      }
      if (profile?.defaultShippingAddress != null) {
        _shippingCtrl.text = profile!.defaultShippingAddress!;
        _shippingPincodeCtrl.text = profile.defaultShippingPincode ?? '';
        setState(
          () => _shipSameAsBilling = _shippingCtrl.text == _billingCtrl.text,
        );
      }
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _billingCtrl.dispose();
    _billingPincodeCtrl.dispose();
    _shippingCtrl.dispose();
    _shippingPincodeCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  String _describeError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
        final msg = data['message']?.toString();
        if (msg != null && msg.isNotEmpty) return msg;
      }
      if (e.response?.statusCode == 401)
        return 'Session expired. Please log in again.';
    }
    return 'Could not submit estimate. Please try again.';
  }

  Future<void> _submit(CartProvider cart) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final billing = _billingCtrl.text.trim();
      final billingPincode = _billingPincodeCtrl.text.trim();
      final shipping = _shipSameAsBilling ? billing : _shippingCtrl.text.trim();
      final shippingPincode =
          _shipSameAsBilling
              ? billingPincode
              : _shippingPincodeCtrl.text.trim();
      final res = await apiService.submitEstimate(
        cart.items
            .map((i) => {'product_id': i.product.id, 'quantity': i.quantity})
            .toList(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        billingAddress: billing.isEmpty ? null : billing,
        billingPincode: billingPincode.isEmpty ? null : billingPincode,
        shippingAddress: shipping.isEmpty ? null : shipping,
        shippingPincode: shippingPincode.isEmpty ? null : shippingPincode,
        contactPhone:
            _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        contactEmail:
            _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      );
      cart.clear();
      if (!mounted) return;
      final estimateId = res['estimate']?['id'];
      final grandTotal = (res['estimate']?['grand_total'] as num?)?.toDouble();
      await showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Estimate Submitted'),
              content: Text(
                estimateId != null
                    ? 'Estimate #$estimateId has been saved${grandTotal != null ? ' — total ₹${grandTotal.toStringAsFixed(2)}' : ''}. Our team will reach out to you soon.'
                    : 'Your estimate has been saved. Our team will reach out to you soon.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyEstimatesScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_describeError(e)),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder:
          (context, cart, _) => Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              title: const Text('Your Cart'),
              actions: [
                if (!cart.isEmpty)
                  TextButton(
                    onPressed:
                        _submitting
                            ? null
                            : () async {
                              final clear = await showDialog<bool>(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      title: const Text('Clear your cart?'),
                                      content: const Text(
                                        'This removes all products from your current estimate.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(ctx, false),
                                          child: const Text('Keep products'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(ctx, true),
                                          child: const Text('Clear cart'),
                                        ),
                                      ],
                                    ),
                              );
                              if (clear == true && context.mounted)
                                cart.clear();
                            },
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
            body:
                cart.isEmpty
                    ? AppEmptyState(
                      icon: Icons.shopping_cart_outlined,
                      title: 'Your cart is empty',
                      message:
                          'Add construction products to request an estimate.',
                      actionLabel: 'Browse products',
                      onAction: () => context.push('/products'),
                    )
                    : Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                          ...cart.items.map(
                            (item) => _CartItemTile(item: item),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Contact for This Order',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ordering for someone else? Change these.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            validator:
                                (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Phone number is required'
                                        : null,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              if (value.isEmpty) return 'Email is required';
                              if (!_emailRegex.hasMatch(value))
                                return 'Enter a valid email address';
                              return null;
                            },
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Delivery',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _billingCtrl,
                            maxLines: 2,
                            onChanged: (_) {
                              if (_shipSameAsBilling) setState(() {});
                            },
                            decoration: const InputDecoration(
                              labelText: 'Billing Address',
                              hintText: 'Where should the bill be addressed?',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _billingPincodeCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            onChanged: (_) {
                              if (_shipSameAsBilling) setState(() {});
                            },
                            validator: (v) {
                              if (_billingCtrl.text.trim().isEmpty) return null;
                              final value = v?.trim() ?? '';
                              if (value.isEmpty)
                                return 'Please add a 6-digit PIN code';
                              if (!_pincodeRegex.hasMatch(value))
                                return 'Enter a valid 6-digit PIN code';
                              return null;
                            },
                            decoration: const InputDecoration(
                              labelText: 'Billing PIN Code',
                              counterText: '',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          CheckboxListTile(
                            value: _shipSameAsBilling,
                            onChanged:
                                (v) => setState(
                                  () => _shipSameAsBilling = v ?? true,
                                ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: const Text(
                              'Shipping address same as billing',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          if (!_shipSameAsBilling) ...[
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _shippingCtrl,
                              maxLines: 2,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Shipping Address',
                                hintText:
                                    'Where should the order be delivered?',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _shippingPincodeCtrl,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              validator: (v) {
                                if (_shippingCtrl.text.trim().isEmpty)
                                  return null;
                                final value = v?.trim() ?? '';
                                if (value.isEmpty)
                                  return 'Please add a 6-digit PIN code';
                                if (!_pincodeRegex.hasMatch(value))
                                  return 'Enter a valid 6-digit PIN code';
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Shipping PIN Code',
                                counterText: '',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextField(
                            controller: _notesCtrl,
                            maxLines: 3,
                            maxLength: 1000,
                            decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                              hintText: 'Anything else our team should know?',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _OrderSummaryCard(cart: cart, gstRate: _gstRate),
                        ],
                      ),
                    ),
            bottomNavigationBar:
                cart.isEmpty
                    ? null
                    : SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Estimated Bill Amount',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '₹${(cart.subtotal * (1 + _gstRate)).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE65100),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Incl. GST @ ${(_gstRate * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed:
                                  _submitting ? null : () => _submit(cart),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child:
                                  _submitting
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text(
                                        'Place Order — Create Estimate',
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
          ),
    );
  }
}

/// A receipt-style breakdown shown before the buyer confirms — makes the
/// total bill amount unambiguous ahead of tapping "Place Order".
class _OrderSummaryCard extends StatelessWidget {
  final CartProvider cart;
  final double gstRate;
  const _OrderSummaryCard({required this.cart, required this.gstRate});

  @override
  Widget build(BuildContext context) {
    final itemCount = cart.items.length;
    final tax = cart.subtotal * gstRate;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          ...cart.items.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${i.product.name} × ${i.quantity}',
                      style: const TextStyle(fontSize: 12.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '₹${i.lineTotal.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$itemCount item${itemCount == 1 ? '' : 's'} · Subtotal',
                style: const TextStyle(fontSize: 12.5, color: Colors.black87),
              ),
              Text(
                '₹${cart.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12.5),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GST @ ${(gstRate * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12.5, color: Colors.black87),
              ),
              Text(
                '₹${tax.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimated Bill Amount',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text(
                '₹${(cart.subtotal + tax).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE65100),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItemModel item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child:
                    product.images.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: product.images.first,
                          fit: BoxFit.cover,
                        )
                        : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.grey,
                          ),
                        ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${product.price.toStringAsFixed(0)} per ${product.unit}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  QuantityStepper(
                    quantity: item.quantity,
                    min: 0,
                    onChanged: (value) => context
                        .read<CartProvider>()
                        .updateQuantity(product.id, value),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${item.lineTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red,
                  ),
                  onPressed:
                      () => context.read<CartProvider>().remove(product.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
