class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final ProfileModel? profile;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] != null ? ProfileModel.fromJson(json['profile']) : null;
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'] ?? '',
      phone: json['phone'] ?? profile?.phone,
      profile: profile,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'profile': profile?.toJson(),
  };
}

class ProfileModel {
  final int? id;
  final String? phone;
  final String? avatar;
  final String? city;
  final String? district;
  final String state;
  final String role;
  final String? bio;
  final String? companyName;
  final bool isVerified;

  ProfileModel({
    this.id,
    this.phone,
    this.avatar,
    this.city,
    this.district,
    this.state = 'Assam',
    this.role = 'buyer',
    this.bio,
    this.companyName,
    this.isVerified = false,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      phone: json['phone'],
      avatar: json['avatar'],
      city: json['city'],
      district: json['district'],
      state: json['state'] ?? 'Assam',
      role: json['role'] ?? 'buyer',
      bio: json['bio'],
      companyName: json['company_name'],
      isVerified: json['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'avatar': avatar,
    'city': city,
    'district': district,
    'state': state,
    'role': role,
    'bio': bio,
    'company_name': companyName,
    'is_verified': isVerified,
  };
}
