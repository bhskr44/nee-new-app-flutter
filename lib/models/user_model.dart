class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final ProfileModel? profile;
  final List<String> roles;
  final Map<String, bool> featureFlags;

  /// A Google sign-in with no OTP-verified phone yet — the backend blocks every
  /// feature (PHONE_NOT_VERIFIED) until it verifies one.
  final bool needsPhoneVerification;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profile,
    this.roles = const [],
    this.featureFlags = const {},
    this.needsPhoneVerification = false,
  });

  /// Admin-controlled app-section visibility (Calculator, Marketplace, etc.) —
  /// defaults to visible when the key is missing (e.g. an older cached
  /// profile, or a module the backend hasn't been told about yet).
  bool isFeatureEnabled(String key) => featureFlags[key] ?? true;

  /// Telecallers ("Area Manager" in the UI) get a distinct in-app mode: they screen raw
  /// sheet leads instead of browsing the customer marketplace.
  bool get isTelecaller => roles.contains('telecaller');

  /// Lead Managers stay in the regular app (no walled shell) — this just unlocks the
  /// "My Coverage Districts" settings entry and field-visit assignment eligibility.
  bool get isLeadManager => roles.contains('lead_manager');

  /// Associate Partners keep full regular-app access plus an additive "Team Dashboard".
  bool get isAssociatePartner => roles.contains('associate_partner');

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final profile =
        json['profile'] != null ? ProfileModel.fromJson(json['profile']) : null;
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'] ?? '',
      phone: json['phone'] ?? profile?.phone,
      profile: profile,
      roles:
          (json['roles'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      featureFlags:
          (json['feature_flags'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v == true),
          ) ??
          const {},
      needsPhoneVerification: json['needs_phone_verification'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'profile': profile?.toJson(),
    'roles': roles,
    'feature_flags': featureFlags,
    'needs_phone_verification': needsPhoneVerification,
  };
}

class ProfileModel {
  final int? id;
  final String? phone;
  final String? avatar;
  final String? city;
  final String? area;
  final String? district;
  final List<String> serviceDistricts;
  final String state;
  final String? country;
  final String? pincode;
  final String role;
  final String? bio;
  final String? companyName;
  final bool isVerified;
  final String? defaultBillingAddress;
  final String? defaultBillingPincode;
  final String? defaultShippingAddress;
  final String? defaultShippingPincode;
  final DateTime? accessFrozenAt;
  final DateTime? guestExpiresAt;
  final String? workAddress;
  final String? googlePlaceId;
  final double? latitude;
  final double? longitude;
  final DateTime? accountApprovedAt;
  final DateTime? approvalDeadlineAt;
  final DateTime? roleConfirmedAt;

  ProfileModel({
    this.id,
    this.phone,
    this.avatar,
    this.city,
    this.area,
    this.district,
    this.serviceDistricts = const [],
    this.state = 'Assam',
    this.country,
    this.pincode,
    this.role = 'buyer',
    this.bio,
    this.companyName,
    this.isVerified = false,
    this.defaultBillingAddress,
    this.defaultBillingPincode,
    this.defaultShippingAddress,
    this.defaultShippingPincode,
    this.accessFrozenAt,
    this.guestExpiresAt,
    this.workAddress,
    this.googlePlaceId,
    this.latitude,
    this.longitude,
    this.accountApprovedAt,
    this.approvalDeadlineAt,
    this.roleConfirmedAt,
  });

  /// Blocked behind the "account frozen" screen — either an initial role
  /// approval that ran past its 7-day window, or expired guest access.
  bool get isFrozen =>
      accessFrozenAt != null ||
      (role == 'guest' &&
          guestExpiresAt != null &&
          guestExpiresAt!.isBefore(DateTime.now()));

  /// True while account_approved_at is still null but the 7-day grace window
  /// (backfilled retroactively for pre-existing accounts, or set on any new
  /// account that somehow slipped through unapproved) hasn't lapsed yet — full
  /// app access except leads, same as a Guest, but not yet frozen.
  bool get isPendingApproval => accountApprovedAt == null && !isFrozen;

  /// Coordinates from GPS/search, or — when the device had no GPS fix and
  /// Google couldn't place the typed address — a manually entered address
  /// saved without coordinates (onboarding is the only writer of
  /// work_address, so it doubles as the "onboarding done" marker there).
  bool get hasLocation =>
      (latitude != null && longitude != null) ||
      ((workAddress?.trim().isNotEmpty ?? false) &&
          (city?.trim().isNotEmpty ?? false) &&
          (district?.trim().isNotEmpty ?? false));

  /// True for a 'buyer' account that has never explicitly gone through a
  /// RolePicker (fresh signup, phone-login profile sheet, Settings role
  /// switch, or the home-screen mandatory prompt) — covers every account
  /// that predates that flow, not just ones created after some cutoff date.
  /// See home_screen.dart's _maybeShowTeamRolePopup.
  bool get needsRoleConfirmation => role == 'buyer' && roleConfirmedAt == null;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      phone: json['phone'],
      avatar: json['avatar'],
      city: json['city'],
      area: json['area'],
      district: json['district'],
      serviceDistricts:
          (json['service_districts'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      state: json['state'] ?? 'Assam',
      country: json['country'],
      pincode: json['pincode'],
      role: json['role'] ?? 'buyer',
      bio: json['bio'],
      companyName: json['company_name'],
      isVerified: json['is_verified'] ?? false,
      defaultBillingAddress: json['default_billing_address'],
      defaultBillingPincode: json['default_billing_pincode'],
      defaultShippingAddress: json['default_shipping_address'],
      defaultShippingPincode: json['default_shipping_pincode'],
      accessFrozenAt:
          json['access_frozen_at'] != null
              ? DateTime.tryParse(json['access_frozen_at'])
              : null,
      guestExpiresAt:
          json['guest_expires_at'] != null
              ? DateTime.tryParse(json['guest_expires_at'])
              : null,
      workAddress: json['work_address'],
      googlePlaceId: json['google_place_id'],
      latitude:
          json['latitude'] != null
              ? double.tryParse(json['latitude'].toString())
              : null,
      longitude:
          json['longitude'] != null
              ? double.tryParse(json['longitude'].toString())
              : null,
      accountApprovedAt:
          json['account_approved_at'] != null
              ? DateTime.tryParse(json['account_approved_at'])
              : null,
      approvalDeadlineAt:
          json['approval_deadline_at'] != null
              ? DateTime.tryParse(json['approval_deadline_at'])
              : null,
      roleConfirmedAt:
          json['role_confirmed_at'] != null
              ? DateTime.tryParse(json['role_confirmed_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'avatar': avatar,
    'city': city,
    'area': area,
    'district': district,
    'service_districts': serviceDistricts,
    'state': state,
    'country': country,
    'pincode': pincode,
    'role': role,
    'bio': bio,
    'company_name': companyName,
    'is_verified': isVerified,
    'default_billing_address': defaultBillingAddress,
    'default_billing_pincode': defaultBillingPincode,
    'default_shipping_address': defaultShippingAddress,
    'default_shipping_pincode': defaultShippingPincode,
    'access_frozen_at': accessFrozenAt?.toIso8601String(),
    'guest_expires_at': guestExpiresAt?.toIso8601String(),
    'work_address': workAddress,
    'google_place_id': googlePlaceId,
    'latitude': latitude,
    'longitude': longitude,
    'account_approved_at': accountApprovedAt?.toIso8601String(),
    'approval_deadline_at': approvalDeadlineAt?.toIso8601String(),
    'role_confirmed_at': roleConfirmedAt?.toIso8601String(),
  };
}
