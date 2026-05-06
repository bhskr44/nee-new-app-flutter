import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buyLeads = mockLeads.where((l) => l.isBuy).toList();
    final sellLeads = mockLeads.where((l) => !l.isBuy).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Construction Leads'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Leads'),
            Tab(text: 'Buy'),
            Tab(text: 'Sell'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPostLead(context),
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Post a Lead', style: TextStyle(color: Colors.white)),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _LeadList(leads: mockLeads),
          _LeadList(leads: buyLeads),
          _LeadList(leads: sellLeads),
        ],
      ),
    );
  }

  void _showPostLead(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Post a Lead', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Share your project requirement or sell a lead', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Project Title')),
            const SizedBox(height: 10),
            const TextField(decoration: InputDecoration(labelText: 'Project Type (Residential/Commercial...)')),
            const SizedBox(height: 10),
            const TextField(decoration: InputDecoration(labelText: 'Location')),
            const SizedBox(height: 10),
            const TextField(keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Estimated Value (₹)')),
            const SizedBox(height: 10),
            const TextField(
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF2E7D32), side: const BorderSide(color: Color(0xFF2E7D32))),
                  child: const Text('Post to Sell'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                  child: const Text('Post to Buy'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _LeadList extends StatelessWidget {
  final List<Lead> leads;
  const _LeadList({required this.leads});

  @override
  Widget build(BuildContext context) {
    if (leads.isEmpty) return const Center(child: Text('No leads found'));
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 90),
      itemCount: leads.length,
      itemBuilder: (_, i) => _LeadCard(lead: leads[i]),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final Lead lead;
  const _LeadCard({required this.lead});

  static const _typeIcons = {
    'New Construction': Icons.home_work,
    'Renovation': Icons.home_repair_service,
    'Commercial': Icons.business,
    'Industrial': Icons.factory,
    'Institutional': Icons.account_balance,
    'Painting': Icons.format_paint,
    'Plumbing': Icons.water,
    'False Ceiling': Icons.layers,
  };

  static const _typeColors = {
    'New Construction': Color(0xFF1565C0),
    'Renovation': Color(0xFF6A1B9A),
    'Commercial': Color(0xFF2E7D32),
    'Industrial': Color(0xFF37474F),
    'Institutional': Color(0xFF00695C),
    'Painting': Color(0xFFE65100),
    'Plumbing': Color(0xFF1976D2),
    'False Ceiling': Color(0xFF283593),
  };

  static const _typeImages = {
    'New Construction': 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=600&h=180&fit=crop&auto=format',
    'Renovation': 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=600&h=180&fit=crop&auto=format',
    'Commercial': 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=600&h=180&fit=crop&auto=format',
    'Industrial': 'https://images.unsplash.com/photo-1486325212027-8081e485255e?w=600&h=180&fit=crop&auto=format',
    'Institutional': 'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=600&h=180&fit=crop&auto=format',
    'Painting': 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=600&h=180&fit=crop&auto=format',
    'Plumbing': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&h=180&fit=crop&auto=format',
    'False Ceiling': 'https://images.unsplash.com/photo-1600585152220-90363fe7e115?w=600&h=180&fit=crop&auto=format',
  };

  Color get _color => _typeColors[lead.projectType] ?? const Color(0xFF455A64);
  IconData get _icon => _typeIcons[lead.projectType] ?? Icons.construction;
  String get _imageUrl => _typeImages[lead.projectType] ?? 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=600&h=180&fit=crop&auto=format';

  String _formatValue(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)} Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)} L';
    return '₹${v.toStringAsFixed(0)}';
  }

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
              height: 110,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        ColoredBox(color: _color.withValues(alpha: 0.2)),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _color.withValues(alpha: 0.3),
                          _color.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(_formatValue(lead.value),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _color)),
                    ),
                  ),
                  Positioned(
                    bottom: 10, left: 12, right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lead.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4)),
                            child: Text(lead.projectType,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: lead.isBuy
                                    ? Colors.blue.shade700
                                    : Colors.green.shade700,
                                borderRadius: BorderRadius.circular(4)),
                            child: Text(lead.isBuy ? 'BUY' : 'SELL',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const Spacer(),
                          Icon(_icon, color: Colors.white54, size: 18),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lead.description,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 13, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 3),
                    Expanded(
                        child: Text(lead.location,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12))),
                    const Icon(Icons.access_time, size: 12, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text(lead.postedDate,
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    _statusChip(lead.status),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          side: const BorderSide(color: Color(0xFFE65100)),
                          foregroundColor: const Color(0xFFE65100),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6))),
                      child: const Text('View Details',
                          style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _showContact(context),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6))),
                      child:
                          const Text('Contact', style: TextStyle(fontSize: 12)),
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

  Widget _statusChip(String status) {
    final colors = {'Active': Colors.green, 'Negotiating': Colors.orange, 'Available': Colors.blue, 'Closed': Colors.grey};
    final c = colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withAlpha(25), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(status, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(lead.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _row('Type', lead.projectType),
            _row('Location', lead.location),
            _row('Est. Value', _formatValue(lead.value)),
            _row('Status', lead.status),
            _row('Posted', lead.postedDate),
            const SizedBox(height: 12),
            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(lead.description, style: TextStyle(color: Colors.grey[600], height: 1.5)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.phone),
                label: const Text('Contact Now'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showContact(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Contact Details'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.phone)),
            title: const Text('Call Now'),
            subtitle: Text(lead.contact),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.chat, color: Colors.white)),
            title: const Text('WhatsApp'),
            subtitle: Text(lead.contact),
            onTap: () => Navigator.pop(context),
          ),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      ]),
    );
  }
}
