import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _selected = 'All';
  String _search = '';

  static const _categories = ['All', 'Cement', 'Steel', 'Bricks', 'Sand', 'Aggregates', 'Tiles', 'Paint', 'Pipes', 'Electrical'];

  List<Product> get _filtered {
    return mockProducts.where((p) {
      final matchCat = _selected == 'All' || p.category == _selected;
      final matchSearch = _search.isEmpty || p.name.toLowerCase().contains(_search.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Construction Products'),
        actions: [
          IconButton(icon: const Icon(Icons.tune), onPressed: () {}),
          IconButton(icon: const Icon(Icons.shopping_cart_outlined), onPressed: () {}),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPostProduct(context),
        backgroundColor: const Color(0xFFE65100),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Post Product', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          _buildHero(),
          _buildSearch(),
          _buildCategories(),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No products found'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _ProductCard(product: _filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return SizedBox(
      height: 140,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=800&h=280&fit=crop&auto=format',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFFE65100)),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xD0BF360C), Color(0xA0E65100)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Building Materials',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                const Text('Find the Best Prices\nNear You',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.2)),
                const SizedBox(height: 10),
                Row(children: [
                  _heroPill(Icons.inventory_2, '14 Products'),
                  const SizedBox(width: 8),
                  _heroPill(Icons.location_on, 'Pan India'),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroPill(IconData icon, String label) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          hintText: 'Search products, brands...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _search.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _search = ''))
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final selected = cat == _selected;
          return ChoiceChip(
            label: Text(cat),
            selected: selected,
            onSelected: (_) => setState(() => _selected = cat),
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

  void _showPostProduct(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Post Your Product', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Product Name')),
            const SizedBox(height: 10),
            const TextField(decoration: InputDecoration(labelText: 'Price (₹)')),
            const SizedBox(height: 10),
            const TextField(decoration: InputDecoration(labelText: 'Location')),
            const SizedBox(height: 10),
            const TextField(decoration: InputDecoration(labelText: 'Contact Number')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Submit Listing'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  static const _categoryImages = {
    'Cement': 'https://images.unsplash.com/photo-1621687779313-e0cd9e10b6d2?w=160&h=160&fit=crop&auto=format',
    'Steel': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=160&h=160&fit=crop&auto=format',
    'Bricks': 'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?w=160&h=160&fit=crop&auto=format',
    'Sand': 'https://images.unsplash.com/photo-1566438480900-0609be27a4be?w=160&h=160&fit=crop&auto=format',
    'Aggregates': 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=160&h=160&fit=crop&auto=format',
    'Tiles': 'https://images.unsplash.com/photo-1600585152220-90363fe7e115?w=160&h=160&fit=crop&auto=format',
    'Paint': 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=160&h=160&fit=crop&auto=format',
    'Pipes': 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=160&h=160&fit=crop&auto=format',
    'Electrical': 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=160&h=160&fit=crop&auto=format',
  };

  @override
  Widget build(BuildContext context) {
    final imgUrl = _categoryImages[product.category];
    return Card(
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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imgUrl != null)
                      Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => ColoredBox(
                            color: product.color.withValues(alpha: 0.12)),
                      )
                    else
                      ColoredBox(color: product.color.withValues(alpha: 0.12)),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            product.color.withValues(alpha: 0.35),
                            product.color.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(product.icon, color: Colors.white, size: 30),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: const Color(0xFFE65100).withAlpha(20),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(product.category,
                          style: const TextStyle(fontSize: 10, color: Color(0xFFE65100), fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.location_on, size: 12, color: Colors.grey),
                    Text(product.location, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const Spacer(),
                    _starRow(product.rating),
                    const SizedBox(width: 3),
                    Text('(${product.reviews})', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
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
                        Text(_formatPrice(product.price, product.category),
                            style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(product.unit, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                      ]),
                      Row(children: [
                        OutlinedButton(
                          onPressed: () => _showDetail(context),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              side: const BorderSide(color: Color(0xFFE65100)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                          child: const Text('Details', style: TextStyle(color: Color(0xFFE65100), fontSize: 12)),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                          child: const Text('Contact', style: TextStyle(fontSize: 12)),
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price, String cat) {
    if (cat == 'Steel') return '₹${price.toStringAsFixed(0)}/MT';
    if (price < 100) return '₹${price.toStringAsFixed(1)}';
    return '₹${price.toStringAsFixed(0)}';
  }

  Widget _starRow(double rating) {
    return Row(
      children: List.generate(5, (i) => Icon(
        i < rating.floor() ? Icons.star : (i < rating ? Icons.star_half : Icons.star_border),
        size: 12, color: Colors.amber,
      )),
    );
  }

  void _showDetail(BuildContext context) {
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
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Container(
              width: double.infinity, height: 140,
              decoration: BoxDecoration(color: product.color.withAlpha(26), borderRadius: BorderRadius.circular(12)),
              child: Icon(product.icon, color: product.color, size: 70),
            ),
            const SizedBox(height: 16),
            Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(product.description, style: TextStyle(color: Colors.grey[600], height: 1.5)),
            const SizedBox(height: 12),
            _detailRow('Supplier', product.supplier),
            _detailRow('Location', product.location),
            _detailRow('Unit', product.unit),
            _detailRow('Rating', '${product.rating} ★ (${product.reviews} reviews)'),
            const SizedBox(height: 16),
            Text(_formatPrice(product.price, product.category),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
            Text(product.unit, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.phone),
                label: const Text('Contact Supplier'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
      ]),
    );
  }
}
