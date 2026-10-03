import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'NEE Platform';
  static const String appPackage = 'com.nee.construction';
  static const String appScheme = 'neeconstruction';

  static const String apiBaseUrl = 'https://admin.neeservice.in/api/v1';

  /// Used directly from the app for Places Autocomplete/Details and Geocoding
  /// REST calls at onboarding (see onboarding_location_screen.dart) — a
  /// client-embedded key is unavoidable for a mobile app, so this MUST be
  /// restricted in Google Cloud Console (Android package name + SHA-1 / iOS
  /// bundle ID, scoped to just the Places API + Geocoding API) before release.
  static const String googlePlacesApiKey = 'AIzaSyD4naMYXHoSJnsmDVlX_goq0euJiJh9MVg';

  /// OAuth *Web* client ID from Google Cloud (same project as Firebase), passed
  /// to google_sign_in as serverClientId so the ID token is issued for it — the
  /// backend only accepts tokens for the IDs in GOOGLE_SIGNIN_CLIENT_IDS. The
  /// "Continue with Google" button stays hidden while this is empty.
  static const String googleServerClientId =
      '283161965851-98ki8t34cekff2i09d6bi5cqrdp5sv8n.apps.googleusercontent.com';

  static const Duration apiTimeout = Duration(seconds: 30);

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  static const List<String> productCategories = [
    'All', 'Cement', 'Steel', 'Bricks', 'Sand', 'Aggregates',
    'Tiles', 'Paint', 'Pipes', 'Electrical', 'Plumbing',
    'Hardware', 'Glass', 'Wood', 'Insulation', 'Roofing',
  ];

  static const List<String> workerTrades = [
    'All', 'Mason', 'Plumber', 'Electrician', 'Carpenter', 'Painter',
    'Welder', 'Tiler', 'Roofer', 'Plasterer', 'Steel Fixer',
    'Concrete Mixer', 'Equipment Operator', 'Excavator',
  ];

  static const List<String> projectTypes = [
    'Residential', 'Commercial', 'Industrial', 'Infrastructure',
    'Renovation', 'Interior', 'Landscaping',
  ];

  /// Roles that only take effect after an admin reviews and approves a
  /// role_change_requests row (RoleRequestController on the backend) — never
  /// sendable as a registration/profile `role` value directly, the backend
  /// rejects it there on purpose. Associate Partner is a supervisory role over
  /// other staff and needs a district assigned by admin; Telecaller ("Area
  /// Manager") screens raw leads and Lead Manager visits/manages claimed leads,
  /// so both need admin sign-off before they take effect. Until approved (or
  /// for 7 days, whichever comes first — see FreezeExpiredRoleRequests on the
  /// backend), the account behaves like a guest: full app access, no leads.
  static const List<String> rolesRequiringApproval = ['telecaller', 'lead_manager', 'associate_partner'];

  static bool roleRequiresApproval(String role) => rolesRequiringApproval.contains(role);

  /// Roles offered at first-time signup: (backend role value, display label, icon,
  /// responsibilities). 'telecaller' is the internal/DB key shown to users as "Area
  /// Manager". Buyer/Seller/Contractor/Worker are granted instantly on registration;
  /// Area Manager, Lead Manager and Associate Partner all require admin approval
  /// (see rolesRequiringApproval) — picking one instead auto-files a role-change
  /// request right after signup, and the account is guest-tier (no leads) until
  /// admin acts or 7 days pass, whichever is first.
  static const List<(String, String, IconData, String)> registrableRoles = [
    ('buyer', 'Buyer / Client', Icons.shopping_cart_outlined,
        'Post your requirements, browse products & workers, and get quotes from sellers and contractors.'),
    ('seller', 'Material Seller', Icons.store_outlined,
        'List construction materials for sale and respond to buyer orders and inquiries.'),
    ('contractor', 'Contractor', Icons.engineering_outlined,
        'Bid on leads, manage projects, and source materials & workers through the platform.'),
    ('worker', 'Skilled Worker', Icons.handyman_outlined,
        'List your trade skills and availability to get hired for construction jobs.'),
    // Guest: instantly active like the roles above (no admin approval), but
    // capped at 7 days from signup and never gets lead access (enforced
    // backend-side too, see BlockGuestFromLeads). Kept in customerRoles, not
    // teamRoles, since it isn't a real team role and never files a
    // role_change_request.
    ('guest', 'Guest (7-day preview)', Icons.visibility_outlined,
        "Explore the app for 7 days without creating a full account. Leads aren't visible in guest mode."),
    ('telecaller', 'Area Manager', Icons.support_agent_outlined,
        'Call and follow up with leads, mark them Hot / Cold / Archived, and assign site visits to Lead Managers in your district. Needs admin approval.'),
    ('lead_manager', 'Lead Manager', Icons.assignment_ind_outlined,
        'Visit sites in person, inspect the property, and submit your findings in the app. Set your coverage districts to get matched automatically. Needs admin approval.'),
    ('associate_partner', 'Associate Partner', Icons.supervisor_account_outlined,
        "Oversee the Area Managers and Lead Managers working in your district. Needs admin approval — they'll assign your district when approving."),
  ];

  /// Every possible profile role (registrable ones plus admin-only-granted ones),
  /// used wherever a role value needs a human-readable label — profile display,
  /// role-request pickers, etc.
  static const Map<String, String> roleLabels = {
    'buyer': 'Buyer / Client',
    'seller': 'Material Seller',
    'contractor': 'Contractor',
    'worker': 'Skilled Worker',
    'telecaller': 'Area Manager',
    'lead_manager': 'Lead Manager',
    'associate_partner': 'Associate Partner',
    'admin': 'Admin',
    'guest': 'Guest',
  };

  static String roleLabel(String role) => roleLabels[role] ?? role;

  /// The everyday marketplace roles plus Guest — shown as simple chips at signup.
  static List<(String, String, IconData, String)> get customerRoles =>
      registrableRoles.sublist(0, 5);

  /// The field-team roles — shown as full cards with responsibilities at
  /// signup, since these are less obvious than "Buyer" or "Seller".
  static List<(String, String, IconData, String)> get teamRoles =>
      registrableRoles.sublist(5);

  static bool isTeamRole(String role) => teamRoles.any((r) => r.$1 == role);

  /// Gate for internal, team-only tools (Calculator) — every field-team role
  /// plus admin. Customer-facing roles (buyer, seller, contractor, worker,
  /// guest) don't get these; see app_segments.dart's visibleSegmentIndices
  /// and router.dart's redirect.
  static bool isTeamOrAdmin(String role) => isTeamRole(role) || role == 'admin';

  /// The lead Market Place is for customers, who pay for lead packs (₹3000 per
  /// 10 leads) to unlock contacts. Team accounts work leads through their own
  /// tools instead (Area Managers in the telecaller app, Lead Managers via
  /// assigned field visits), so they don't get it — enforced backend-side too
  /// (marketplace.customers). Guests/unapproved accounts are blocked separately.
  static bool canUseMarketplace(String role) => !isTeamRole(role);
}
