class AreaContactModel {
  final int id;
  final String name, designation, district, region, phone;
  final String? email, whatsapp;

  const AreaContactModel({
    required this.id,
    required this.name,
    required this.designation,
    required this.district,
    required this.region,
    required this.phone,
    this.email,
    this.whatsapp,
  });

  factory AreaContactModel.fromJson(Map<String, dynamic> j) => AreaContactModel(
        id: j['id'],
        name: j['name'] ?? '',
        designation: j['designation'] ?? '',
        district: j['district'] ?? '',
        region: j['region'] ?? '',
        phone: j['phone'] ?? '',
        email: j['email'],
        whatsapp: j['whatsapp'],
      );
}
