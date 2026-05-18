import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/dashboard_provider.dart';
import '../providers/auth_provider.dart';
import '../models/lead_model.dart';
import '../services/api_service.dart';
import 'products_screen.dart';
import 'manpower_screen.dart';
import 'leads_screen.dart';
import 'calculator_screen.dart';
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
  static const _segments = [
    _Segment('Construction Products', Icons.construction, Color(0xFFE65100), 'Cement, Steel, Bricks & More'),
    _Segment('Construction Manpower', Icons.people_alt_outlined, Color(0xFF1565C0), 'Skilled Workers On-Demand'),
    _Segment('Market Place', Icons.storefront, Color(0xFF2E7D32), 'Buy & Sell Project Leads'),
    _Segment('Construction Calculator', Icons.calculate_outlined, Color(0xFF6A1B9A), 'Civil, Interior, Tiles & Paint'),
    _Segment('Funding Support', Icons.account_balance_outlined, Color(0xFF00695C), 'Loans & Govt. Schemes'),
    _Segment('Start Your Business', Icons.rocket_launch_outlined, Color(0xFFC62828), 'Launch Your Venture'),
    _Segment('Jobs & Training', Icons.school_outlined, Color(0xFFF57F17), 'Find Jobs, Upskill Today'),
    _Segment('Area Contacts', Icons.location_on_outlined, Color(0xFF37474F), 'District-Wise Contact Persons'),
  ];

  Future<List<dynamic>>? _activityFuture;

  @override
  void initState() {
    super.initState();
  }

  void _refreshRecentActivity() {
    _activityFuture = apiService.getUserActivity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      drawer: _buildDrawer(context),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(child: _buildStats(context)),
          SliverToBoxAdapter(child: _buildBanner()),
          SliverToBoxAdapter(child: _sectionHeader('Our Services', '${_segments.length} categories')),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _SegmentCard(segment: _segments[i], onTap: () => _navigate(context, i)),
                childCount: _segments.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 180,
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildRecentActivity(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String sub) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF111111))),
        const Spacer(),
        Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ]),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 190,
      pinned: true,
      backgroundColor: const Color(0xFFBF360C),
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () => context.push('/notifications'),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => context.push('/profile'),
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8B1A00), Color(0xFFBF360C), Color(0xFFE65100)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -30, top: -20,
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                right: 40, bottom: -40,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                left: 20, right: 20, bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.verified_rounded, color: Colors.white, size: 11),
                        SizedBox(width: 5),
                        Text("India's #1 Construction Platform",
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    const Text('NEE Construction',
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    const SizedBox(height: 3),
                    Text('Your Complete Construction Partner',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Row(children: [
        _statCard(Icons.inventory_2_outlined, _fmtStat(dash.totalProducts), 'Products', const Color(0xFFE65100)),
        const SizedBox(width: 10),
        _statCard(Icons.people_outline, _fmtStat(dash.totalWorkers), 'Workers', const Color(0xFF1565C0)),
        const SizedBox(width: 10),
        _statCard(Icons.trending_up, _fmtStat(dash.totalLeads), 'Live Leads', const Color(0xFF2E7D32)),
      ]),
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            ]),
          ),
        ]),
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
          Row(children: [
            const Text('Recent Activity',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF111111))),
            const Spacer(),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('See all', style: TextStyle(color: Color(0xFFE65100), fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 8),
          if (auth.isAuthenticated)
            FutureBuilder<List<dynamic>>(
              future: _activityFuture ??= apiService.getUserActivity(),
              builder: (context, snapshot) {
                final activities = snapshot.data ?? [];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(),
                  ));
                }
                if (activities.isEmpty) {
                  return _activityTile(Icons.touch_app_outlined, 'No activity yet',
                      'Tap products, leads, workers, jobs or funding', 'New', const Color(0xFFE65100));
                }
                return Column(
                  children: [
                    for (final activity in activities.take(5))
                      _activityTile(
                        _activityIcon(activity['action']?.toString() ?? ''),
                        _activityTitle(activity),
                        activity['entity_name']?.toString() ?? activity['entity_type']?.toString() ?? 'User action',
                        _activityTime(activity['created_at']?.toString()),
                        _activityColor(activity['entity_type']?.toString() ?? ''),
                      ),
                  ],
                );
              },
            )
          else if (leads.isEmpty && dash.loading)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(),
            ))
          else if (leads.isEmpty) ...[
            _activityTile(Icons.trending_up, 'New Lead Posted',
                '2BHK Construction · ₹45L', 'Recent', const Color(0xFF2E7D32)),
            _activityTile(Icons.people, 'Worker Available',
                'Electrician accepting bookings', 'Recent', const Color(0xFF1565C0)),
            _activityTile(Icons.inventory_2_outlined, 'Products Listed',
                'Cement & Steel prices updated', 'Recent', const Color(0xFFE65100)),
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
    if (action.startsWith('contact') || action.startsWith('call')) return Icons.phone_outlined;
    if (action.startsWith('hire')) return Icons.people_alt_outlined;
    if (action.startsWith('apply') || action.startsWith('enroll')) return Icons.assignment_turned_in_outlined;
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
    final action = activity['action']?.toString().replaceAll('_', ' ') ?? 'Activity';
    return action.split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
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

  Widget _activityTile(IconData icon, String title, String sub, String time, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF111111))),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(color: Colors.grey[500], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        const SizedBox(width: 8),
        Text(time, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
      ]),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final userName = user?.name ?? 'NEE User';
    final userSub = [
      if (user?.profile?.city != null) user!.profile!.city!,
    ].join(' · ');

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B1A00), Color(0xFFE65100)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  userName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Text(userName,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                userSub.isNotEmpty ? userSub : (user?.email ?? ''),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 13),
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (int i = 0; i < _segments.length; i++)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: _segments[i].color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_segments[i].icon, color: _segments[i].color, size: 19),
                    ),
                    title: Text(_segments[i].label, style: const TextStyle(fontSize: 14)),
                    onTap: () {
                      Navigator.pop(context);
                      _navigate(context, i);
                    },
                  ),
                const Divider(height: 24, indent: 16, endIndent: 16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const Icon(Icons.settings_outlined, size: 21, color: Color(0xFF555555)),
                  title: const Text('Settings', style: TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/settings');
                  },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const Icon(Icons.help_outline, size: 21, color: Color(0xFF555555)),
                  title: const Text('Help & Support', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('+91 70020 13244', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context);
                    launchUrl(
                      Uri.parse('https://wa.me/917002013244'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigate(BuildContext context, int index) async {
    final screens = [
      const ProductsScreen(),
      const ManpowerScreen(),
      const LeadsScreen(),
      const CalculatorScreen(),
      const FundingScreen(),
      const BusinessScreen(),
      const JobsScreen(),
      const AreaContactsScreen(),
    ];
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screens[index]));
    if (!mounted) return;
    context.read<DashboardProvider>().init();
    setState(_refreshRecentActivity);
  }
}

// ─── Data ─────────────────────────────────────────────────────────────────────

class _Segment {
  final String label, subtitle;
  final IconData icon;
  final Color color;
  const _Segment(this.label, this.icon, this.color, this.subtitle);
}

// ─── Service Card ─────────────────────────────────────────────────────────────

class _SegmentCard extends StatelessWidget {
  final _Segment segment;
  final VoidCallback onTap;
  const _SegmentCard({required this.segment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: segment.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(segment.icon, color: segment.color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              segment.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111111), height: 1.3),
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            Text(
              segment.subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(children: [
              Text('Explore', style: TextStyle(color: segment.color, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 3),
              Icon(Icons.arrow_forward_rounded, color: segment.color, size: 13),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─── Offer Slider ─────────────────────────────────────────────────────────────

class _OfferSlide {
  final String tag, title, subtitle, ctaLabel, imageUrl, actionType, actionValue;
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
      imageUrl: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=800&h=320&fit=crop&auto=format',
      actionType: 'products',
      color: Color(0xFFE65100),
    ),
    _OfferSlide(
      tag: 'BUSINESS',
      title: 'Register Your Business\nin 3 Easy Steps',
      subtitle: 'Free GST + MSME + Trade License guidance',
      ctaLabel: 'Get Started',
      imageUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800&h=320&fit=crop&auto=format',
      actionType: 'business',
      color: Color(0xFF1565C0),
    ),
    _OfferSlide(
      tag: 'GOVT SCHEME',
      title: 'PM Mudra Loan\nUp to ₹10 Lakh',
      subtitle: 'No collateral needed. Apply in minutes.',
      ctaLabel: 'Apply Now',
      imageUrl: 'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=800&h=320&fit=crop&auto=format',
      actionType: 'funding',
      color: Color(0xFF2E7D32),
    ),
    _OfferSlide(
      tag: 'MANPOWER',
      title: 'Hire Skilled Workers\nInstantly',
      subtitle: '890+ verified workers ready across Assam',
      ctaLabel: 'Find Workers',
      imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&h=320&fit=crop&auto=format',
      actionType: 'workers',
      color: Color(0xFF6A1B9A),
    ),
    _OfferSlide(
      tag: 'PROJECT LEADS',
      title: 'Post a Lead,\nGet 5 Free Quotes',
      subtitle: 'Connect with contractors in your district',
      ctaLabel: 'Post Lead',
      imageUrl: 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=800&h=320&fit=crop&auto=format',
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
      final slides = data
          .whereType<Map<String, dynamic>>()
          .map(_OfferSlide.fromJson)
          .where((slide) => slide.title.isNotEmpty && slide.imageUrl.isNotEmpty)
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
              errorBuilder: (_, _, _) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [slide.color, slide.color.withValues(alpha: 0.7)],
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(slide.tag,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  ),
                  const SizedBox(height: 8),
                  Text(slide.title,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, height: 1.25)),
                  const SizedBox(height: 5),
                  Text(slide.subtitle,
                      style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3), maxLines: 2),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _handleSlideAction(slide),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: slide.color,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Future<void> _handleSlideAction(_OfferSlide slide) async {
    if (slide.actionType == 'url' && slide.actionValue.isNotEmpty) {
      final uri = Uri.tryParse(slide.actionValue);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
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
