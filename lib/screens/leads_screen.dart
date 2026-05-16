import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/lead_model.dart';
import '../providers/lead_provider.dart';
import '../services/activity_service.dart';
import '../services/api_service.dart';

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
    List<XFile> pickedImages = [];
    final picker = ImagePicker();

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
                    decoration: const InputDecoration(labelText: 'Description (optional)')),
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
                const SizedBox(height: 14),
                // Photo picker
                Text('Photos (optional)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ...pickedImages.asMap().entries.map((e) => Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 76, height: 76,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: FutureBuilder(
                                future: e.value.readAsBytes(),
                                builder: (_, snap) => snap.hasData
                                    ? Image.memory(snap.requireData, fit: BoxFit.cover)
                                    : Container(color: Colors.grey[200]),
                              ),
                            ),
                          ),
                          Positioned(
                            top: -4, right: 4,
                            child: GestureDetector(
                              onTap: () => setModalState(() => pickedImages.removeAt(e.key)),
                              child: Container(
                                width: 18, height: 18,
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )),
                      if (pickedImages.length < 6)
                        GestureDetector(
                          onTap: () async {
                            final imgs = await picker.pickMultiImage(imageQuality: 75);
                            if (imgs.isNotEmpty) {
                              setModalState(() {
                                pickedImages = [...pickedImages, ...imgs]
                                    .take(6).toList();
                              });
                            }
                          },
                          child: Container(
                            width: 76, height: 76,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                            ),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.add_photo_alternate_outlined, color: Colors.grey[500], size: 24),
                              Text('Add', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                            ]),
                          ),
                        ),
                    ],
                  ),
                ),
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
                      }, images: pickedImages.isEmpty ? null : pickedImages);
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lead.isAssignedToMe)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                ),
              ),
              child: const Row(children: [
                Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                SizedBox(width: 6),
                Text('Dedicated Lead For You',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700,
                        letterSpacing: 0.3)),
              ]),
            ),
          Padding(
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
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showFeedbacks(context, color),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(children: [
                Icon(Icons.rate_review_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  lead.isBuy ? 'Community Feedback — Did sellers respond? Still looking?' : 'Community Feedback — Received calls? Still available?',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, size: 14, color: Colors.grey[400]),
              ]),
            ),
          ),
        ]),
        ),   // closes Padding
        ],   // closes outer Column children
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
        initialChildSize: lead.images.isNotEmpty ? 0.75 : 0.6,
        maxChildSize: 0.95,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            if (lead.images.isNotEmpty) ...[
              _ImageGallery(images: lead.images),
              const SizedBox(height: 16),
            ],
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

  void _showFeedbacks(BuildContext context, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _FeedbackSheet(lead: lead, color: color, scrollCtrl: ctrl),
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

// ─── Image Gallery ────────────────────────────────────────────────────────────

class _ImageGallery extends StatefulWidget {
  final List<String> images;
  const _ImageGallery({required this.images});

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  int _current = 0;
  late final PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Main image
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _openFullscreen(context, i),
              child: CachedNetworkImage(
                imageUrl: widget.images[i],
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                errorWidget: (_, __, ___) => Container(color: Colors.grey[200],
                    child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40)),
              ),
            ),
          ),
        ),
      ),
      // Thumbnail strip
      if (widget.images.length > 1) ...[
        const SizedBox(height: 10),
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final selected = _current == i;
              return GestureDetector(
                onTap: () {
                  _ctrl.animateToPage(i,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut);
                  setState(() => _current = i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? const Color(0xFF2E7D32) : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: widget.images[i],
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey[200]),
                      errorWidget: (_, __, ___) => Container(color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 16, color: Colors.grey)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ]);
  }

  void _openFullscreen(BuildContext context, int initial) {
    final ctrl = PageController(initialPage: initial);
    int idx = initial;
    showDialog(
      context: context,
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: StatefulBuilder(
            builder: (_, ss) => Text('${idx + 1} / ${widget.images.length}',
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ),
        body: PageView.builder(
          controller: ctrl,
          itemCount: widget.images.length,
          onPageChanged: (i) => idx = i,
          itemBuilder: (_, i) => InteractiveViewer(
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.images[i],
                fit: BoxFit.contain,
                placeholder: (_, __) => const CircularProgressIndicator(color: Colors.white),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white, size: 60),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Feedback Sheet ───────────────────────────────────────────────────────────

class _FeedbackSheet extends StatefulWidget {
  final LeadModel lead;
  final Color color;
  final ScrollController scrollCtrl;
  const _FeedbackSheet({required this.lead, required this.color, required this.scrollCtrl});

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  Map<String, dynamic>? _summary;
  bool _loading = true;
  bool _showForm = false;
  bool? _receivedResponse;
  bool? _stillActive;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _commentCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final data = await apiService.getLeadFeedbacks(widget.lead.id);
      if (mounted) setState(() { _summary = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_receivedResponse == null && _stillActive == null && _commentCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      await apiService.submitLeadFeedback(widget.lead.id, {
        if (_receivedResponse != null) 'received_response': _receivedResponse,
        if (_stillActive != null) 'still_active': _stillActive,
        if (_commentCtrl.text.trim().isNotEmpty) 'comment': _commentCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() { _showForm = false; _submitting = false; _receivedResponse = null; _stillActive = null; });
      _commentCtrl.clear();
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!'), backgroundColor: Color(0xFF2E7D32)),
      );
    } catch (e) {
      if (mounted) setState(() => _submitting = false);
      String msg = 'Failed to submit. Try again.';
      if (e is DioException && e.response != null) {
        final body = e.response!.data;
        final serverMsg = body is Map ? (body['message'] ?? body['error']) : null;
        if (serverMsg != null) msg = serverMsg.toString();
        debugPrint('Feedback submit error ${e.response!.statusCode}: $body');
      } else {
        debugPrint('Feedback submit error: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = widget.lead.isBuy;
    final q1 = isBuy ? 'Did you receive responses from sellers?' : 'Did you receive a call or inquiry?';
    final q2 = isBuy ? 'Is your requirement still active?' : 'Is this lead still available?';

    return ListView(
      controller: widget.scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 14),
        Row(children: [
          Icon(Icons.rate_review_outlined, color: widget.color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text('User Feedbacks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.color))),
          if (!_showForm)
            TextButton.icon(
              onPressed: () => setState(() => _showForm = true),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Feedback'),
              style: TextButton.styleFrom(foregroundColor: widget.color),
            ),
        ]),
        const Divider(height: 20),

        if (_showForm) ...[
          _PollQuestion(question: q1, value: _receivedResponse, color: widget.color,
              onChanged: (v) => setState(() => _receivedResponse = v)),
          const SizedBox(height: 12),
          _PollQuestion(question: q2, value: _stillActive, color: widget.color,
              onChanged: (v) => setState(() => _stillActive = v)),
          const SizedBox(height: 12),
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share your experience (optional)...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.all(12),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => setState(() { _showForm = false; _receivedResponse = null; _stillActive = null; _commentCtrl.clear(); }),
              child: const Text('Cancel'),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: widget.color, foregroundColor: Colors.white),
              child: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit'),
            )),
          ]),
          const Divider(height: 28),
        ],

        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (_summary == null || (_summary!['total'] as int) == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(children: [
              Icon(Icons.chat_bubble_outline, size: 40, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text('No feedback yet — be the first!', style: TextStyle(color: Colors.grey[500])),
            ]),
          )
        else ...[
          _StatBar(label: q1, yes: _summary!['received_response_yes'] as int,
              no: _summary!['received_response_no'] as int, color: widget.color),
          const SizedBox(height: 12),
          _StatBar(label: q2, yes: _summary!['still_active_yes'] as int,
              no: _summary!['still_active_no'] as int, color: widget.color),
          if ((_summary!['comments'] as List).isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
            const SizedBox(height: 10),
            for (final c in (_summary!['comments'] as List))
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c['comment']?.toString() ?? '', style: const TextStyle(fontSize: 13, height: 1.4)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.person_outline, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(c['user']?.toString() ?? 'Anonymous', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    const Spacer(),
                    Text(c['date']?.toString() ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ]),
                ]),
              ),
          ],
        ],
      ],
    );
  }
}

