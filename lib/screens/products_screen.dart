import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../services/activity_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  static const _categories = [
    'All', 'Cement', 'Steel', 'Bricks', 'Sand', 'Aggregates',
    'Tiles', 'Paint', 'Pipes', 'Electrical', 'Plumbing', 'Hardware',
  ];

  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
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
      builder: (context, prov, _) => Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('Construction Products'),
          actions: [IconButton(icon: const Icon(Icons.tune), onPressed: () {})],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showPostProduct(context, prov),
          backgroundColor: const Color(0xFFE65100),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Post Product', style: TextStyle(color: Colors.white)),
        ),
        body: Column(
          children: [
            _buildSearch(prov),
            _buildCategories(prov),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => prov.fetch(refresh: true),
                child: prov.products.isEmpty && prov.loading
                    ? const Center(child: CircularProgressIndicator())
                    : prov.products.isEmpty
                        ? const Center(child: Text('No products found'))
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: prov.products.length + (prov.hasMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i == prov.products.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator()),
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
      child: TextField(
        controller: _searchCtrl,
        onChanged: prov.setSearch,
        decoration: InputDecoration(
          hintText: 'Search products, brands...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    prov.setSearch('');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCategories(ProductProvider prov) {
    return SizedBox(
      height: 42,
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }

  void _showPostProduct(BuildContext context, ProductProvider prov) {
    final nameCtrl     = TextEditingController();
    final priceCtrl    = TextEditingController();
    final locationCtrl = TextEditingController();
    final supplierCtrl = TextEditingController();
    final unitCtrl     = TextEditingController();
    String selectedCat    = 'Cement';
    bool submitting       = false;
    List<XFile> pickedImages = [];
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Post Your Product', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Your listing will go live after admin review.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Product Name *')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedCat,
                  items: _categories.skip(1).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setModalState(() => selectedCat = v!),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 10),
                TextField(controller: supplierCtrl,
                    decoration: const InputDecoration(labelText: 'Supplier Name *')),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(labelText: 'Price (₹) *'),
                    keyboardType: TextInputType.number,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(
                    controller: unitCtrl,
                    decoration: const InputDecoration(labelText: 'Unit (bag/ton) *'),
                  )),
                ]),
                const SizedBox(height: 10),
                TextField(controller: locationCtrl,
                    decoration: const InputDecoration(labelText: 'Location *')),
                const SizedBox(height: 14),
                // Photo picker
                Text('Photos (optional)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ...pickedImages.asMap().entries.map((e) => Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 76, height: 76,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: FutureBuilder(
                                future: e.value.readAsBytes(),
                                builder: (_, snap) => snap.hasData
                                    ? Image.memory(snap.requireData, fit: BoxFit.cover)
                                    : Container(color: Colors.grey[200]),
                              ),
                            ),
                          ),
                          Positioned(
                            top: -4, right: 4,
                            child: GestureDetector(
                              onTap: () => setModalState(() => pickedImages.removeAt(e.key)),
                              child: Container(
                                width: 18, height: 18,
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )),
                      if (pickedImages.length < 6)
                        GestureDetector(
                          onTap: () async {
                            final imgs = await picker.pickMultiImage(imageQuality: 75);
                            if (imgs.isNotEmpty) {
                              setModalState(() {
                                pickedImages = [...pickedImages, ...imgs].take(6).toList();
                              });
                            }
                          },
                          child: Container(
                            width: 76, height: 76,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.add_photo_alternate_outlined, color: Colors.grey[500], size: 24),
                              Text('Add', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                            ]),
                          ),
                        ),
                    ],
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: submitting
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty ||
                                priceCtrl.text.trim().isEmpty ||
                                supplierCtrl.text.trim().isEmpty ||
                                unitCtrl.text.trim().isEmpty ||
                                locationCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Please fill all required fields')),
                              );
                              return;
                            }
                            setModalState(() => submitting = true);
                            final msg = await prov.create({
                              'name':     nameCtrl.text.trim(),
                              'category': selectedCat,
                              'supplier': supplierCtrl.text.trim(),
                              'price':    double.tryParse(priceCtrl.text.trim()) ?? 0,
                              'unit':     unitCtrl.text.trim(),
                              'location': locationCtrl.text.trim(),
                            }, images: pickedImages.isEmpty ? null : pickedImages);
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(msg ?? 'Product submitted for review.'),
                                  backgroundColor: Colors.green[700],
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          },
                    child: submitting
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Submit for Review', style: TextStyle(fontWeight: FontWeight.w700)),
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

