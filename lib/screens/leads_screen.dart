import '../widgets/app_search_field.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_empty_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/lead_model.dart';
import '../widgets/youtube_sheet.dart';
import '../models/lead_package_model.dart';
import '../providers/auth_provider.dart';
import '../providers/lead_provider.dart';
import '../services/activity_service.dart';
import '../services/api_service.dart';
import '../services/razorpay_service.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<LeadProvider>();
    _searchCtrl.text = provider.search;
    WidgetsBinding.instance.addPostFrameCallback((_) => provider.loadUnlocks());
    _tab = TabController(
      length: 4,
      vsync: this,
      initialIndex:
          provider.assignedToMe
              ? 3
              : provider.typeFilter == 'buy'
              ? 1
              : provider.typeFilter == 'sell'
              ? 2
              : 0,
    );
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
    if (index == 3) {
      if (!prov.assignedToMe) prov.setAssignedToMe(true);
      return;
    }
    final type = switch (index) {
      1 => 'buy',
      2 => 'sell',
      _ => null,
    };
    if (prov.assignedToMe || prov.typeFilter != type) {
      prov.setTypeFilter(type);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LeadProvider>(
      builder:
          (context, prov, _) => Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            drawer: const AppDrawer(),
            appBar: AppBar(
              // (These two icons were the old Leads tab's — kept in use so a
              // Shorebird patch doesn't change the release's icon font.)
              title: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up_outlined, size: 20),
                  SizedBox(width: 6),
                  Text('Market Place'),
                ],
              ),
              leading: IconButton(
                tooltip: 'Back to Home',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.maybePop(context),
              ),
              actions: [
                Builder(
                  builder: (ctx) => IconButton(
                    tooltip: 'Open menu',
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
              ],
              bottom: TabBar(
                controller: _tab,
                onTap: _setLeadType,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Buy'),
                  Tab(text: 'Sell'),
                  Tab(icon: Icon(Icons.star_rounded, size: 16), text: 'For Me'),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showPostLead(context, prov),
              backgroundColor: const Color(0xFF2E7D32),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Post Lead',
                style: TextStyle(color: Colors.white),
              ),
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: AppSearchField(
                    controller: _searchCtrl,
                    hint: 'Search leads',
                    onChanged: prov.setSearch,
                  ),
                ),
                if (prov.unlocksLeft != null)
                  _UnlocksBanner(unlocksLeft: prov.unlocksLeft!),
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _LeadList(
                        leads: prov.leads,
                        loading: prov.loading,
                        onRefresh: () => prov.fetch(refresh: true),
                      ),
                      _LeadList(
                        leads: prov.leads,
                        loading: prov.loading,
                        onRefresh: () => prov.fetch(refresh: true),
                      ),
                      _LeadList(
                        leads: prov.leads,
                        loading: prov.loading,
                        onRefresh: () => prov.fetch(refresh: true),
                      ),
                      _LeadList(
                        leads: prov.leads,
                        loading: prov.loading,
                        onRefresh: () => prov.fetch(refresh: true),
                        emptyMessage: 'No leads assigned to you yet',
                      ),
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
    final youtubeCtrl = TextEditingController();
    final customCategoryCtrl = TextEditingController();
    String projectType = 'Real Estate';
    String customCategory = '';
    bool isBuy = true;
    List<XFile> pickedImages = [];
    List<PlatformFile> pickedDocs = [];
    final picker = ImagePicker();

    const categories = [
      'Real Estate',
      'Construction',
      'Used Car',
      'Used Bike',
      'Electronics',
      'Furniture',
      'Machinery',
      'Showpiece / Collectibles',
      'Agriculture',
      'Services',
      'Other (Custom)',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setModalState) => Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    MediaQuery.of(ctx).viewInsets.bottom + 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Post a Lead',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Lead Title',
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: projectType,
                          items:
                              categories
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) => setModalState(() => projectType = v!),
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                        ),
                        if (projectType == 'Other (Custom)') ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: customCategoryCtrl,
                            onChanged: (v) => customCategory = v,
                            decoration: const InputDecoration(
                              labelText: 'Describe your category',
                              hintText: 'e.g. Antique Watch, Goat Farm...',
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: valueCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Value (₹)',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: locationCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Location',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: contactCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Contact Number',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description (optional)',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text('Type: '),
                            ChoiceChip(
                              label: const Text('Buy'),
                              selected: isBuy,
                              onSelected:
                                  (_) => setModalState(() => isBuy = true),
                              selectedColor: const Color(0xFF2E7D32),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Sell'),
                              selected: !isBuy,
                              onSelected:
                                  (_) => setModalState(() => isBuy = false),
                              selectedColor: const Color(0xFF1565C0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Photo picker
                        Text(
                          'Photos (optional)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              ...pickedImages.asMap().entries.map(
                                (e) => Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 76,
                                      height: 76,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[200],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: FutureBuilder(
                                          future: e.value.readAsBytes(),
                                          builder:
                                              (_, snap) =>
                                                  snap.hasData
                                                      ? Image.memory(
                                                        snap.requireData,
                                                        fit: BoxFit.cover,
                                                      )
                                                      : Container(
                                                        color: Colors.grey[200],
                                                      ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: -4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap:
                                            () => setModalState(
                                              () =>
                                                  pickedImages.removeAt(e.key),
                                            ),
                                        child: Container(
                                          width: 18,
                                          height: 18,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (pickedImages.length < 6)
                                GestureDetector(
                                  onTap: () async {
                                    final imgs = await picker.pickMultiImage(
                                      imageQuality: 75,
                                    );
                                    if (imgs.isNotEmpty) {
                                      setModalState(() {
                                        pickedImages =
                                            [
                                              ...pickedImages,
                                              ...imgs,
                                            ].take(6).toList();
                                      });
                                    }
                                  },
                                  child: Container(
                                    width: 76,
                                    height: 76,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          color: Colors.grey[500],
                                          size: 24,
                                        ),
                                        Text(
                                          'Add',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // PDF document picker
                        Text(
                          'Documents (PDF, optional)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...pickedDocs.asMap().entries.map(
                          (e) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    e.value.name,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                GestureDetector(
                                  onTap:
                                      () => setModalState(
                                        () => pickedDocs.removeAt(e.key),
                                      ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (pickedDocs.length < 3)
                          OutlinedButton.icon(
                            onPressed: () async {
                              final result = await FilePicker.platform
                                  .pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['pdf'],
                                    allowMultiple: true,
                                    withData: true,
                                  );
                              if (result != null) {
                                setModalState(() {
                                  pickedDocs =
                                      [
                                        ...pickedDocs,
                                        ...result.files,
                                      ].take(3).toList();
                                });
                              }
                            },
                            icon: const Icon(Icons.upload_file, size: 16),
                            label: Text(
                              'Add PDF${pickedDocs.isEmpty ? '' : ' (${pickedDocs.length}/3)'}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2E7D32),
                              side: const BorderSide(color: Color(0xFF2E7D32)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),
                        // YouTube URL
                        TextField(
                          controller: youtubeCtrl,
                          keyboardType: TextInputType.url,
                          decoration: InputDecoration(
                            labelText: 'YouTube Video URL (optional)',
                            prefixIcon: const Icon(
                              Icons.play_circle_outline,
                              color: Colors.red,
                            ),
                            hintText: 'https://youtube.com/watch?v=...',
                            helperText: 'Add a video related to this lead',
                            helperStyle: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                            ),
                            onPressed: () async {
                              if (titleCtrl.text.isEmpty ||
                                  valueCtrl.text.isEmpty)
                                return;
                              final resolvedCategory =
                                  projectType == 'Other (Custom)'
                                      ? (customCategory.trim().isNotEmpty
                                          ? customCategory.trim()
                                          : 'Other')
                                      : projectType;
                              Navigator.pop(ctx);
                              final created = await prov.createLead(
                                {
                                  'title': titleCtrl.text,
                                  'project_type': resolvedCategory,
                                  'value': double.tryParse(valueCtrl.text) ?? 0,
                                  'location': locationCtrl.text,
                                  'contact': contactCtrl.text,
                                  'description': descCtrl.text,
                                  'is_buy': isBuy,
                                  if (youtubeCtrl.text.trim().isNotEmpty)
                                    'youtube_url': youtubeCtrl.text.trim(),
                                },
                                images:
                                    pickedImages.isEmpty ? null : pickedImages,
                                documents:
                                    pickedDocs.isEmpty ? null : pickedDocs,
                              );
                              if (created) {
                                activityService.log(
                                  'post_lead',
                                  entityType: 'lead',
                                  entityName: titleCtrl.text,
                                  extra: {
                                    'type': isBuy ? 'buy' : 'sell',
                                    'project_type': resolvedCategory,
                                  },
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
  final String emptyMessage;

  const _LeadList({
    required this.leads,
    required this.loading,
    required this.onRefresh,
    this.emptyMessage = 'No leads found',
  });

  @override
  Widget build(BuildContext context) {
    if (leads.isEmpty && loading)
      return const Center(child: CircularProgressIndicator());
    final provider = context.watch<LeadProvider>();
    if (leads.isEmpty)
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: AppEmptyState(
          icon: Icons.work_outline,
          title: provider.error != null ? 'Could not load leads' : emptyMessage,
          message:
              provider.error != null
                  ? 'Check your connection and try again.'
                  : 'Try another search or check back for new leads.',
          actionLabel: 'Refresh leads',
          onAction: onRefresh,
        ),
      );

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: leads.length + (provider.hasMore ? 1 : 0),
        itemBuilder:
            (_, i) =>
                i < leads.length
                    ? _LeadCard(lead: leads[i])
                    : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child:
                            provider.loading
                                ? const CircularProgressIndicator()
                                : TextButton(
                                  onPressed: () => provider.fetch(),
                                  child: Text(
                                    provider.error != null
                                        ? 'Try loading more again'
                                        : 'Load more leads',
                                  ),
                                ),
                      ),
                    ),
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final LeadModel lead;
  const _LeadCard({required this.lead});

  static const _typeColors = {
    // Legacy types kept for existing data
    'Residential': Color(0xFF1565C0),
    'Commercial': Color(0xFF6A1B9A),
    'Industrial': Color(0xFF37474F),
    'Infrastructure': Color(0xFF2E7D32),
    'Renovation': Color(0xFFE65100),
    'Interior': Color(0xFF00695C),
    // New categories
    'Real Estate': Color(0xFF1565C0),
    'Construction': Color(0xFF2E7D32),
    'Used Car': Color(0xFFE53935),
    'Used Bike': Color(0xFFF57C00),
    'Electronics': Color(0xFF0288D1),
    'Furniture': Color(0xFF795548),
    'Machinery': Color(0xFF37474F),
    'Showpiece / Collectibles': Color(0xFF7B1FA2),
    'Agriculture': Color(0xFF558B2F),
    'Services': Color(0xFF00695C),
  };

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[lead.projectType] ?? const Color(0xFF2E7D32);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context, color),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lead.claimedByMe)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE65100), Color(0xFFF57C00)],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, size: 15, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    lead.claimDaysLeft > 0
                        ? 'Reserved for you · ${lead.claimDaysLeft} day${lead.claimDaysLeft == 1 ? '' : 's'} left'
                        : 'Reserved for you',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            )
          else if (lead.isAssignedToMe)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                  SizedBox(width: 6),
                  Text(
                    'Dedicated Lead For You',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          if (lead.fieldVisit?.status == 'pending')
            GestureDetector(
              onTap: () => _acceptFieldVisit(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 15,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Site visit available — ${_formatDate(lead.fieldVisit!.scheduledDate)}. Tap to accept',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 15,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            )
          else if (lead.fieldVisit?.status == 'accepted_by_me')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_available,
                    size: 15,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "You're confirmed for a visit — ${_formatDate(lead.fieldVisit!.scheduledDate)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        lead.projectType,
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            lead.isBuy
                                ? Colors.green.withAlpha(25)
                                : Colors.blue.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        lead.isBuy ? 'BUY' : 'SELL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color:
                              lead.isBuy ? Colors.green[700] : Colors.blue[700],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹${_formatValue(lead.value)}',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  lead.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (lead.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    lead.description!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 13, color: Colors.grey),
                    Flexible(
                      child: Text(
                        lead.location,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    if (lead.postedBy != null)
                      Text(
                        'By ${lead.postedBy}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // ─ Contact unlocked (own / dedicated / claimed leads) or "Proceed" gate ─
                if (lead.contactUnlocked)
                  Row(
                    children: [
                      Expanded(
                        child: _ContactButton(
                          icon: Icons.call_outlined,
                          label: 'Call',
                          color: color,
                          phone: lead.contact,
                          onTap: () => _launchCall(context, lead.contact),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ContactButton(
                          icon: Icons.chat_outlined,
                          label: 'WhatsApp',
                          color: const Color(0xFF25D366),
                          phone: lead.contact,
                          onTap: () => _launchWhatsApp(context, lead.contact),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _showDetails(context, color),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: color),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                        ),
                        child: Text(
                          'Details',
                          style: TextStyle(color: color, fontSize: 12),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _proceedWithLead(context),
                          icon: const Icon(Icons.handshake_outlined, size: 15),
                          label: const Text(
                            'Proceed with this Lead',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            minimumSize: const Size(0, 36),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _showDetails(context, color),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: color),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                        ),
                        child: Text(
                          'Details',
                          style: TextStyle(color: color, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                // ─ Conversion feedback prompt for claimed leads ─
                if (lead.claimedByMe &&
                    !lead.claimFeedbackGiven &&
                    lead.claimId != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showConversionDialog(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFFCC80)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.help_outline,
                            size: 14,
                            color: Color(0xFFE65100),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Did this lead convert? Tell us',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFE65100),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.chevron_right,
                            size: 14,
                            color: Color(0xFFE65100),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showFeedbacks(context, color),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          lead.isBuy
                              ? 'Did sellers respond? Still looking?'
                              : 'Received calls? Still available?',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ), // closes Padding
        ], // closes outer Column children
        ),
      ),
    );
  }

  String _formatValue(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  String _formatDate(String isoDate) {
    final d = DateTime.tryParse(isoDate);
    if (d == null) return isoDate;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  // ─── Accept a telecaller-offered field visit — same package/paywall gate as
  //     "Proceed with this Lead" (see LeadFieldVisitController::accept()) ──────

  Future<void> _acceptFieldVisit(BuildContext context) async {
    final visitId = lead.fieldVisit?.id;
    if (visitId == null) return;

    activityService.log(
      'accept_field_visit',
      entityType: 'lead',
      entityId: lead.id,
      entityName: lead.title,
    );
    try {
      final res = await apiService.acceptFieldVisit(visitId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message']?.toString() ??
                "You're confirmed for the field visit.",
          ),
          backgroundColor: const Color(0xFF6A1B9A),
        ),
      );
      context.read<LeadProvider>().fetch(refresh: true);
    } on DioException catch (e) {
      if (!context.mounted) return;
      final code = e.response?.statusCode;
      final body = e.response?.data;
      if (code == 402 && body is Map) {
        final packages =
            (body['packages'] as List? ?? [])
                .map(
                  (p) =>
                      LeadPackageModel.fromJson(Map<String, dynamic>.from(p)),
                )
                .toList();
        _showPackageSheet(context, packages);
      } else {
        final msg = body is Map ? (body['message']?.toString()) : null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              msg ?? 'Could not accept this field visit. Try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        if (code == 409) context.read<LeadProvider>().fetch(refresh: true);
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not accept this field visit. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDetails(BuildContext context, Color color) {
    activityService.log(
      'view_lead',
      entityType: 'lead',
      entityId: lead.id,
      entityName: lead.title,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: lead.images.isNotEmpty ? 0.75 : 0.6,
            maxChildSize: 0.95,
            builder:
                (_, ctrl) => SingleChildScrollView(
                  controller: ctrl,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (lead.images.isNotEmpty) ...[
                        _ImageGallery(images: lead.images),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: color.withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              lead.projectType,
                              style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  lead.isBuy
                                      ? Colors.green.withAlpha(25)
                                      : Colors.blue.withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              lead.isBuy ? 'BUY' : 'SELL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color:
                                    lead.isBuy
                                        ? Colors.green[700]
                                        : Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        lead.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            lead.location,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '₹${_formatValue(lead.value)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (lead.description != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Description',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lead.description!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                      if (lead.postedBy != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Posted by ${lead.postedBy}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (lead.youtubeUrl != null &&
                          lead.youtubeUrl!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed:
                              () => showYoutubeSheet(context, lead.youtubeUrl!),
                          icon: const Icon(
                            Icons.play_circle_outline,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Watch Video',
                            style: TextStyle(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            minimumSize: const Size(double.infinity, 44),
                          ),
                        ),
                      ],
                      if (lead.documents.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ...lead.documents.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final uri = Uri.tryParse(e.value);
                                if (uri == null) return;
                                try {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Could not open document',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(
                                Icons.picture_as_pdf,
                                color: Colors.red,
                                size: 18,
                              ),
                              label: Text(
                                'Document ${e.key + 1}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.red[200]!),
                                minimumSize: const Size(double.infinity, 40),
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child:
                            lead.contactUnlocked
                                ? ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _contact(context, color);
                                  },
                                  icon: const Icon(Icons.phone),
                                  label: const Text('Contact Now'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: color,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                  ),
                                )
                                : ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _proceedWithLead(context);
                                  },
                                  icon: const Icon(Icons.handshake_outlined),
                                  label: const Text('Proceed with this Lead'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _showFeedbacks(BuildContext context, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => DraggableScrollableSheet(
            initialChildSize: 0.75,
            maxChildSize: 0.92,
            minChildSize: 0.4,
            expand: false,
            builder:
                (_, ctrl) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: _FeedbackSheet(
                    lead: lead,
                    color: color,
                    scrollCtrl: ctrl,
                  ),
                ),
          ),
    );
  }

  // ─── Proceed with lead: requires an active lead package; reserves the lead
  //     exclusively for the user for 30 days ──────────────────────────────────

  Future<void> _proceedWithLead(BuildContext context) async {
    activityService.log(
      'proceed_lead',
      entityType: 'lead',
      entityId: lead.id,
      entityName: lead.title,
    );
    try {
      final res = await apiService.proceedWithLead(lead.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message']?.toString() ??
                'This lead is now reserved for you for 30 days.',
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      context.read<LeadProvider>().fetch(refresh: true);
    } on DioException catch (e) {
      if (!context.mounted) return;
      final code = e.response?.statusCode;
      final body = e.response?.data;
      if (code == 402 && body is Map) {
        // No active package — show the plans and route to payment
        final packages =
            (body['packages'] as List? ?? [])
                .map(
                  (p) =>
                      LeadPackageModel.fromJson(Map<String, dynamic>.from(p)),
                )
                .toList();
        _showPackageSheet(context, packages);
      } else if (code == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to proceed with leads.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        final msg = body is Map ? (body['message']?.toString()) : null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              msg ?? 'Could not proceed with this lead. Try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        if (code == 409) context.read<LeadProvider>().fetch(refresh: true);
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not proceed with this lead. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPackageSheet(
    BuildContext context,
    List<LeadPackageModel> packages,
  ) {
    bool purchasing = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setSheetState) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            color: Color(0xFF2E7D32),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Buy a Lead Pack',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Unlock a lead to see its phone number. Each unlocked lead is reserved only for you for 30 days — close it before then.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (packages.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No packages available right now.',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ),
                        )
                      else
                        ...packages.map(
                          (p) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap:
                                  purchasing
                                      ? null
                                      : () async {
                                        setSheetState(() => purchasing = true);
                                        await _purchasePackage(ctx, context, p);
                                        if (ctx.mounted)
                                          setSheetState(
                                            () => purchasing = false,
                                          );
                                      },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF2E7D32,
                                    ).withAlpha(80),
                                  ),
                                  color: const Color(0xFF2E7D32).withAlpha(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            p.description ?? p.summary,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹${p.price}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (purchasing)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                ),
          ),
    );
  }

  Future<void> _purchasePackage(
    BuildContext sheetCtx,
    BuildContext mainCtx,
    LeadPackageModel package,
  ) async {
    final user = mainCtx.read<AuthProvider>().user;

    try {
      final res = await apiService.purchaseLeadPackage(package.id);
      activityService.log(
        'purchase_lead_package',
        entityType: 'lead_package',
        entityId: package.id,
        entityName: package.name,
        extra: {'price': package.price},
      );
      if (!sheetCtx.mounted) return;

      final orderId = res['razorpay_order_id']?.toString();
      final key = res['razorpay_key']?.toString();
      final purchaseId = res['purchase_id'] as int?;
      final amount = (res['amount'] as num?)?.toInt() ?? 0;

      if (orderId == null || key == null || purchaseId == null) {
        ScaffoldMessenger.of(sheetCtx).showSnackBar(
          SnackBar(
            content: Text(
              res['message']?.toString() ?? 'Could not create payment order.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      Navigator.pop(sheetCtx);

      final result = await razorpayService.pay(
        razorpayKey: key,
        orderId: orderId,
        amountInPaise: amount * 100,
        contactPhone: user?.phone ?? '',
        email: user?.email,
        description: 'NEE Lead Package – ${package.name}',
      );

      if (!mainCtx.mounted) return;
      ScaffoldMessenger.of(mainCtx).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Activating your package…'),
            ],
          ),
          duration: const Duration(seconds: 30),
        ),
      );

      await apiService.verifyLeadPackagePayment(
        purchaseId,
        paymentId: result.paymentId,
        orderId: result.orderId,
        signature: result.signature,
      );

      if (!mainCtx.mounted) return;
      ScaffoldMessenger.of(mainCtx).hideCurrentSnackBar();
      ScaffoldMessenger.of(mainCtx).showSnackBar(
        const SnackBar(
          content: Text(
            'Lead pack activated! Tap Proceed on any lead to unlock it.',
          ),
          backgroundColor: Color(0xFF2E7D32),
          duration: Duration(seconds: 5),
        ),
      );
      mainCtx.read<LeadProvider>().fetch(refresh: true);
    } on DioException catch (e) {
      if (!mainCtx.mounted) return;
      final body = e.response?.data;
      final msg = body is Map ? body['message']?.toString() : null;
      ScaffoldMessenger.of(mainCtx).showSnackBar(
        SnackBar(
          content: Text(msg ?? 'Could not complete the purchase. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mainCtx.mounted) return;
      // Silently dismiss when the user cancels — no error banner needed.
      if (e is PaymentCancelledException) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(mainCtx).showSnackBar(
        SnackBar(
          content: Text(msg.isNotEmpty ? msg : 'Payment was not completed.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // ─── Conversion feedback on a claimed lead ──────────────────────────────────

  void _showConversionDialog(BuildContext context) {
    bool? converted;
    final commentCtrl = TextEditingController();
    bool submitting = false;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Did this lead convert?',
                    style: TextStyle(fontSize: 16),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lead.title,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const SizedBox(
                                width: double.infinity,
                                child: Text(
                                  'Yes, converted',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              selected: converted == true,
                              selectedColor: const Color(0xFF2E7D32),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                color:
                                    converted == true
                                        ? Colors.white
                                        : Colors.grey[700],
                              ),
                              onSelected:
                                  (_) => setDialogState(() => converted = true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const SizedBox(
                                width: double.infinity,
                                child: Text(
                                  'Not yet',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              selected: converted == false,
                              selectedColor: Colors.red[400],
                              labelStyle: TextStyle(
                                fontSize: 12,
                                color:
                                    converted == false
                                        ? Colors.white
                                        : Colors.grey[700],
                              ),
                              onSelected:
                                  (_) =>
                                      setDialogState(() => converted = false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: commentCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Comments (optional)...',
                          hintStyle: const TextStyle(fontSize: 12.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.all(10),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Later'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                      ),
                      onPressed:
                          (converted == null || submitting)
                              ? null
                              : () async {
                                setDialogState(() => submitting = true);
                                try {
                                  final res = await apiService
                                      .submitClaimFeedback(
                                        lead.claimId!,
                                        converted: converted!,
                                        comment: commentCtrl.text.trim(),
                                      );
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        res['message']?.toString() ??
                                            'Thank you for your feedback!',
                                      ),
                                      backgroundColor: const Color(0xFF2E7D32),
                                    ),
                                  );
                                  if (context.mounted)
                                    context.read<LeadProvider>().fetch(
                                      refresh: true,
                                    );
                                } catch (_) {
                                  if (!ctx.mounted) return;
                                  setDialogState(() => submitting = false);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Failed to submit. Try again.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                      child:
                          submitting
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Submit'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _launchCall(BuildContext context, String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contact number available')),
      );
      return;
    }
    activityService.log(
      'contact_lead',
      entityType: 'lead',
      entityId: lead.id,
      entityName: lead.title,
      extra: {'phone': phone, 'via': 'call'},
    );
    final uri = Uri(
      scheme: 'tel',
      path: phone.replaceAll(RegExp(r'[^\d+]'), ''),
    );
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _launchWhatsApp(BuildContext context, String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contact number available')),
      );
      return;
    }
    activityService.log(
      'contact_lead',
      entityType: 'lead',
      entityId: lead.id,
      entityName: lead.title,
      extra: {'phone': phone, 'via': 'whatsapp'},
    );
    final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/91$clean');
    if (await canLaunchUrl(uri))
      launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _contact(BuildContext context, Color color) {
    final phone = lead.contact;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contact number available')),
      );
      return;
    }
    activityService.log(
      'contact_lead',
      entityType: 'lead',
      entityId: lead.id,
      entityName: lead.title,
      extra: {'phone': phone},
    );
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withAlpha(15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.phone, color: color, size: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  lead.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          final uri = Uri(
                            scheme: 'tel',
                            path: phone.replaceAll(RegExp(r'[^\d+]'), ''),
                          );
                          if (await canLaunchUrl(uri)) launchUrl(uri);
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('Call Now'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
                          final uri = Uri.parse('https://wa.me/91$clean');
                          if (await canLaunchUrl(uri))
                            launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }
}

// ─── Inline contact button (call / WhatsApp) ─────────────────────────────────

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? phone;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.phone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhone = phone != null && phone!.isNotEmpty;
    return ElevatedButton.icon(
      onPressed: hasPhone ? onTap : null,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: Colors.grey[200],
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.grey[400],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(vertical: 8),
        minimumSize: const Size(0, 36),
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
    return Column(
      children: [
        // Main image
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _ctrl,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder:
                  (_, i) => GestureDetector(
                    onTap: () => _openFullscreen(context, i),
                    child: CachedNetworkImage(
                      imageUrl: widget.images[i],
                      fit: BoxFit.cover,
                      placeholder:
                          (_, _) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      errorWidget:
                          (_, _, _) => Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
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
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final selected = _current == i;
                return GestureDetector(
                  onTap: () {
                    _ctrl.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                    setState(() => _current = i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            selected
                                ? const Color(0xFF2E7D32)
                                : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: widget.images[i],
                        fit: BoxFit.cover,
                        placeholder:
                            (_, _) => Container(color: Colors.grey[200]),
                        errorWidget:
                            (_, _, _) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  void _openFullscreen(BuildContext context, int initial) {
    final ctrl = PageController(initialPage: initial);
    int idx = initial;
    showDialog(
      context: context,
      builder:
          (_) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              title: StatefulBuilder(
                builder:
                    (_, ss) => Text(
                      '${idx + 1} / ${widget.images.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
              ),
            ),
            body: PageView.builder(
              controller: ctrl,
              itemCount: widget.images.length,
              onPageChanged: (i) => idx = i,
              itemBuilder:
                  (_, i) => InteractiveViewer(
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: widget.images[i],
                        fit: BoxFit.contain,
                        placeholder:
                            (_, _) => const CircularProgressIndicator(
                              color: Colors.white,
                            ),
                        errorWidget:
                            (_, _, _) => const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white,
                              size: 60,
                            ),
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
  const _FeedbackSheet({
    required this.lead,
    required this.color,
    required this.scrollCtrl,
  });

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
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await apiService.getLeadFeedbacks(widget.lead.id);
      if (mounted)
        setState(() {
          _summary = data;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_receivedResponse == null &&
        _stillActive == null &&
        _commentCtrl.text.trim().isEmpty)
      return;
    setState(() => _submitting = true);
    try {
      await apiService.submitLeadFeedback(widget.lead.id, {
        if (_receivedResponse != null) 'received_response': _receivedResponse,
        if (_stillActive != null) 'still_active': _stillActive,
        if (_commentCtrl.text.trim().isNotEmpty)
          'comment': _commentCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        _showForm = false;
        _submitting = false;
        _receivedResponse = null;
        _stillActive = null;
      });
      _commentCtrl.clear();
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your feedback!'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _submitting = false);
      String msg = 'Failed to submit. Try again.';
      if (e is DioException && e.response != null) {
        final body = e.response!.data;
        final serverMsg =
            body is Map ? (body['message'] ?? body['error']) : null;
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
    final q1 =
        isBuy
            ? 'Did you receive responses from sellers?'
            : 'Did you receive a call or inquiry?';
    final q2 =
        isBuy
            ? 'Is your requirement still active?'
            : 'Is this lead still available?';

    return ListView(
      controller: widget.scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Icon(Icons.rate_review_outlined, color: widget.color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'User Feedbacks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),
            ),
            if (!_showForm)
              TextButton.icon(
                onPressed: () => setState(() => _showForm = true),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Feedback'),
                style: TextButton.styleFrom(foregroundColor: widget.color),
              ),
          ],
        ),
        const Divider(height: 20),

        if (_showForm) ...[
          _PollQuestion(
            question: q1,
            value: _receivedResponse,
            color: widget.color,
            onChanged: (v) => setState(() => _receivedResponse = v),
          ),
          const SizedBox(height: 12),
          _PollQuestion(
            question: q2,
            value: _stillActive,
            color: widget.color,
            onChanged: (v) => setState(() => _stillActive = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share your experience (optional)...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.all(12),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      () => setState(() {
                        _showForm = false;
                        _receivedResponse = null;
                        _stillActive = null;
                        _commentCtrl.clear();
                      }),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                  ),
                  child:
                      _submitting
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Submit'),
                ),
              ),
            ],
          ),
          const Divider(height: 28),
        ],

        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_summary == null || (_summary!['total'] as int) == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 40,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 8),
                Text(
                  'No feedback yet — be the first!',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          )
        else ...[
          _StatBar(
            label: q1,
            yes: _summary!['received_response_yes'] as int,
            no: _summary!['received_response_no'] as int,
            color: widget.color,
          ),
          const SizedBox(height: 12),
          _StatBar(
            label: q2,
            yes: _summary!['still_active_yes'] as int,
            no: _summary!['still_active_no'] as int,
            color: widget.color,
          ),
          if ((_summary!['comments'] as List).isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Comments',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c['comment']?.toString() ?? '',
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 12,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          c['user']?.toString() ?? 'Anonymous',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          c['date']?.toString() ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
  const _PollQuestion({
    required this.question,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _PollChip(
              label: 'Yes',
              icon: Icons.thumb_up_outlined,
              selected: value == true,
              color: color,
              onTap: () => onChanged(value == true ? null : true),
            ),
            const SizedBox(width: 10),
            _PollChip(
              label: 'No',
              icon: Icons.thumb_down_outlined,
              selected: value == false,
              color: Colors.red[400]!,
              onTap: () => onChanged(value == false ? null : false),
            ),
          ],
        ),
      ],
    );
  }
}

class _PollChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _PollChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final int yes, no;
  final Color color;
  const _StatBar({
    required this.label,
    required this.yes,
    required this.no,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final total = yes + no;
    final yesPct = total == 0 ? 0.0 : yes / total;
    final yesPctStr = total == 0 ? '—' : '${(yesPct * 100).round()}%';
    final noPctStr = total == 0 ? '—' : '${((1 - yesPct) * 100).round()}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: yesPct,
                  minHeight: 8,
                  backgroundColor: Colors.red[100],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$yesPctStr yes · $noPctStr no',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }
}

/// How many lead-pack unlocks the user has left — or, with none, what a pack costs.
class _UnlocksBanner extends StatelessWidget {
  final int unlocksLeft;
  const _UnlocksBanner({required this.unlocksLeft});

  @override
  Widget build(BuildContext context) {
    final has = unlocksLeft > 0;
    const green = Color(0xFF2E7D32);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: has ? green.withAlpha(20) : Colors.orange.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            has ? Icons.trending_up_rounded : Icons.lock_rounded,
            size: 18,
            color: has ? green : Colors.orange[800],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              has
                  ? 'You can unlock $unlocksLeft more lead${unlocksLeft == 1 ? '' : 's'}. Tap Proceed on a lead to see its phone number.'
                  : 'Phone numbers are locked. Get 10 leads for ₹3,000 — tap Proceed on any lead to buy.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.3,
                color: has ? green : Colors.orange[900],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
