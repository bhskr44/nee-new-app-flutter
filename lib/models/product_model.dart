class ProductModel {
  final int id;
  final String name, category, supplier, unit, location;
  final String? description, brand;
  final String? supplierPhone;
  final String? supplierEmail;
  final int? supplierId;
  final double price;
  final double? rating;
  final int? stock;
  final String? postedBy;
  final List<String> images;
  final List<String> documents;
  final String? youtubeUrl;

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
    this.supplierEmail,
    this.supplierId,
    required this.price,
    this.rating,
    this.stock,
    this.postedBy,
    this.images = const [],
    this.documents = const [],
    this.youtubeUrl,
  });

  factory ProductModel.fromJson(Map<String, dynamic> j) {
    final sup = j['supplier'] is Map ? j['supplier'] as Map : null;
    return ProductModel(
      id: j['id'],
      name: j['name'] ?? '',
      category: j['category'] ?? '',
      supplier: sup?['name'] ?? j['supplier'] ?? '',
      unit: j['unit'] ?? '',
      location: j['location'] ?? '',
      description: j['description'],
      brand: j['brand'],
      supplierId: sup?['id'],
      supplierPhone: sup?['phone'] ?? j['supplier_phone'],
      supplierEmail: sup?['email'],
      price: (j['price'] as num).toDouble(),
      rating: j['rating'] != null ? (j['rating'] as num).toDouble() : null,
      stock: j['stock'],
      postedBy: j['user']?['name'],
      images: (j['image_urls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      documents: (j['document_urls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      youtubeUrl: j['youtube_url'],
    );
  }
}