class _PollQuestion extends StatelessWidget {
  final String question;
  final bool? value;
  final Color color;
  final ValueChanged<bool?> onChanged;
  const _PollQuestion({required this.question, required this.value, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(question, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Row(children: [
        _PollChip(label: 'Yes', icon: Icons.thumb_up_outlined, selected: value == true, color: color,
            onTap: () => onChanged(value == true ? null : true)),
        const SizedBox(width: 10),
        _PollChip(label: 'No', icon: Icons.thumb_down_outlined, selected: value == false, color: Colors.red[400]!,
            onTap: () => onChanged(value == false ? null : false)),
      ]),
    ]);
  }
}

class _PollChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _PollChip({required this.label, required this.icon, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.grey[300]!),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: selected ? Colors.white : Colors.grey[600]),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey[700])),
        ]),
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final int yes, no;
  final Color color;
  const _StatBar({required this.label, required this.yes, required this.no, required this.color});

  @override
  Widget build(BuildContext context) {
    final total = yes + no;
    final yesPct = total == 0 ? 0.0 : yes / total;
    final yesPctStr = total == 0 ? '—' : '${(yesPct * 100).round()}%';
    final noPctStr = total == 0 ? '—' : '${((1 - yesPct) * 100).round()}%';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      Row(children: [
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: yesPct, minHeight: 8,
            backgroundColor: Colors.red[100],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        )),
        const SizedBox(width: 10),
        Text('$yesPctStr yes · $noPctStr no',
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ]),
    ]);
  }
}
