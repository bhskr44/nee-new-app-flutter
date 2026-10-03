import '../widgets/app_search_field.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/quantity_stepper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product_model.dart';
import '../models/supplier_model.dart';
import '../widgets/youtube_sheet.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../services/activity_service.dart';
import '../services/api_service.dart';
import 'cart_screen.dart';
import 'my_estimates_screen.dart';
import 'suppliers_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  static const _categories = [
    'All',
    'Cement',
    'Steel',
    'Bricks',
    'Sand',
    'Aggregates',
    'Tiles',
    'Paint',
    'Pipes',
    'Electrical',
    'Plumbing',
    'Hardware',
  ];

  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _searchCtrl.text = context.read<ProductProvider>().search;
    // Refetch on every entry so products stay fresh and recover from
    // any failed initial load that happened at app start.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<ProductProvider>();
      if (prov.products.isEmpty && !prov.loading) prov.fetch();
    });
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
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'No internet connection. Please try again.';
      }
    }
    return 'Could not submit product. Please try again.';
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<ProductProvider>().fetch();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder:
          (context, prov, _) => Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            drawer: const AppDrawer(),
            appBar: AppBar(
              title: const Text('Construction Products'),
              // Products is a bottom-nav tab, not a pushed route — nothing on
              // the Navigator stack to pop. MainShell wraps itself in
              // PopScope(canPop: false, ...) precisely so this falls through
              // to the same "switch back to the Home tab" handling as the
              // hardware back button.
              leading: IconButton(
                tooltip: 'Back to Home',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.maybePop(context),
              ),
              actions: [
                Builder(
                  builder: (ctx) => IconButton(
                    tooltip: 'Open menu',
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                Consumer<CartProvider>(
                  builder:
                      (context, cart, _) => Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.shopping_cart_outlined),
                            tooltip: 'Cart',
                            onPressed:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CartScreen(),
                                  ),
                                ),
                          ),
                          if (cart.itemCount > 0)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '${cart.itemCount}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.receipt_long_outlined),
                  tooltip: 'My Estimates',
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyEstimatesScreen(),
                        ),
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.store_outlined),
                  tooltip: 'Suppliers',
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SuppliersScreen(),
                        ),
                      ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showPostProduct(context, prov),
              backgroundColor: const Color(0xFFE65100),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Post Product',
                style: TextStyle(color: Colors.white),
              ),
            ),
            body: Column(
              children: [
                _buildSearch(prov),
                _buildCategories(prov),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => prov.fetch(refresh: true),
                    child:
                        prov.products.isEmpty && prov.loading
                            ? const Center(child: CircularProgressIndicator())
                            : prov.products.isEmpty
                            ? AppEmptyState(
                              icon: Icons.inventory_2_outlined,
                              title:
                                  prov.error != null
                                      ? 'Could not load products'
                                      : 'No products found',
                              message:
                                  prov.error != null
                                      ? 'Check your connection and try again.'
                                      : 'Try another search or browse all products.',
                              actionLabel:
                                  prov.error != null
                                      ? 'Try again'
                                      : 'Show all products',
                              onAction: () {
                                if (prov.error != null) {
                                  prov.fetch(refresh: true);
                                  return;
                                }
                                _searchCtrl.clear();
                                prov.setSearch('');
                                prov.setCategory('All');
                                if (!prov.loading) prov.fetch(refresh: true);
                              },
                            )
                            : ListView.builder(
                              controller: _scrollCtrl,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 80),
                              itemCount:
                                  prov.products.length + (prov.hasMore ? 1 : 0),
                              itemBuilder: (_, i) {
                                if (i == prov.products.length) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16),
                                    child:
                                        prov.loading
                                            ? const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            )
                                            : Center(
                                              child: TextButton(
                                                onPressed: () => prov.fetch(),
                                                child: Text(
                                                  prov.error != null
                                                      ? 'Try loading more again'
                                                      : 'Load more products',
                                                ),
                                              ),
                                            ),
                                  );
                                }
                                return _ProductCard(product: prov.products[i]);
                              },
                            ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSearch(ProductProvider prov) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: AppSearchField(
        controller: _searchCtrl,
        hint: 'Search products or brands',
        onChanged: prov.setSearch,
      ),
    );
  }

  Widget _buildCategories(ProductProvider prov) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final selected = cat == prov.category;
          return ChoiceChip(
            label: Text(cat),
            selected: selected,
            onSelected: (_) => prov.setCategory(cat),
            selectedColor: const Color(0xFFE65100),
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.grey[700],
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  void _showPostProduct(BuildContext context, ProductProvider prov) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final supplierCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final youtubeCtrl = TextEditingController();
    String selectedCat = 'Cement';
    bool submitting = false;
    SupplierModel? selectedSupplier;
    List<XFile> pickedImages = [];
    List<PlatformFile> pickedDocs = [];
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setModalState) => Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    MediaQuery.of(ctx).viewInsets.bottom + 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Post Your Product',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your listing will go live after admin review.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Product Name *',
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: selectedCat,
                          items:
                              _categories
                                  .skip(1)
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) => setModalState(() => selectedCat = v!),
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                        ),
                        const SizedBox(height: 10),
                        _SupplierPicker(
                          controller: supplierCtrl,
                          selectedSupplier: selectedSupplier,
                          onSelected:
                              (s) => setModalState(() {
                                selectedSupplier = s;
                                supplierCtrl.text = s?.name ?? '';
                              }),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: priceCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Price (₹) *',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: unitCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Unit (bag/ton) *',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: locationCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Location *',
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Photo picker
                        Text(
                          'Photos (optional)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              ...pickedImages.asMap().entries.map(
                                (e) => Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 76,
                                      height: 76,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[200],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: FutureBuilder(
                                          future: e.value.readAsBytes(),
                                          builder:
                                              (_, snap) =>
                                                  snap.hasData
                                                      ? Image.memory(
                                                        snap.requireData,
                                                        fit: BoxFit.cover,
                                                      )
                                                      : Container(
                                                        color: Colors.grey[200],
                                                      ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: -4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap:
                                            () => setModalState(
                                              () =>
                                                  pickedImages.removeAt(e.key),
                                            ),
                                        child: Container(
                                          width: 18,
                                          height: 18,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (pickedImages.length < 6)
                                GestureDetector(
                                  onTap: () async {
                                    final imgs = await picker.pickMultiImage(
                                      imageQuality: 75,
                                    );
                                    if (imgs.isNotEmpty) {
                                      setModalState(() {
                                        pickedImages =
                                            [
                                              ...pickedImages,
                                              ...imgs,
                                            ].take(6).toList();
                                      });
                                    }
                                  },
                                  child: Container(
                                    width: 76,
                                    height: 76,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          color: Colors.grey[500],
                                          size: 24,
                                        ),
                                        Text(
                                          'Add',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // PDF document picker
                        Text(
                          'Documents / Specs (PDF, optional)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...pickedDocs.asMap().entries.map(
                          (e) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    e.value.name,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                GestureDetector(
                                  onTap:
                                      () => setModalState(
                                        () => pickedDocs.removeAt(e.key),
                                      ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (pickedDocs.length < 3)
                          OutlinedButton.icon(
                            onPressed: () async {
                              final result = await FilePicker.platform
                                  .pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['pdf'],
                                    allowMultiple: true,
                                    withData: true,
                                  );
                              if (result != null) {
                                setModalState(() {
                                  pickedDocs =
                                      [
                                        ...pickedDocs,
                                        ...result.files,
                                      ].take(3).toList();
                                });
                              }
                            },
                            icon: const Icon(Icons.upload_file, size: 16),
                            label: Text(
                              'Add PDF${pickedDocs.isEmpty ? '' : ' (${pickedDocs.length}/3)'}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE65100),
                              side: const BorderSide(color: Color(0xFFE65100)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),
                        // YouTube URL
                        TextField(
                          controller: youtubeCtrl,
                          keyboardType: TextInputType.url,
                          decoration: InputDecoration(
                            labelText: 'YouTube Video URL (optional)',
                            prefixIcon: const Icon(
                              Icons.play_circle_outline,
                              color: Colors.red,
                            ),
                            hintText: 'https://youtube.com/watch?v=...',
                            helperText:
                                'Add a product demo or walkthrough video',
                            helperStyle: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFBF360C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed:
                                submitting
                                    ? null
                                    : () async {
                                      if (nameCtrl.text.trim().isEmpty ||
                                          priceCtrl.text.trim().isEmpty ||
                                          supplierCtrl.text.trim().isEmpty ||
                                          unitCtrl.text.trim().isEmpty ||
                                          locationCtrl.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please fill all required fields',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      setModalState(() => submitting = true);
                                      try {
                                        final msg = await prov.create(
                                          {
                                            'name': nameCtrl.text.trim(),
                                            'category': selectedCat,
                                            'supplier':
                                                supplierCtrl.text.trim(),
                                            if (selectedSupplier != null)
                                              'supplier_id':
                                                  selectedSupplier!.id,
                                            'price':
                                                double.tryParse(
                                                  priceCtrl.text.trim(),
                                                ) ??
                                                0,
                                            'unit': unitCtrl.text.trim(),
                                            'location':
                                                locationCtrl.text.trim(),
                                            if (youtubeCtrl.text
                                                .trim()
                                                .isNotEmpty)
                                              'youtube_url':
                                                  youtubeCtrl.text.trim(),
                                          },
                                          images:
                                              pickedImages.isEmpty
                                                  ? null
                                                  : pickedImages,
                                          documents:
                                              pickedDocs.isEmpty
                                                  ? null
                                                  : pickedDocs,
                                        );
                                        if (!ctx.mounted) return;
                                        Navigator.pop(ctx);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                msg ??
                                                    'Product submitted for review.',
                                              ),
                                              backgroundColor:
                                                  Colors.green[700],
                                              duration: const Duration(
                                                seconds: 4,
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (!ctx.mounted) return;
                                        setModalState(() => submitting = false);
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          SnackBar(
                                            content: Text(_describeError(e)),
                                            backgroundColor: Colors.red[700],
                                            duration: const Duration(
                                              seconds: 4,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                            child:
                                submitting
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text(
                                      'Submit for Review',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
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

// ─── Supplier Picker ───────────────────────────────────────────────────────────

class _SupplierPicker extends StatefulWidget {
  final TextEditingController controller;
  final SupplierModel? selectedSupplier;
  final ValueChanged<SupplierModel?> onSelected;

  const _SupplierPicker({
    required this.controller,
    required this.selectedSupplier,
    required this.onSelected,
  });

  @override
  State<_SupplierPicker> createState() => _SupplierPickerState();
}

class _SupplierPickerState extends State<_SupplierPicker> {
  void _openPicker() async {
    final result = await showModalBottomSheet<SupplierModel?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _SupplierSearchSheet(),
    );
    // result == null means user dismissed without choosing (keep current)
    // result == SupplierModel means they picked one
    // We also handle "enter manually" by the user editing the text field directly
    if (result != null) {
      widget.onSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final linked = widget.selectedSupplier != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _openPicker,
          child: AbsorbPointer(
            absorbing: false,
            child: TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                labelText: 'Supplier Name *',
                suffixIcon:
                    linked
                        ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: 'Clear selection',
                          onPressed: () => widget.onSelected(null),
                        )
                        : IconButton(
                          icon: const Icon(
                            Icons.search,
                            size: 18,
                            color: Color(0xFFE65100),
                          ),
                          tooltip: 'Pick supplier',
                          onPressed: _openPicker,
                        ),
              ),
              onTap: _openPicker,
              readOnly: linked,
            ),
          ),
        ),
        if (linked)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 13,
                  color: Color(0xFF2E7D32),
                ),
                const SizedBox(width: 4),
                Text(
                  'Linked to existing supplier',
                  style: TextStyle(fontSize: 11, color: Colors.green[700]),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'Tap to search or type a new name',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ),
      ],
    );
  }
}

class _SupplierSearchSheet extends StatefulWidget {
  const _SupplierSearchSheet();

  @override
  State<_SupplierSearchSheet> createState() => _SupplierSearchSheetState();
}

class _SupplierSearchSheetState extends State<_SupplierSearchSheet> {
  final _ctrl = TextEditingController();
  List<SupplierModel> _results = [];
  bool _loading = false;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    setState(() {
      _loading = true;
      _searched = true;
    });
    try {
      final res = await apiService.getSuppliers(
        search: q.isEmpty ? null : q,
        perPage: 30,
      );
      final items =
          (res['data'] as List?)
              ?.map((e) => SupplierModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [];
      setState(() {
        _results = items;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder:
          (_, scrollCtrl) => Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Select Supplier',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ctrl,
                  autofocus: true,
                  onChanged: _search,
                  decoration: InputDecoration(
                    hintText: 'Search suppliers…',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child:
                      _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _results.isEmpty && _searched
                          ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'No matching suppliers found',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              if (_ctrl.text.trim().isNotEmpty)
                                TextButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: Text(
                                    'Use "${_ctrl.text.trim()}" as new supplier',
                                  ),
                                  onPressed: () {
                                    // Return null to signal "no existing supplier picked"
                                    // but the text in the parent field will be used
                                    Navigator.pop(context, null);
                                  },
                                ),
                            ],
                          )
                          : ListView.builder(
                            controller: scrollCtrl,
                            itemCount: _results.length,
                            itemBuilder: (_, i) {
                              final s = _results[i];
                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFE65100),
                                  child: Icon(
                                    Icons.store,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  s.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  [
                                    if (s.location != null) s.location!,
                                    if (s.phone != null) s.phone!,
                                  ].join(' · '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                onTap: () => Navigator.pop(context, s),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
    );
  }
}

// ─── Category helpers ──────────────────────────────────────────────────────────

Color _catColor(String cat) => switch (cat) {
  'Steel' => const Color(0xFF455A64),
  'Bricks' => const Color(0xFFBF360C),
  'Sand' => const Color(0xFFF9A825),
  'Tiles' => const Color(0xFF00695C),
  'Paint' => const Color(0xFF6A1B9A),
  'Pipes' => const Color(0xFF1565C0),
  'Electrical' => const Color(0xFFF57F17),
  'Plumbing' => const Color(0xFF00838F),
  _ => const Color(0xFFE65100),
};

IconData _catIcon(String cat) => switch (cat) {
  'Steel' => Icons.straighten,
  'Bricks' => Icons.foundation,
  'Sand' => Icons.terrain,
  'Tiles' => Icons.grid_view,
  'Paint' => Icons.format_paint,
  'Pipes' => Icons.water,
  'Electrical' => Icons.electrical_services,
  'Plumbing' => Icons.plumbing,
  _ => Icons.inventory_2,
};

// ─── Product Card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final color = _catColor(product.category);
    final rating = product.rating ?? 0.0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetail(context),
        child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 80,
                height: 80,
                child:
                    product.images.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: product.images.first,
                          fit: BoxFit.cover,
                          placeholder:
                              (_, _) => Container(
                                color: color.withAlpha(30),
                                child: Center(
                                  child: Icon(
                                    _catIcon(product.category),
                                    color: color,
                                    size: 30,
                                  ),
                                ),
                              ),
                          errorWidget:
                              (_, _, _) => _FallbackThumb(
                                color: color,
                                category: product.category,
                              ),
                        )
                        : _FallbackThumb(
                          color: color,
                          category: product.category,
                        ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100).withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.category,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey,
                      ),
                      Expanded(
                        child: Text(
                          product.location,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (rating > 0) ...[
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Supplier: ${product.supplier}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Color(0xFFE65100),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'per ${product.unit}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => _showDetail(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          'Details',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    activityService.log(
      'view_product',
      entityType: 'product',
      entityId: product.id,
      entityName: product.name,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _ProductDetailScreen(product: product)),
    );
  }
}

// ─── Fallback thumbnail (no images) ───────────────────────────────────────────

class _FallbackThumb extends StatelessWidget {
  final Color color;
  final String category;
  const _FallbackThumb({required this.color, required this.category});

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ColoredBox(color: color.withAlpha(30)),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withAlpha(90), color.withAlpha(153)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      Center(child: Icon(_catIcon(category), color: Colors.white, size: 30)),
    ],
  );
}

// ─── Product image gallery ─────────────────────────────────────────────────────

class _ProductImageGallery extends StatefulWidget {
  final List<String> images;
  final Color color;
  final String category;
  const _ProductImageGallery({
    required this.images,
    required this.color,
    required this.category,
  });

  @override
  State<_ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<_ProductImageGallery> {
  int _current = 0;
  late final PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _ctrl,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder:
                  (_, i) => GestureDetector(
                    onTap: () => _openFullscreen(context, i),
                    child: CachedNetworkImage(
                      imageUrl: widget.images[i],
                      fit: BoxFit.cover,
                      placeholder:
                          (_, _) => Container(
                            color: widget.color.withAlpha(30),
                            child: Center(
                              child: Icon(
                                _catIcon(widget.category),
                                color: widget.color,
                                size: 50,
                              ),
                            ),
                          ),
                      errorWidget:
                          (_, _, _) => Container(
                            color: widget.color.withAlpha(30),
                            child: Icon(
                              _catIcon(widget.category),
                              color: widget.color,
                              size: 50,
                            ),
                          ),
                    ),
                  ),
            ),
          ),
        ),
        if (widget.images.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final sel = _current == i;
                return GestureDetector(
                  onTap: () {
                    _ctrl.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                    setState(() => _current = i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            sel ? const Color(0xFFE65100) : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: widget.images[i],
                        fit: BoxFit.cover,
                        placeholder:
                            (_, _) => Container(color: Colors.grey[200]),
                        errorWidget:
                            (_, _, _) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  void _openFullscreen(BuildContext context, int initial) {
    int idx = initial;
    final ctrl = PageController(initialPage: initial);
    showDialog(
      context: context,
      builder:
          (_) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              title: StatefulBuilder(
                builder:
                    (_, _) => Text(
                      '${idx + 1} / ${widget.images.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
              ),
            ),
            body: PageView.builder(
              controller: ctrl,
              itemCount: widget.images.length,
              onPageChanged: (i) => idx = i,
              itemBuilder:
                  (_, i) => InteractiveViewer(
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: widget.images[i],
                        fit: BoxFit.contain,
                        placeholder:
                            (_, _) => const CircularProgressIndicator(
                              color: Colors.white,
                            ),
                        errorWidget:
                            (_, _, _) => const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white,
                              size: 60,
                            ),
                      ),
                    ),
                  ),
            ),
          ),
    );
  }
}

// ─── Product Detail Screen ─────────────────────────────────────────────────────

class _ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  const _ProductDetailScreen({required this.product});

  @override
  State<_ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<_ProductDetailScreen> {
  int _qty = 1;

  ProductModel get product => widget.product;

  int? get _maxQty =>
      (product.stock != null && product.stock! > 0) ? product.stock : null;

  void _addToCart(BuildContext context) {
    context.read<CartProvider>().add(product, quantity: _qty);
    // Resolve the navigator now, while context is definitely still mounted —
    // the SnackBarAction's onPressed fires later and closing over `context`
    // directly crashes (null check on a defunct element) if this screen has
    // since been popped but the snackbar is still showing.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // Repeated "Add to Cart" taps otherwise queue one snackbar behind the
    // next — each plays out its full duration before the next starts, which
    // reads as "it never goes away". Clear any pending ones first so only
    // the latest tap's snackbar shows.
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Added $_qty × ${product.name} to cart'),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green[700],
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed:
              () => navigator.push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _catColor(product.category);
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            tooltip: 'Contact Supplier',
            onPressed: () => _contactSupplier(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.images.isNotEmpty) ...[
              _ProductImageGallery(
                images: product.images,
                color: color,
                category: product.category,
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_catIcon(product.category), color: color, size: 80),
              ),
              const SizedBox(height: 16),
            ],
            // Category chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100).withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                product.category,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFE65100),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (product.description != null &&
                product.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                product.description!,
                style: TextStyle(color: Colors.grey[600], height: 1.5),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _row('Supplier', product.supplier),
            _row('Location', product.location),
            _row('Unit', product.unit),
            if (product.brand != null && product.brand!.isNotEmpty)
              _row('Brand', product.brand!),
            if (product.stock != null) _row('Stock', '${product.stock} units'),
            const SizedBox(height: 16),
            Text(
              '₹${product.price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE65100),
              ),
            ),
            Text(
              'per ${product.unit}',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            // YouTube video
            if (product.youtubeUrl != null &&
                product.youtubeUrl!.isNotEmpty) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => showYoutubeSheet(context, product.youtubeUrl!),
                icon: const Icon(Icons.play_circle_outline, color: Colors.red),
                label: const Text(
                  'Watch Product Video',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
            // PDF documents
            if (product.documents.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Documents',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...product.documents.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.tryParse(e.value);
                      if (uri == null) return;
                      try {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not open document'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                      size: 18,
                    ),
                    label: Text(
                      'Document ${e.key + 1}',
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red[200]!),
                      minimumSize: const Size(double.infinity, 44),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 80), // space above the bottom button
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              QuantityStepper(
                quantity: _qty,
                max: _maxQty,
                onChanged: (value) => setState(() => _qty = value),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _addToCart(context),
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('Add to Cart'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _contactSupplier(BuildContext context) {
    final phone = product.supplierPhone;
    if (phone == null || phone.trim().isEmpty) {
      activityService.log(
        'contact_supplier',
        entityType: 'product',
        entityId: product.id,
        entityName: product.name,
        extra: {'status': 'missing_phone', 'supplier': product.supplier},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No contact number available for ${product.supplier}'),
        ),
      );
      return;
    }
    activityService.log(
      'contact_supplier',
      entityType: 'product',
      entityId: product.id,
      entityName: product.name,
      extra: {'phone': phone, 'supplier': product.supplier},
    );
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.supplier,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  phone,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          final uri = Uri(
                            scheme: 'tel',
                            path: phone.replaceAll(RegExp(r'[^\d+]'), ''),
                          );
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('Call'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
                          final uri = Uri.parse('https://wa.me/91$clean');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}
