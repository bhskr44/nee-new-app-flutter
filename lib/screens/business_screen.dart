import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class BusinessScreen extends StatelessWidget {
  const BusinessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Start Your Business')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildHero(),
          _buildStats(),
          const _SectionHeader('Choose Your Business Type'),
          ...mockBusinessTypes.map((b) => _BusinessCard(type: b)),
          const _SectionHeader('Why Start in Construction?'),
          _buildWhyCards(),
          const _SectionHeader('Government Support Available'),
          _buildGovtSupport(),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFC62828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(20)),
            child: const Text('India\'s Fastest Growing Sector', style: TextStyle(color: Colors.white, fontSize: 11)),
          ),
          const SizedBox(height: 12),
          const Text('Launch Your Construction\nBusiness Today', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.3)),
          const SizedBox(height: 8),
          const Text('Step-by-step guidance, funding support\nand a ready market waiting for you.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFFC62828)),
            child: const Text('Get Free Consultation', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(children: [
        _statBox('₹11 Lakh Cr', 'Industry Size 2026', const Color(0xFFC62828)),
        const SizedBox(width: 10),
        _statBox('7.5 Crore+', 'Jobs in Construction', const Color(0xFF1565C0)),
        const SizedBox(width: 10),
        _statBox('15–35%', 'Typical Margins', const Color(0xFF2E7D32)),
      ]),
    );
  }

  Widget _statBox(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildWhyCards() {
    const items = [
      ('📈', 'High Demand', 'India needs 11 crore new homes by 2030. Massive opportunity.'),
      ('🏛️', 'Govt Push', 'Smart Cities, PMAY, infra budget ₹11L crore creates constant work.'),
      ('💰', 'Good Margins', '15–35% margins on projects. Cash flow positive within months.'),
      ('🤝', 'Network Effect', 'One satisfied client brings 3–5 referrals in construction.'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.2,
        children: items.map((item) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(item.$1, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(item.$2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(item.$3, style: TextStyle(color: Colors.grey[600], fontSize: 11, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis),
          ]),
        )).toList(),
      ),
    );
  }

  Widget _buildGovtSupport() {
    const items = [
      (Icons.account_balance, 'PM Mudra Yojana', 'Loans up to ₹10L with no collateral for small businesses.', Color(0xFF1565C0)),
      (Icons.handshake, 'PMEGP Scheme', '15–35% capital subsidy for manufacturing businesses.', Color(0xFF2E7D32)),
      (Icons.verified, 'Udyam Registration', 'Free MSME registration — unlocks priority lending & tenders.', Color(0xFF6A1B9A)),
      (Icons.construction, 'GeM Portal', 'Sell directly to Govt — ₹2L Cr+ in annual procurement.', Color(0xFFE65100)),
    ];
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 5)]),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: item.$4.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                child: Icon(item.$1, color: item.$4, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.$2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 3),
              Text(item.$3, style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.3)),
            ])),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ]),
        );
      },
    );
  }
}

class _BusinessCard extends StatelessWidget {
  final BusinessType type;
  const _BusinessCard({required this.type});

  static const _businessImages = {
    'Construction Contractor': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=600&h=200&fit=crop&auto=format',
    'Building Material Supply': 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=600&h=200&fit=crop&auto=format',
    'Manpower Agency': 'https://images.unsplash.com/photo-1486325212027-8081e485255e?w=600&h=200&fit=crop&auto=format',
    'Interior Design Firm': 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=600&h=200&fit=crop&auto=format',
  };

  String get _imageUrl => _businessImages[type.name] ?? 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=600&h=200&fit=crop&auto=format';

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetail(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        ColoredBox(color: type.color.withValues(alpha: 0.2)),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          type.color.withValues(alpha: 0.3),
                          type.color.withValues(alpha: 0.88),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12, left: 14, right: 14,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(type.name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 2),
                              Text(type.description,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(type.icon,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _pill(Icons.currency_rupee,
                        'Investment: ${type.minInvestment} – ${type.maxInvestment}',
                        Colors.blue),
                    const SizedBox(width: 8),
                    _pill(Icons.trending_up, type.returns, Colors.green),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showDetail(context),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: type.color,
                            padding:
                                const EdgeInsets.symmetric(vertical: 10)),
                        child: const Text('View Guide',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                          foregroundColor: type.color,
                          side: BorderSide(color: type.color),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10)),
                      child: const Text('Talk to Expert',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Expanded(child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: type.color.withAlpha(25), borderRadius: BorderRadius.circular(12)),
                  child: Icon(type.icon, color: type.color, size: 28)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(type.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(type.returns, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ])),
            ]),
            const SizedBox(height: 14),
            Text(type.description, style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 14)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _infoBox('Min Investment', type.minInvestment, Icons.arrow_downward, Colors.green)),
              const SizedBox(width: 10),
              Expanded(child: _infoBox('Max Investment', type.maxInvestment, Icons.arrow_upward, Colors.orange)),
            ]),
            const SizedBox(height: 16),
            const Text('Steps to Start', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...type.steps.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(radius: 12, backgroundColor: type.color, child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 11))),
                const SizedBox(width: 10),
                Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13, height: 1.4))),
              ]),
            )),
            const SizedBox(height: 16),
            const Text('Documents Required', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...type.documents.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Icon(Icons.check_circle, color: type.color, size: 16),
                const SizedBox(width: 8),
                Text(d, style: const TextStyle(fontSize: 13)),
              ]),
            )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: type.color, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Start This Business Journey'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _infoBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF212121))),
    );
  }
}
