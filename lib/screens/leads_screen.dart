import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/lead_model.dart';
import '../providers/lead_provider.dart';
import '../services/activity_service.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tab.removeListener(_handleTabChange);
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tab.indexIsChanging) return;
    _setLeadType(_tab.index);
  }

  void _setLeadType(int index) {
    final prov = context.read<LeadProvider>();
    final type = switch (index) {
      1 => 'buy',
      2 => 'sell',
      _ => null,
    };
    if (prov.typeFilter != type) {
      prov.setTypeFilter(type);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LeadProvider>(
      builder: (context, prov, _) => Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('Construction Leads'),
          bottom: TabBar(
            controller: _tab,
            onTap: _setLeadType,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [Tab(text: 'All'), Tab(text: 'Buy'), Tab(text: 'Sell')],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showPostLead(context, prov),
          backgroundColor: const Color(0xFF2E7D32),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Post Lead', style: TextStyle(color: Colors.white)),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: prov.setSearch,
                decoration: InputDecoration(
                  hintText: 'Search leads...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                          _searchCtrl.clear();
                          prov.setSearch('');
                        })
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  fillColor: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _LeadList(leads: prov.leads, loading: prov.loading, onRefresh: () => prov.fetch(refresh: true)),
                  _LeadList(leads: prov.leads, loading: prov.loading, onRefresh: () => prov.fetch(refresh: true)),
                  _LeadList(leads: prov.leads, loading: prov.loading, onRefresh: () => prov.fetch(refresh: true)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPostLead(BuildContext context, LeadProvider prov) {
    final titleCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String projectType = 'Residential';
    bool isBuy = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Post a Lead', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Lead Title')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: projectType,
                  items: ['Residential', 'Commercial', 'Industrial', 'Infrastructure', 'Renovation', 'Interior']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setModalState(() => projectType = v!),
                  decoration: const InputDecoration(labelText: 'Project Type'),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextField(controller: valueCtrl, keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Value (₹)'))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: locationCtrl,
                      decoration: const InputDecoration(labelText: 'Location'))),
                ]),
                const SizedBox(height: 10),
                TextField(controller: contactCtrl, keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Contact Number')),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 10),
                Row(children: [
                  const Text('Type: '),
                  ChoiceChip(label: const Text('Buy'), selected: isBuy,
                      onSelected: (_) => setModalState(() => isBuy = true),
                      selectedColor: const Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  ChoiceChip(label: const Text('Sell'), selected: !isBuy,
                      onSelected: (_) => setModalState(() => isBuy = false),
                      selectedColor: const Color(0xFF1565C0)),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                    onPressed: () async {
                      if (titleCtrl.text.isEmpty || valueCtrl.text.isEmpty) return;
                      Navigator.pop(ctx);
                      final created = await prov.createLead({
                        'title': titleCtrl.text,
                        'project_type': projectType,
                        'value': double.tryParse(valueCtrl.text) ?? 0,
                        'location': locationCtrl.text,
                        'contact': contactCtrl.text,
                        'description': descCtrl.text,
                        'is_buy': isBuy,
                      });
                      if (created) {
                        activityService.log(
                          'post_lead',
                          entityType: 'lead',
                          entityName: titleCtrl.text,
                          extra: {'type': isBuy ? 'buy' : 'sell', 'project_type': projectType},
                        );
                      }
                    },
                    child: const Text('Submit Lead'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeadList extends StatelessWidget {
  final List<LeadModel> leads;
  final bool loading;
  final Future<void> Function() onRefresh;

  const _LeadList({required this.leads, required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (leads.isEmpty && loading) return const Center(child: CircularProgressIndicator());
    if (leads.isEmpty) return const Center(child: Text('No leads found'));

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: leads.length,
        itemBuilder: (_, i) => _LeadCard(lead: leads[i]),
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final LeadModel lead;
  const _LeadCard({required this.lead});

  static const _typeColors = {
    'Residential': Color(0xFF1565C0),
    'Commercial': Color(0xFF6A1B9A),
    'Industrial': Color(0xFF37474F),
    'Infrastructure': Color(0xFF2E7D32),
    'Renovation': Color(0xFFE65100),
    'Interior': Color(0xFF00695C),
  };

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[lead.projectType] ?? const Color(0xFF2E7D32);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(lead.projectType,
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: lead.isBuy ? Colors.green.withAlpha(25) : Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(lead.isBuy ? 'BUY' : 'SELL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: lead.isBuy ? Colors.green[700] : Colors.blue[700],
                  )),
            ),
            const Spacer(),
            Text('₹${_formatValue(lead.value)}',
                style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          const SizedBox(height: 8),
          Text(lead.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          if (lead.description != null) ...[
            const SizedBox(height: 4),
            Text(lead.description!,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.location_on, size: 13, color: Colors.grey),
            Text(lead.location, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const Spacer(),
            if (lead.postedBy != null)
              Text('By ${lead.postedBy}', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showDetails(context, color),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: color),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text('View Details', style: TextStyle(color: color, fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _contact(context, color),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Contact', style: TextStyle(fontSize: 12)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  String _formatValue(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  void _showDetails(BuildContext context, Color color) {
    activityService.log('view_lead', entityType: 'lead', entityId: lead.id, entityName: lead.title);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(4)),
                child: Text(lead.projectType, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: lead.isBuy ? Colors.green.withAlpha(25) : Colors.blue.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(lead.isBuy ? 'BUY' : 'SELL',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                        color: lead.isBuy ? Colors.green[700] : Colors.blue[700])),
              ),
            ]),
            const SizedBox(height: 12),
            Text(lead.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(lead.location, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ]),
            const SizedBox(height: 12),
            Text('₹${_formatValue(lead.value)}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            if (lead.description != null) ...[
              const SizedBox(height: 12),
              Text('Description', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              Text(lead.description!, style: TextStyle(color: Colors.grey[600], height: 1.5)),
            ],
            if (lead.postedBy != null) ...[
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Posted by ${lead.postedBy}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ]),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () { Navigator.pop(context); _contact(context, color); },
                icon: const Icon(Icons.phone),
                label: const Text('Contact Now'),
                style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 13)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _contact(BuildContext context, Color color) {
    final phone = lead.contact;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contact number available')));
      return;
    }
    activityService.log('contact_lead', entityType: 'lead', entityId: lead.id, entityName: lead.title,
        extra: {'phone': phone});
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withAlpha(15), shape: BoxShape.circle),
            child: Icon(Icons.phone, color: color, size: 36),
          ),
          const SizedBox(height: 12),
          Text(lead.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(phone, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), ''));
                  if (await canLaunchUrl(uri)) launchUrl(uri);
                },
                icon: const Icon(Icons.phone),
                label: const Text('Call Now'),
                style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color),
                    padding: const EdgeInsets.symmetric(vertical: 13)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
                  final uri = Uri.parse('https://wa.me/91$clean');
                  if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.chat),
                label: const Text('WhatsApp'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366),
                    padding: const EdgeInsets.symmetric(vertical: 13)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
