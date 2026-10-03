import '../widgets/app_search_field.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/dashboard_provider.dart';
import '../providers/auth_provider.dart';
import '../models/lead_model.dart';
import '../services/api_service.dart';
import '../config/app_segments.dart';
import '../config/constants.dart';
import '../widgets/app_drawer.dart';
import '../widgets/team_role_popup.dart';
import 'products_screen.dart';
import 'manpower_screen.dart';
import 'leads_screen.dart';
import 'funding_screen.dart';
import 'business_screen.dart';
import 'jobs_screen.dart';
import 'area_contacts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<dynamic>>? _activityFuture;
  final _serviceSearch = TextEditingController();
  String _serviceQuery = '';
  bool _showAllActivity = false;

  @override
  void dispose() {
    _serviceSearch.dispose();
    super.dispose();
  }

  Future<void> _refreshHome() async {
    setState(_refreshRecentActivity);
    await Future.wait([
      context.read<DashboardProvider>().init(),
      context.read<AuthProvider>().refreshUser(),
      _activityFuture!,
    ]);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeShowTeamRolePopup(),
    );
  }

  /// Mandatory for any account that's never explicitly confirmed a role
  /// (ProfileModel.needsRoleConfirmation — backend-tracked via
  /// profiles.role_confirmed_at, not local storage, so it doesn't reset on
  /// logout/login or a new device). Covers every legacy 'buyer' account from
  /// before the RolePicker flow existed, not just newly created ones. No
  /// dismiss: they must pick a role in the popup itself.
  Future<void> _maybeShowTeamRolePopup() async {
    if (!mounted) return;
    final user = context.read<AuthProvider>().user;
    if (user?.profile?.needsRoleConfirmation != true) return;

    final selectedRole = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const TeamRolePopup(),
    );

    if (selectedRole == null || !mounted) return;
    await _applyTeamRole(selectedRole);
  }

  /// Performs the actual role change once the picker has closed — deliberately
  /// not run from inside the dialog itself. Area Manager triggers GoRouter's
  /// own redirect to /telecaller; doing that while the dialog's Navigator.pop()
  /// is still in flight is what caused the "popped the last page off of the
  /// stack" crash, so this only runs after the dialog is fully gone.
  Future<void> _applyTeamRole(String role) async {
    final auth = context.read<AuthProvider>();

    if (AppConstants.roleRequiresApproval(role)) {
      final label = AppConstants.roleLabel(role);
      try {
        final result = await apiService.requestRoleChange(role);
        // Filing the request may have just stamped role_confirmed_at and/or
        // changed the account's own role (guest-tier while pending, see
        // RoleRequestController::store) — refresh so this session's user
        // reflects that immediately instead of only on next login.
        await auth.refreshUser();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] as String? ??
                  'Request submitted! Your $label request is pending admin approval.',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not submit request. Try again from Settings.',
              ),
            ),
          );
        }
      }
      return;
    }

    final label = AppConstants.roleLabel(role);
    final success = await auth.updateProfile({'role': role});
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You're now a $label!"),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not change your role. Try again from Settings.'),
        ),
      );
    }
  }

  void _refreshRecentActivity() {
    _activityFuture = apiService.getUserActivity();
  }

  @override
  Widget build(BuildContext context) {
    final visible =
        visibleSegmentIndices(context).where((i) {
          final segment = appSegments[i];
          return '${segment.label} ${segment.subtitle}'.toLowerCase().contains(
            _serviceQuery,
          );
        }).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _refreshHome,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(child: _buildGuestBanner(context)),
            SliverToBoxAdapter(child: _buildRoleModeToggle(context)),
            if (_serviceQuery.isEmpty)
              SliverToBoxAdapter(child: _buildStats(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: AppSearchField(
                  controller: _serviceSearch,
                  hint: 'Find products, workers, calculators...',
                  debounce: Duration.zero,
                  onChanged:
                      (value) =>
                          setState(() => _serviceQuery = value.toLowerCase()),
                ),
              ),
            ),
            if (_serviceQuery.isEmpty)
              SliverToBoxAdapter(child: _buildBanner()),
            SliverToBoxAdapter(
              child: _sectionHeader(
                'What do you need?',
                '${visible.length} services',
              ),
            ),
            if (visible.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No matching services. Try products, workers, jobs or funding.',
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final largeText =
                      MediaQuery.textScalerOf(context).scale(14) > 18;
                  return SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, pos) => _SegmentCard(
                        segment: appSegments[visible[pos]],
                        onTap: () => _navigate(context, visible[pos]),
                      ),
                      childCount: visible.length,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          largeText || constraints.crossAxisExtent < 340
                              ? 1
                              : constraints.crossAxisExtent > 700
                              ? 4
                              : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: largeText ? 165 : 130,
                    ),
                  );
                },
              ),
            ),
            if (_serviceQuery.isEmpty)
              SliverToBoxAdapter(child: _buildRecentActivity(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String sub) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111111),
            ),
          ),
          const Spacer(),
          Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF111111),
      surfaceTintColor: Colors.transparent,
      // The global AppBarTheme now sets an explicit white iconTheme (see
      // app_theme.dart) so orange app bars elsewhere render correctly — but
      // that's more specific than this widget's foregroundColor and would
      // otherwise win here too, making the menu/notification/profile icons
      // white-on-white and invisible against this screen's white app bar.
      iconTheme: const IconThemeData(color: Color(0xFF111111)),
      actionsIconTheme: const IconThemeData(color: Color(0xFF111111)),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111111),
      ),
      title: const Text('NEE'),
      leading: Builder(
        builder:
            (ctx) => IconButton(
              tooltip: 'Open menu',
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
      ),
      actions: [
        IconButton(
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => context.push('/notifications'),
        ),
        IconButton(
          tooltip: 'My profile',
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: () => context.push('/profile'),
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Row(
        children: [
          _statCard(
            Icons.inventory_2_outlined,
            _fmtStat(dash.totalProducts),
            'Products',
            const Color(0xFFE65100),
          ),
          const SizedBox(width: 10),
          _statCard(
            Icons.people_outline,
            _fmtStat(dash.totalWorkers),
            'Workers',
            const Color(0xFF1565C0),
          ),
          const SizedBox(width: 10),
          _statCard(
            Icons.trending_up,
            _fmtStat(dash.totalLeads),
            'Live Leads',
            const Color(0xFF2E7D32),
          ),
        ],
      ),
    );
  }

  String _fmtStat(int n) {
    if (n == 0) return '–';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K+';
    return '$n+';
  }

  Widget _statCard(IconData icon, String count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF98A2B3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A small countdown for guest accounts (7-day, no-leads preview), for any
  /// account still waiting on the retroactive/first-time approval review
  /// (same no-leads restriction, same 7-day grace window), and for a team-role
  /// trial (RoleRequestController::store's one-time 7-day trial — role is
  /// already e.g. 'telecaller' but guest_expires_at stays set until an admin
  /// actually approves/rejects the request, see RoleChangeRequestResource) —
  /// nothing shown once approved. Backend enforces the actual restriction
  /// (BlockGuestFromLeads); this is just visibility into the remaining time.
  Widget _buildGuestBanner(BuildContext context) {
    final profile = context.watch<AuthProvider>().user?.profile;
    final isGuest = profile?.role == 'guest';
    final isPending = profile?.isPendingApproval ?? false;
    final isTeamRoleTrial =
        !isGuest &&
        AppConstants.isTeamRole(profile?.role ?? '') &&
        profile?.guestExpiresAt != null;
    if (!isGuest && !isPending && !isTeamRoleTrial) {
      return const SizedBox.shrink();
    }

    final expiresAt =
        (isGuest || isTeamRoleTrial)
            ? profile?.guestExpiresAt
            : profile?.approvalDeadlineAt;
    final daysLeft = expiresAt?.difference(DateTime.now()).inDays.clamp(0, 7);
    final label =
        isTeamRoleTrial
            ? '${AppConstants.roleLabel(profile!.role)} trial — pending admin approval'
            : isGuest
            ? 'Guest access'
            : 'Account pending admin approval';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFE0B2)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.visibility_outlined,
              size: 18,
              color: Color(0xFFE65100),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                (() {
                  final suffix =
                      isTeamRoleTrial
                          ? 'Full access for now — reverts if not approved in time.'
                          : 'Leads are not visible in this mode.';
                  return daysLeft == null
                      ? '$label — $suffix'
                      : '$label: $daysLeft day${daysLeft == 1 ? '' : 's'} left. $suffix';
                })(),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8A5A00),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Quick-access toggle into whichever work mode matches the user's current
  /// role — Telecalling Mode for Area Managers, Field Visit Mode for Lead
  /// Managers, Team Dashboard for Associate Partners. Nothing shown for plain
  /// Buyer/Seller/Contractor/Worker accounts, since they have no such mode.
  /// Same destinations as the Settings tiles and the drawer entry, just
  /// surfaced where they're more likely to be seen right after opening the app.
  Widget _buildRoleModeToggle(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final config = roleModeConfig(user);
    if (config == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(config.route),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: config.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(config.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      config.subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() => const _OfferSlider();

  Widget _buildRecentActivity(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final auth = context.watch<AuthProvider>();
    final List<LeadModel> leads = dash.recentLeads;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111111),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed:
                    () => setState(() => _showAllActivity = !_showAllActivity),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _showAllActivity ? 'Show less' : 'See all',
                  style: TextStyle(color: Color(0xFFE65100), fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (auth.isAuthenticated)
            FutureBuilder<List<dynamic>>(
              future: _activityFuture ??= apiService.getUserActivity(),
              builder: (context, snapshot) {
                final activities = snapshot.data ?? [];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return ListTile(
                    title: const Text('Could not load recent activity'),
                    trailing: IconButton(
                      tooltip: 'Retry activity',
                      icon: const Icon(Icons.refresh),
                      onPressed: () => setState(_refreshRecentActivity),
                    ),
                  );
                }
                if (activities.isEmpty) {
                  return _activityTile(
                    Icons.touch_app_outlined,
                    'No activity yet',
                    'Tap products, leads, workers, jobs or funding',
                    'New',
                    const Color(0xFFE65100),
                  );
                }
                return Column(
                  children: [
                    for (final activity in activities.take(
                      _showAllActivity ? activities.length : 5,
                    ))
                      _activityTile(
                        _activityIcon(activity['action']?.toString() ?? ''),
                        _activityTitle(activity),
                        activity['entity_name']?.toString() ??
                            activity['entity_type']?.toString() ??
                            'User action',
                        _activityTime(activity['created_at']?.toString()),
                        _activityColor(
                          activity['entity_type']?.toString() ?? '',
                        ),
                      ),
                  ],
                );
              },
            )
          else if (leads.isEmpty && dash.loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (leads.isEmpty) ...[
            _activityTile(
              Icons.trending_up,
              'New Lead Posted',
              '2BHK Construction · ₹45L',
              'Recent',
              const Color(0xFF2E7D32),
            ),
            _activityTile(
              Icons.people,
              'Worker Available',
              'Electrician accepting bookings',
              'Recent',
              const Color(0xFF1565C0),
            ),
            _activityTile(
              Icons.inventory_2_outlined,
              'Products Listed',
              'Cement & Steel prices updated',
              'Recent',
              const Color(0xFFE65100),
            ),
          ] else
            for (final lead in leads.take(3))
              _activityTile(
                lead.isBuy ? Icons.trending_up : Icons.local_offer_outlined,
                lead.title,
                '${lead.projectType} · ${lead.location} · ₹${_fmtLeadVal(lead.value)}',
                lead.status,
                lead.isBuy ? const Color(0xFF2E7D32) : const Color(0xFF1565C0),
              ),
        ],
      ),
    );
  }

  IconData _activityIcon(String action) {
    if (action.startsWith('contact') || action.startsWith('call'))
      return Icons.phone_outlined;
    if (action.startsWith('hire')) return Icons.people_alt_outlined;
    if (action.startsWith('apply') || action.startsWith('enroll'))
      return Icons.assignment_turned_in_outlined;
    if (action.startsWith('view')) return Icons.visibility_outlined;
    return Icons.touch_app_outlined;
  }

  Color _activityColor(String type) => switch (type) {
    'product' => const Color(0xFFE65100),
    'worker' => const Color(0xFF1565C0),
    'lead' => const Color(0xFF2E7D32),
    'job' || 'course' => const Color(0xFFF57F17),
    'funding' => const Color(0xFF00695C),
    'contact' => const Color(0xFF37474F),
    _ => const Color(0xFFE65100),
  };

  String _activityTitle(dynamic activity) {
    final action =
        activity['action']?.toString().replaceAll('_', ' ') ?? 'Activity';
    return action
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }

  String _activityTime(String? raw) {
    if (raw == null) return 'Recent';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return 'Recent';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  String _fmtLeadVal(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  Widget _activityTile(
    IconData icon,
    String title,
    String sub,
    String time,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF98A2B3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(time, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
        ],
      ),
    );
  }

  Future<void> _navigate(BuildContext context, int index) async {
    await navigateToSegment(context, index);
    if (!mounted) return;
    setState(_refreshRecentActivity);
  }
}

