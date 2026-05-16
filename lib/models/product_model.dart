class ProductModel {
  final int id;
  final String name, category, supplier, unit, location;
  final String? description, brand;
  final String? supplierPhone;
  final double price;
  final double? rating;
  final int? stock;
  final String? postedBy;
  final List<String> images;

  const ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.supplier,
    required this.unit,
    required this.location,
    this.description,
    this.brand,
    this.supplierPhone,
    required this.price,
    this.rating,
    this.stock,
    this.postedBy,
    this.images = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> j) => ProductModel(
        id: j['id'],
        name: j['name'] ?? '',
        category: j['category'] ?? '',
        supplier: j['supplier'] ?? '',
        unit: j['unit'] ?? '',
        location: j['location'] ?? '',
        description: j['description'],
        brand: j['brand'],
        supplierPhone: j['supplier_phone'] ?? j['phone'] ?? j['user']?['phone'],
        price: (j['price'] as num).toDouble(),
        rating: j['rating'] != null ? (j['rating'] as num).toDouble() : null,
        stock: j['stock'],
        postedBy: j['user']?['name'],
        images: (j['image_urls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );
}
