class EstimateItemModel {
  final int id;
  final String productName, unit;
  final double unitPrice, lineTotal;
  final int quantity;

  const EstimateItemModel({
    required this.id,
    required this.productName,
    required this.unit,
    required this.unitPrice,
    required this.lineTotal,
    required this.quantity,
  });

  factory EstimateItemModel.fromJson(Map<String, dynamic> j) =>
      EstimateItemModel(
        id: j['id'],
        productName: j['product_name'] ?? '',
        unit: j['unit'] ?? '',
        unitPrice: (j['unit_price'] as num).toDouble(),
        lineTotal: (j['line_total'] as num).toDouble(),
        quantity: j['quantity'] ?? 0,
      );
}

class EstimateModel {
  final int id;
  final String status; // submitted | contacted | closed
  final String? notes;
  final String? billingAddress;
  final String? billingPincode;
  final String? shippingAddress;
  final String? shippingPincode;
  final String? contactPhone;
  final String? contactEmail;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double grandTotal;
  final int itemCount;
  final String createdAt;
  final List<EstimateItemModel> items;

  const EstimateModel({
    required this.id,
    required this.status,
    this.notes,
    this.billingAddress,
    this.billingPincode,
    this.shippingAddress,
    this.shippingPincode,
    this.contactPhone,
    this.contactEmail,
    required this.subtotal,
    this.taxRate = 18,
    this.taxAmount = 0,
    required this.grandTotal,
    required this.itemCount,
    required this.createdAt,
    this.items = const [],
  });

  factory EstimateModel.fromJson(Map<String, dynamic> j) => EstimateModel(
    id: j['id'],
    status: j['status'] ?? 'submitted',
    notes: j['notes'],
    billingAddress: j['billing_address'],
    billingPincode: j['billing_pincode'],
    shippingAddress: j['shipping_address'],
    shippingPincode: j['shipping_pincode'],
    contactPhone: j['contact_phone'],
    contactEmail: j['contact_email'],
    subtotal: (j['subtotal'] as num).toDouble(),
    taxRate: (j['tax_rate'] as num?)?.toDouble() ?? 18,
    taxAmount: (j['tax_amount'] as num?)?.toDouble() ?? 0,
    grandTotal:
        (j['grand_total'] as num?)?.toDouble() ??
        (j['subtotal'] as num).toDouble(),
    itemCount: j['item_count'] ?? 0,
    createdAt: j['created_at'] ?? '',
    items:
        (j['items'] as List?)
            ?.map(
              (e) => EstimateItemModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList() ??
        [],
  );
}
