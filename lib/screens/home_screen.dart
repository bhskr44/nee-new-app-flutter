import 'dart:async';
import 'package:flutter/material.dart';
import 'products_screen.dart';
import 'manpower_screen.dart';
import 'leads_screen.dart';
import 'calculator_screen.dart';
import 'funding_screen.dart';
import 'business_screen.dart';
import 'jobs_screen.dart';
import 'area_contacts_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _segments = [
    _Segment(
      'Construction\nProducts',
      Icons.construction,
      Color(0xFFE65100),
      'Cement, Steel, Bricks & More',
      'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400&h=300&fit=crop&auto=format',
    ),
    _Segment(
      'Construction\nManpower',
      Icons.people,
      Color(0xFF1565C0),
      'Skilled Workers On-Demand',
      'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&h=300&fit=crop&auto=format',
    ),
    _Segment(
      'Construction\nLeads',
      Icons.trending_up,
      Color(0xFF2E7D32),
      'Buy & Sell Project Leads',
      'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=400&h=300&fit=crop&auto=format',
    ),
    _Segment(
      'Construction\nCalculator',
      Icons.calculate,
      Color(0xFF6A1B9A),
      'Civil, Interior, Tiles, Paint',
      'https://images.unsplash.com/photo-1486325212027-8081e485255e?w=400&h=300&fit=crop&auto=format',
    ),
    _Segment(
      'Funding\nSupport',
      Icons.account_balance,
      Color(0xFF00695C),
      'Loans & Govt. Schemes',
      'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=400&h=300&fit=crop&auto=format',
    ),
    _Segment(
      'Start Your\nBusiness',
      Icons.rocket_launch,
      Color(0xFFC62828),
      'Launch Your Venture',
      'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=400&h=300&fit=crop&auto=format',
    ),
    _Segment(
      'Jobs &\nTraining',
      Icons.school,
      Color(0xFFF57F17),
      'Find Jobs, Upskill Today',
      'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=400&h=300&fit=crop&auto=format',
    ),
    _Segment(
      'Area\nContacts',
      Icons.location_on,
      Color(0xFF37474F),
      'District-Wise Contact Persons',
      'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=400&h=300&fit=crop&auto=format',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: _buildDrawer(context),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(child: _buildStats()),
          SliverToBoxAdapter(child: _buildBanner()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _SegmentCard(
                  segment: _segments[i],
                  onTap: () => _navigate(context, i),
                ),
                childCount: _segments.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildRecentActivity()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 190,
      pinned: true,
      backgroundColor: const Color(0xFFE65100),
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {},
        ),
        const CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white24,
          child: Icon(Icons.person, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=800&h=400&fit=crop&auto=format',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFFBF360C)),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xD8BF360C), Color(0xB8E65100)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        child: Text(
                          "INDIA'S #1 CONSTRUCTION PLATFORM",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'NEE Construction',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your Complete Construction Platform',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return ColoredBox(
      color: const Color(0xFFBF360C),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Row(
          children: [
            _statPill(Icons.inventory_2, '2,340+', 'Products'),
            const SizedBox(width: 8),
            _statPill(Icons.people, '892', 'Workers'),
            const SizedBox(width: 8),
            _statPill(Icons.trending_up, '456', 'Live Leads'),
          ],
        ),
      ),
    );
  }

  Widget _statPill(IconData icon, String count, String label) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(count,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  Text(label,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() => const _OfferSlider();

  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Recent Activity',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121))),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('See all',
                    style: TextStyle(color: Color(0xFFE65100), fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _activityTile(Icons.trending_up, 'New Lead Posted',
              '2BHK Construction — Bengaluru · ₹45L', '2 min ago'),
          _activityTile(Icons.people, 'Worker Available',
              'Senthil Vel (Electrician) is accepting bookings', '15 min ago'),
          _activityTile(Icons.inventory_2, 'Price Update',
              'Cement prices updated for May 2026', '1 hr ago'),
        ],
      ),
    );
  }

  Widget _activityTile(IconData icon, String title, String sub, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                const Color(0xFFE65100).withValues(alpha: 0.1),
            child: Icon(icon, color: const Color(0xFFE65100), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(sub,
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Text(time,
              style: TextStyle(color: Colors.grey[400], fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400&h=200&fit=crop&auto=format',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFBF360C), Color(0xFFE65100)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xCC000000), Color(0x88BF360C)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person,
                              color: Colors.white, size: 30),
                        ),
                        const SizedBox(height: 8),
                        const Text('Rajan Kumar',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Text('Contractor · Bengaluru',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (int i = 0; i < _segments.length; i++)
                  ListTile(
                    leading: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _segments[i]
                            .color
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(_segments[i].icon,
                            color: _segments[i].color, size: 18),
                      ),
                    ),
                    title: Text(
                        _segments[i].label.replaceAll('\n', ' '),
                        style: const TextStyle(fontSize: 14)),
                    onTap: () {
                      Navigator.pop(context);
                      _navigate(context, i);
                    },
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title:
                      const Text('Settings', style: TextStyle(fontSize: 14)),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Support',
                      style: TextStyle(fontSize: 14)),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
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
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => screens[index]));
  }
}

