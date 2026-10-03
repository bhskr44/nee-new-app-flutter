import '../widgets/app_empty_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/business_type_model.dart';
import '../providers/auth_provider.dart';
import '../services/activity_service.dart';
import '../services/api_service.dart';

class BusinessScreen extends StatefulWidget {
  const BusinessScreen({super.key});

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  late Future<List<BusinessTypeModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<BusinessTypeModel>> _load() async {
    final data = await apiService.getBusinessTypes();
    return data.map((e) => BusinessTypeModel.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Start Your Business')),
      body: RefreshIndicator(
        onRefresh: () async {
          final future = _load();
          setState(() => _future = future);
          await future;
        },
        child: FutureBuilder<List<BusinessTypeModel>>(
          future: _future,
          builder: (context, snapshot) {
            final types = snapshot.data ?? [];
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _buildHero(context),
                _buildStats(),
                const _SectionHeader('Choose Your Business Type'),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError)
                  AppEmptyState(
                    icon: Icons.business_outlined,
                    title: 'Could not load business guides',
                    message: 'Check your connection and try again.',
                    actionLabel: 'Try again',
                    onAction: () => setState(() => _future = _load()),
                  )
                else if (types.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: Text('No business guides available')),
                  )
                else
                  ...types.map((type) => _BusinessCard(type: type)),
                const _SectionHeader('How It Works'),
                _howItWorksCard(context),
                const _SectionHeader('Why Start in Construction?'),
                _buildWhyCards(),
                const _SectionHeader('Government Support Available'),
                _buildGovtSupport(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
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
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Free Expert Consultation',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Launch Your Construction\nBusiness Today',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Apply now — our experts will review your details and contact you with guidance.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showConsultationForm(context, null),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFC62828),
            ),
            child: const Text(
              'Apply Now',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          _statBox('Free', 'Experts Consultation', const Color(0xFFC62828)),
          const SizedBox(width: 10),
          _statBox('10X', 'Business Growth', const Color(0xFF2E7D32)),
        ],
      ),
    );
  }

  Widget _statBox(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _howItWorksCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFC62828).withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.assignment_turned_in_outlined,
                color: Color(0xFFC62828),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Apply in 2 quick steps — share your details, then upload your documents (or let us know if you don\'t have them yet).',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
            TextButton(
              onPressed: () => _showConsultationForm(context, null),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhyCards() {
    const items = [
      (
        Icons.trending_up,
        'High Demand',
        'Huge opportunity in homes, commercial work and infrastructure.',
      ),
      (
        Icons.account_balance,
        'Govt Push',
        'MSME, Mudra, PMEGP and procurement schemes support new businesses.',
      ),
      (
        Icons.currency_rupee,
        'Good Margins',
        'Construction services can generate strong repeat and referral revenue.',
      ),
      (
        Icons.handshake,
        'Guided Start',
        'Admin follow-up notes help track every customer conversation.',
      ),
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
        children:
            items
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.$1, color: const Color(0xFFC62828)),
                        const SizedBox(height: 6),
                        Text(
                          item.$2,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$3,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildGovtSupport() {
    const items = [
      (
        Icons.account_balance,
        'PM Mudra Yojana',
        'Loans up to ₹10L with no collateral for small businesses.',
        Color(0xFF1565C0),
      ),
      (
        Icons.handshake,
        'PMEGP Scheme',
        '15-35% capital subsidy for manufacturing businesses.',
        Color(0xFF2E7D32),
      ),
      (
        Icons.verified,
        'Udyam Registration',
        'Free MSME registration unlocks priority lending and tenders.',
        Color(0xFF6A1B9A),
      ),
      (
        Icons.construction,
        'GeM Portal',
        'Sell directly to government departments after registration.',
        Color(0xFFE65100),
      ),
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 5),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.$4.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.$1, color: item.$4, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$2,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.$3,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showConsultationForm(BuildContext context, BusinessTypeModel? type) {
    final user = context.read<AuthProvider>().user;

    // Pre-fill from profile; phone always populated if available.
    final profilePhone = user?.phone ?? '';
    final profileEmail =
        (user?.email ?? '').contains('@nee.local') ? '' : (user?.email ?? '');
    final profileDistrict = user?.profile?.district ?? '';

    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final phoneCtrl = TextEditingController(text: profilePhone);
    final emailCtrl = TextEditingController(text: profileEmail);
    final districtCtrl = TextEditingController(text: profileDistrict);
    final messageCtrl = TextEditingController(
      text: type == null ? '' : 'Interested in ${type.name}',
    );
    String stage = 'Planning';
    int step = 0;
    PlatformFile? pickedDoc;
    bool docNotAvailable = false;
    var submitting = false;

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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                type == null
                                    ? 'Apply for Consultation'
                                    : 'Apply - ${type.name}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              'Step ${step + 1} of 2',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          step == 0
                              ? 'Tell us about yourself and your business plan.'
                              : 'Share the documents you have — or let us know if you don\'t have them yet.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (step == 0) ...[
                          TextField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Full Name *',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Mobile Number *',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: districtCtrl,
                            decoration: const InputDecoration(
                              labelText: 'District',
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: stage,
                            decoration: const InputDecoration(
                              labelText: 'Business Stage',
                            ),
                            items:
                                [
                                      'Planning',
                                      'Already started',
                                      'Need funding',
                                      'Need documents',
                                      'Need customers',
                                    ]
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (value) =>
                                    setModalState(() => stage = value ?? stage),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: messageCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'What help do you need?',
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (nameCtrl.text.trim().isEmpty ||
                                    phoneCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter your name and mobile number',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                setModalState(() => step = 1);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC62828),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text(
                                'Next: Documents',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ] else ...[
                          if (type != null && type.documents.isNotEmpty) ...[
                            const Text(
                              'Documents typically required',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final doc in type.documents)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFFC62828),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        doc,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 14),
                          ],
                          if (!docNotAvailable) ...[
                            if (pickedDoc != null)
                              Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.description,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        pickedDoc!.name,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap:
                                          () => setModalState(
                                            () => pickedDoc = null,
                                          ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final result = await FilePicker.platform
                                      .pickFiles(
                                        type: FileType.custom,
                                        allowedExtensions: [
                                          'pdf',
                                          'jpg',
                                          'jpeg',
                                          'png',
                                        ],
                                        withData: true,
                                      );
                                  if (result != null &&
                                      result.files.isNotEmpty) {
                                    setModalState(
                                      () => pickedDoc = result.files.first,
                                    );
                                  }
                                },
                                icon: const Icon(Icons.upload_file, size: 18),
                                label: const Text('Upload Document'),
                              ),
                            const SizedBox(height: 10),
                          ],
                          CheckboxListTile(
                            value: docNotAvailable,
                            onChanged:
                                (v) => setModalState(() {
                                  docNotAvailable = v ?? false;
                                  if (docNotAvailable) pickedDoc = null;
                                }),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: const Text(
                              'Document not available currently',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed:
                                      submitting
                                          ? null
                                          : () => setModalState(() => step = 0),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  child: const Text('Back'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed:
                                      submitting
                                          ? null
                                          : () async {
                                            setModalState(
                                              () => submitting = true,
                                            );
                                            try {
                                              final phone =
                                                  phoneCtrl.text.trim();
                                              final email =
                                                  emailCtrl.text.trim();
                                              await apiService
                                                  .requestBusinessConsultation({
                                                    if (type != null)
                                                      'business_type_id':
                                                          type.id,
                                                    'name':
                                                        nameCtrl.text.trim(),
                                                    'phone': phone,
                                                    if (email.isNotEmpty)
                                                      'email': email,
                                                    if (districtCtrl.text
                                                        .trim()
                                                        .isNotEmpty)
                                                      'district':
                                                          districtCtrl.text
                                                              .trim(),
                                                    'business_stage': stage,
                                                    'message':
                                                        messageCtrl.text.trim(),
                                                    'document_not_available':
                                                        docNotAvailable,
                                                  }, document: pickedDoc);
                                              await activityService.log(
                                                'apply_business_consultation',
                                                entityType: 'business',
                                                entityName:
                                                    type?.name ??
                                                    'Business Consultation',
                                              );
                                              if (!ctx.mounted) return;
                                              Navigator.pop(ctx);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Application submitted! Our team will contact you shortly.',
                                                    ),
                                                    backgroundColor: Color(
                                                      0xFF2E7D32,
                                                    ),
                                                    duration: Duration(
                                                      seconds: 5,
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              setModalState(
                                                () => submitting = false,
                                              );
                                              if (!ctx.mounted) return;
                                              ScaffoldMessenger.of(
                                                ctx,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Submission failed. Please try again.',
                                                  ),
                                                  backgroundColor:
                                                      Colors.orange,
                                                ),
                                              );
                                            }
                                          },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFC62828),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  child:
                                      submitting
                                          ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                          : const Text(
                                            'Submit Application',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
          ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  final BusinessTypeModel type;
  const _BusinessCard({required this.type});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_BusinessScreenState>();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetail(context, state),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 126,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [type.color.withAlpha(200), type.color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          type.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(type.iconData, color: Colors.white, size: 32),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _pill(
                        Icons.currency_rupee,
                        '${type.minInvestment} - ${type.maxInvestment}',
                        Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _pill(
                        Icons.trending_up,
                        type.expectedReturns,
                        Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showDetail(context, state),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: type.color,
                          ),
                          child: const Text(
                            'View Guide',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed:
                            () => state?._showConsultationForm(context, type),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: type.color,
                          side: BorderSide(color: type.color),
                        ),
                        child: const Text(
                          'Apply Now',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
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
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, _BusinessScreenState? state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: type.color.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              type.iconData,
                              color: type.color,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  type.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  type.expectedReturns,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        type.description,
                        style: TextStyle(
                          color: Colors.grey[700],
                          height: 1.5,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Steps to Start',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final entry in type.steps.asMap().entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: type.color,
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        'Documents Required',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final doc in type.documents)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: type.color,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  doc,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            state?._showConsultationForm(context, type);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: type.color,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Apply Now'),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
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
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF212121),
        ),
      ),
    );
  }
}