// ─── Service Card ─────────────────────────────────────────────────────────────

class _SegmentCard extends StatelessWidget {
  final AppSegment segment;
  final VoidCallback onTap;
  const _SegmentCard({required this.segment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF98A2B3), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(segment.icon, color: segment.color, size: 24),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: segment.color,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                segment.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                segment.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF526071),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Offer Slider ─────────────────────────────────────────────────────────────

class _OfferSlide {
  final String tag,
      title,
      subtitle,
      ctaLabel,
      imageUrl,
      actionType,
      actionValue;
  final Color color;
  const _OfferSlide({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.imageUrl,
    this.actionType = 'none',
    this.actionValue = '',
    required this.color,
  });

  factory _OfferSlide.fromJson(Map<String, dynamic> json) {
    return _OfferSlide(
      tag: json['tag']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      ctaLabel: json['cta_label']?.toString() ?? 'Explore',
      imageUrl: json['image_url']?.toString() ?? '',
      actionType: json['action_type']?.toString() ?? 'none',
      actionValue: json['action_value']?.toString() ?? '',
      color: _parseHexColor(json['color']?.toString() ?? '#e65100'),
    );
  }

  static Color _parseHexColor(String value) {
    final hex = value.replaceAll('#', '');
    final normalized = hex.length == 6 ? 'ff$hex' : hex;
    return Color(int.tryParse(normalized, radix: 16) ?? 0xffe65100);
  }
}

class _OfferSlider extends StatefulWidget {
  const _OfferSlider();