const _categoryImages = {
  'Cement': 'https://images.unsplash.com/photo-1621687779313-e0cd9e10b6d2?w=160&h=160&fit=crop&auto=format',
  'Steel': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=160&h=160&fit=crop&auto=format',
  'Bricks': 'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?w=160&h=160&fit=crop&auto=format',
  'Sand': 'https://images.unsplash.com/photo-1566438480900-0609be27a4be?w=160&h=160&fit=crop&auto=format',
  'Tiles': 'https://images.unsplash.com/photo-1600585152220-90363fe7e115?w=160&h=160&fit=crop&auto=format',
  'Paint': 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=160&h=160&fit=crop&auto=format',
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 80, height: 80,
                child: product.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.images.first,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: color.withAlpha(30),
                            child: Center(child: Icon(_catIcon(product.category), color: color, size: 30))),
                        errorWidget: (_, __, ___) => _FallbackThumb(color: color, category: product.category),
                      )
                    : _FallbackThumb(color: color, category: product.category),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100).withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(product.category,
                      style: const TextStyle(fontSize: 10, color: Color(0xFFE65100), fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 4),
                Text(product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.location_on, size: 12, color: Colors.grey),
                  Expanded(
                    child: Text(product.location,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  if (rating > 0) ...[
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    Text(rating.toStringAsFixed(1),
                        style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ],
                ]),
                const SizedBox(height: 6),
                Text('Supplier: ${product.supplier}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('₹${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('per ${product.unit}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                    ]),
                    ElevatedButton(
                      onPressed: () => _showDetail(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('Details', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final color = _catColor(product.category);
    activityService.log('view_product', entityType: 'product', entityId: product.id, entityName: product.name);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            if (product.images.isNotEmpty) ...[
              _ProductImageGallery(images: product.images, color: color, category: product.category),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                width: double.infinity, height: 140,
                decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(12)),
                child: Icon(_catIcon(product.category), color: color, size: 70),
              ),
              const SizedBox(height: 16),
            ],
            Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (product.description != null) ...[
              const SizedBox(height: 8),
              Text(product.description!, style: TextStyle(color: Colors.grey[600], height: 1.5)),
            ],
            const SizedBox(height: 12),
            _row('Supplier', product.supplier),
            _row('Location', product.location),
            _row('Unit', product.unit),
            if (product.brand != null) _row('Brand', product.brand!),
            if (product.stock != null) _row('Stock', '${product.stock} units'),
            const SizedBox(height: 16),
            Text('₹${product.price.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
            Text('per ${product.unit}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _contactSupplier(context);
                },
                icon: const Icon(Icons.phone),
                label: const Text('Contact Supplier'),
              ),
            ),
          ]),
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
        SnackBar(content: Text('No contact number available for ${product.supplier}')),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(product.supplier, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Text(phone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFE65100))),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), ''));
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
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
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.chat),
                label: const Text('WhatsApp'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ]),
      );
}

// ─── Fallback thumbnail (no images) ───────────────────────────────────────────

class _FallbackThumb extends StatelessWidget {
  final Color color;
  final String category;
  const _FallbackThumb({required this.color, required this.category});

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        ColoredBox(color: color.withAlpha(30)),
        DecoratedBox(decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withAlpha(90), color.withAlpha(153)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        )),
        Center(child: Icon(_catIcon(category), color: Colors.white, size: 30)),
      ]);
}

// ─── Product image gallery ─────────────────────────────────────────────────────

class _ProductImageGallery extends StatefulWidget {
  final List<String> images;
  final Color color;
  final String category;
  const _ProductImageGallery({required this.images, required this.color, required this.category});

  @override
  State<_ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<_ProductImageGallery> {
  int _current = 0;
  late final PageController _ctrl;

  @override
  void initState() { super.initState(); _ctrl = PageController(); }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _openFullscreen(context, i),
              child: CachedNetworkImage(
                imageUrl: widget.images[i],
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: widget.color.withAlpha(30),
                    child: Center(child: Icon(_catIcon(widget.category), color: widget.color, size: 50))),
                errorWidget: (_, __, ___) => Container(color: widget.color.withAlpha(30),
                    child: Icon(_catIcon(widget.category), color: widget.color, size: 50)),
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
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final sel = _current == i;
              return GestureDetector(
                onTap: () {
                  _ctrl.animateToPage(i,
                      duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
                  setState(() => _current = i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: sel ? const Color(0xFFE65100) : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: widget.images[i],
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey[200]),
                      errorWidget: (_, __, ___) => Container(color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 16, color: Colors.grey)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ]);
  }

  void _openFullscreen(BuildContext context, int initial) {
    int idx = initial;
    final ctrl = PageController(initialPage: initial);
    showDialog(
      context: context,
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: StatefulBuilder(
            builder: (_, ss) => Text('${idx + 1} / ${widget.images.length}',
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ),
        body: PageView.builder(
          controller: ctrl,
          itemCount: widget.images.length,
          onPageChanged: (i) => idx = i,
          itemBuilder: (_, i) => InteractiveViewer(
            child: Center(child: CachedNetworkImage(
              imageUrl: widget.images[i], fit: BoxFit.contain,
              placeholder: (_, __) => const CircularProgressIndicator(color: Colors.white),
              errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white, size: 60),
            )),
          ),
        ),
      ),
    );
  }
}
