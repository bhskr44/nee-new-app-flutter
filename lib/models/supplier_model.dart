class SupplierModel {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? location;
  final String? address;
  final String? website;
  final int? productsCount;

  const SupplierModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.location,
    this.address,
    this.website,
    this.productsCount,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> j) => SupplierModel(
        id: j['id'],
        name: j['name'] ?? '',
        phone: j['phone'],
        email: j['email'],
        location: j['location'],
        address: j['address'],
        website: j['website'],
        productsCount: j['products_count'],
      );
}