  @override
  State<_OfferSlider> createState() => _OfferSliderState();
}

class _OfferSliderState extends State<_OfferSlider> {
  static const _fallbackSlides = [
    _OfferSlide(
      tag: 'LIMITED OFFER',
      title: 'Cement & Steel at\nFactory Prices',
      subtitle: 'Up to 18% off on bulk orders this week',
      ctaLabel: 'Shop Now',
      imageUrl:
          'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=800&h=320&fit=crop&auto=format',
      actionType: 'products',
      color: Color(0xFFE65100),
    ),
    _OfferSlide(
      tag: 'BUSINESS',
      title: 'Register Your Business\nin 3 Easy Steps',
      subtitle: 'Free GST + MSME + Trade License guidance',
      ctaLabel: 'Get Started',
      imageUrl:
          'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800&h=320&fit=crop&auto=format',
      actionType: 'business',
      color: Color(0xFF1565C0),
    ),
    _OfferSlide(
      tag: 'GOVT SCHEME',
      title: 'PM Mudra Loan\nUp to ₹10 Lakh',
      subtitle: 'No collateral needed. Apply in minutes.',
      ctaLabel: 'Apply Now',
      imageUrl:
          'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=800&h=320&fit=crop&auto=format',
      actionType: 'funding',
      color: Color(0xFF2E7D32),
    ),
    _OfferSlide(
      tag: 'MANPOWER',
      title: 'Hire Skilled Workers\nInstantly',
      subtitle: '890+ verified workers ready across Assam',
      ctaLabel: 'Find Workers',
      imageUrl:
          'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&h=320&fit=crop&auto=format',
      actionType: 'workers',
      color: Color(0xFF6A1B9A),
    ),
    _OfferSlide(
      tag: 'PROJECT LEADS',
      title: 'Post a Lead,\nGet 5 Free Quotes',
      subtitle: 'Connect with contractors in your district',
      ctaLabel: 'Post Lead',
      imageUrl:
          'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=800&h=320&fit=crop&auto=format',
      actionType: 'leads',
      color: Color(0xFF00695C),
    ),
  ];

