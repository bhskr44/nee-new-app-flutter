import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../screens/area_contacts_screen.dart';
import '../screens/business_screen.dart';
import '../screens/calculator_screen.dart';
import '../screens/funding_screen.dart';
import '../screens/jobs_screen.dart';
import '../screens/leads_screen.dart';
import '../screens/manpower_screen.dart';
import '../screens/products_screen.dart';
import '../screens/request_estimate_screen.dart';
import 'constants.dart';

/// The home-page grid cards, also reused as the drawer's menu list — kept in
/// one place (rather than duplicated in home_screen.dart and app_drawer.dart)
/// so the RBAC filtering below never drifts between the two surfaces.
class AppSegment {
  final String label, subtitle;
  final IconData icon;
  final Color color;
  const AppSegment(this.label, this.icon, this.color, this.subtitle);
}

const appSegments = [
  AppSegment(
    'Construction Products',
    Icons.construction,
    Color(0xFFE65100),
    'Cement, Steel, Bricks & More',
  ),
  AppSegment(
    'Request an Estimate',
    Icons.request_quote_outlined,
    Color(0xFF00897B),
    'Tell Us What You Want to Build',
  ),
  AppSegment(
    'Construction Manpower',
    Icons.people_alt_outlined,
    Color(0xFF1565C0),
    'Skilled Workers On-Demand',
  ),
  AppSegment(
    'Market Place',
    Icons.storefront,
    Color(0xFF2E7D32),
    'Buy & Sell Project Leads',
  ),
  AppSegment(
    'Construction Calculator',
    Icons.calculate_outlined,
    Color(0xFF6A1B9A),
    'Civil, Interior, Tiles & Paint',
  ),
  AppSegment(
    'Funding Support',
    Icons.account_balance_outlined,
    Color(0xFF00695C),
    'Loans & Govt. Schemes',
  ),
  AppSegment(
    'Start Your Business',
    Icons.rocket_launch_outlined,
    Color(0xFFC62828),
    'Launch Your Venture',
  ),
  AppSegment(
    'Jobs & Training',
    Icons.school_outlined,
    Color(0xFFF57F17),
    'Find Jobs, Upskill Today',
  ),
  AppSegment(
    'Area Contacts',
    Icons.location_on_outlined,
    Color(0xFF37474F),
    'District-Wise Contact Persons',
  ),
];

// Parallel to appSegments and to the `screens` list in navigateToSegment() —
// admin feature-flag key each grid card / drawer item is gated on.
const appSegmentKeys = [
  'products',
  'estimate_request',
  'manpower',
  'leads',
  'calculator',
  'funding',
  'business',
  'jobs',
  'area_contacts',
];

/// Indices into appSegments (and appSegmentKeys) whose feature is enabled for
/// the current user — everything else stays hidden from the grid, drawer,
/// and slider CTAs.
List<int> visibleSegmentIndices(BuildContext context) {
  final user = context.watch<AuthProvider>().user;
  final flags = user?.featureFlags ?? const {};
  final role = user?.profile?.role ?? 'buyer';
  // Guest accounts, and any account still awaiting admin approval (including
  // pre-existing accounts backfilled into the retroactive approval queue),
  // never get lead access — enforced backend-side too, see BlockGuestFromLeads.
  final blockLeads =
      role == 'guest' || (user?.profile?.isPendingApproval ?? false);
  // Calculator is an internal tool for the field team and admin; the lead
  // Market Place is the opposite — customers only (paid lead packs), never
  // team accounts.
  final teamOrAdmin = AppConstants.isTeamOrAdmin(role);
  final marketplace = AppConstants.canUseMarketplace(role);
  return [
    for (int i = 0; i < appSegments.length; i++)
      if ((flags[appSegmentKeys[i]] ?? true) &&
          !(blockLeads && appSegmentKeys[i] == 'leads') &&
          !(appSegmentKeys[i] == 'leads' && !marketplace) &&
          !(appSegmentKeys[i] == 'calculator' && !teamOrAdmin))
        i,
  ];
}

Future<void> navigateToSegment(BuildContext context, int index) async {
  final screens = [
    const ProductsScreen(),
    const RequestEstimateScreen(),
    const ManpowerScreen(),
    const LeadsScreen(),
    const CalculatorScreen(),
    const FundingScreen(),
    const BusinessScreen(),
    const JobsScreen(),
    const AreaContactsScreen(),
  ];
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => screens[index]),
  );
  if (context.mounted) {
    context.read<DashboardProvider>().init();
  }
}

/// Quick-access "switch to your work mode" tile config — Telecalling Mode
/// for Area Managers, Field Visit Mode for Lead Managers, Team Dashboard for
/// Associate Partners. Null for plain Buyer/Seller/Contractor/Worker/Guest
/// accounts, which have no such mode. Shared by the home screen's toggle
/// card and the drawer's menu tile.
({
  String label,
  String subtitle,
  IconData icon,
  String route,
  List<Color> colors,
})?
roleModeConfig(UserModel? user) {
  if (user == null) return null;
  if (user.isTelecaller) {
    return (
      label: 'Telecalling Mode',
      subtitle: 'Switch to your lead-calling dashboard',
      icon: Icons.call_outlined,
      route: '/telecaller',
      colors: const [Color(0xFF1565C0), Color(0xFF0D47A1)],
    );
  }
  if (user.isLeadManager) {
    return (
      label: 'Field Visit Mode',
      subtitle: 'View and manage your assigned site visits',
      icon: Icons.location_on_outlined,
      route: '/my-field-visits',
      colors: const [Color(0xFF6A1B9A), Color(0xFF4A148C)],
    );
  }
  if (user.isAssociatePartner) {
    return (
      label: 'Team Dashboard',
      subtitle: "Oversee your district's Area & Lead Managers",
      icon: Icons.dashboard_outlined,
      route: '/associate-partner-dashboard',
      colors: const [Color(0xFFC62828), Color(0xFF8E0000)],
    );
  }
  return null;
}