class _Segment {
  final String label;
  final IconData icon;
  final Color color;
  final String subtitle;
  final String imageUrl;
  const _Segment(
      this.label, this.icon, this.color, this.subtitle, this.imageUrl);
}

// ── Offer Slider ─────────────────────────────────────────────────────────────

class _OfferSlide {
  final String tag, title, subtitle, ctaLabel, imageUrl;
  final Color color;
  const _OfferSlide({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.imageUrl,
    required this.color,
  });
}

class _OfferSlider extends StatefulWidget {
  const _OfferSlider();

  @override
  State<_OfferSlider> createState() => _OfferSliderState();
}

class _OfferSliderState extends State<_OfferSlider> {
  static const _slides = [
    _OfferSlide(
      tag: '🏷️ LIMITED OFFER',
      title: 'Cement & Steel at\nFactory Prices',
      subtitle: 'Up to 18% off on bulk orders this week',
      ctaLabel: 'Shop Now',
      imageUrl: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=800&h=320&fit=crop&auto=format',
      color: Color(0xFFE65100),
    ),
    _OfferSlide(
      tag: '🏢 BUSINESS',
      title: 'Register Your Business\nin 3 Easy Steps',
      subtitle: 'Free GST + MSME + Trade License guidance',
      ctaLabel: 'Get Started',
      imageUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800&h=320&fit=crop&auto=format',
      color: Color(0xFF1565C0),
    ),
    _OfferSlide(
      tag: '🏛️ GOVT SCHEME',
      title: 'PM Mudra Loan\nUp to ₹10 Lakh',
      subtitle: 'No collateral needed. Apply in minutes.',
      ctaLabel: 'Apply Now',
      imageUrl: 'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=800&h=320&fit=crop&auto=format',
      color: Color(0xFF2E7D32),
    ),
    _OfferSlide(
      tag: '👷 MANPOWER',
      title: 'Hire Skilled Workers\nInstantly',
      subtitle: '890+ verified workers ready across Assam',
      ctaLabel: 'Find Workers',
      imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&h=320&fit=crop&auto=format',
      color: Color(0xFF6A1B9A),
    ),
    _OfferSlide(
      tag: '📋 LEADS',
      title: 'Post a Project Lead,\nGet 5 Free Quotes',
      subtitle: 'Connect with contractors in your district',
      ctaLabel: 'Post Lead',
      imageUrl: 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=800&h=320&fit=crop&auto=format',
      color: Color(0xFF00695C),
    ),
  ];

  late final PageController _ctrl;
  Timer? _timer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(viewportFraction: 0.92);
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_current + 1) % _slides.length;
      _ctrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
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
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Column(
        children: [
          SizedBox(
            height: 165,
            child: PageView.builder(
              controller: _ctrl,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) => _buildSlide(_slides[i]),
            ),
          ),
          const SizedBox(height: 10),
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
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              slide.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(color: slide.color),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    slide.color.withValues(alpha: 0.88),
                    slide.color.withValues(alpha: 0.42),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      slide.tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    slide.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    slide.subtitle,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11, height: 1.3),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: slide.color,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
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
}

class _SegmentCard extends StatelessWidget {
  final _Segment segment;
  final VoidCallback onTap;
  const _SegmentCard({required this.segment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: segment.color.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                segment.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        segment.color.withValues(alpha: 0.6),
                        segment.color,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      segment.color.withValues(alpha: 0.4),
                      segment.color.withValues(alpha: 0.88),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(segment.icon,
                            color: Colors.white, size: 22),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      segment.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      segment.subtitle,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