  late final PageController _ctrl;
  Timer? _timer;
  int _current = 0;
  List<_OfferSlide> _slides = _fallbackSlides;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(viewportFraction: 0.92);
    _loadSlides();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_slides.isEmpty) return;
      _ctrl.animateToPage(
        (_current + 1) % _slides.length,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _loadSlides() async {
    try {
      final data = await apiService.getSliders();
      final slides =
          data
              .whereType<Map<String, dynamic>>()
              .map(_OfferSlide.fromJson)
              .where(
                (slide) => slide.title.isNotEmpty && slide.imageUrl.isNotEmpty,
              )
              .toList();

      if (!mounted || slides.isEmpty) return;
      setState(() {
        _slides = slides;
        _current = 0;
      });
    } catch (_) {
      // Keep the seeded mock slides visible if the backend is unavailable.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Column(
        children: [
          SizedBox(
            height: 185,
            child: PageView.builder(
              controller: _ctrl,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) => _buildSlide(_slides[i]),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              final active = i == _current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFE65100) : Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(_OfferSlide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              slide.imageUrl,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, _, _) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          slide.color,
                          slide.color.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    slide.color.withValues(alpha: 0.88),
                    slide.color.withValues(alpha: 0.35),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      slide.tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    slide.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    slide.subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.3,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _handleSlideAction(slide),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: slide.color,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(slide.ctaLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _slideActionFeatureKeys = {
    'products': 'products',
    'workers': 'manpower',
    'leads': 'leads',
    'funding': 'funding',
    'business': 'business',
    'jobs': 'jobs',
    'contacts': 'area_contacts',
  };

  Future<void> _handleSlideAction(_OfferSlide slide) async {
    if (slide.actionType == 'url' && slide.actionValue.isNotEmpty) {
      final uri = Uri.tryParse(slide.actionValue);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    final flagKey = _slideActionFeatureKeys[slide.actionType];
    if (flagKey != null) {
      final flags = context.read<AuthProvider>().user?.featureFlags ?? const {};
      if (!(flags[flagKey] ?? true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This feature is currently unavailable.'),
          ),
        );
        return;
      }
    }

    // The Market Place is customers-only (see visibleSegmentIndices) — an
    // admin-configured promo slide shouldn't route a team account there.
    if (slide.actionType == 'leads') {
      final role = context.read<AuthProvider>().user?.profile?.role ?? 'buyer';
      if (!AppConstants.canUseMarketplace(role)) return;
    }

    final screen = switch (slide.actionType) {
      'products' => const ProductsScreen(),
      'workers' => const ManpowerScreen(),
      'leads' => const LeadsScreen(),
      'funding' => const FundingScreen(),
      'business' => const BusinessScreen(),
      'jobs' => const JobsScreen(),
      'contacts' => const AreaContactsScreen(),
      _ => null,
    };

    if (screen == null) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
