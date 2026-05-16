import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/funding_scheme_model.dart';
import '../providers/funding_provider.dart';
import '../services/activity_service.dart';
import '../services/api_service.dart';

class FundingScreen extends StatefulWidget {
  const FundingScreen({super.key});

  @override
  State<FundingScreen> createState() => _FundingScreenState();
}

class _FundingScreenState extends State<FundingScreen> {
  static const _filters = ['All', 'Government Scheme', 'Government Subsidy', 'Government Guarantee Scheme', 'Bank Loan', 'NBFC / Private'];
  static const _filterLabels = ['All', 'Govt Schemes', 'Subsidies', 'Guarantee', 'Bank Loans', 'Private'];

  @override
  Widget build(BuildContext context) {
    return Consumer<FundingProvider>(
      builder: (context, prov, _) => Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(title: const Text('Funding Support')),
        body: Column(
          children: [
            _buildHero(),
            _buildFilters(prov),
            Expanded(
              child: RefreshIndicator(
                onRefresh: prov.fetch,
                child: prov.filtered.isEmpty && prov.loading
                    ? const Center(child: CircularProgressIndicator())
                    : prov.filtered.isEmpty
                        ? const Center(child: Text('No funding schemes found'))
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: prov.filtered.length,
                            itemBuilder: (_, i) => _FundingCard(option: prov.filtered[i]),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return SizedBox(
      height: 210,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=800&h=340&fit=crop&auto=format',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFF00695C)),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xE0004D40), Color(0xC000695C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Financial Support',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                const Text('Grow Your Business\nWith Smart Funding',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.3)),
                const SizedBox(height: 16),
                Row(children: [
                  _heroPill(Icons.account_balance, '₹50K – ₹2Cr', 'Loan Range'),
                  const SizedBox(width: 10),
                  _heroPill(Icons.percent, '7–19%', 'Interest Rate'),
                  const SizedBox(width: 10),
                  _heroPill(Icons.timer, '1–30 Yrs', 'Tenure'),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroPill(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _buildFilters(FundingProvider prov) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _filterLabels.length,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final val = _filters[i];
          final sel = prov.type == val;
          return ChoiceChip(
            label: Text(_filterLabels[i], style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.grey[700], fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
            selected: sel,
            onSelected: (_) => prov.setType(val),
            selectedColor: const Color(0xFF00695C),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }
}

class _FundingCard extends StatelessWidget {
  final FundingSchemeModel option;
  const _FundingCard({required this.option});

  static const _typeColors = {
    'Government Scheme': Color(0xFF1565C0),
    'Government Subsidy': Color(0xFF2E7D32),
    'Government Guarantee Scheme': Color(0xFF6A1B9A),
    'Bank Loan': Color(0xFF00695C),
    'NBFC / Private': Color(0xFFE65100),
  };

  Color get _color => _typeColors[option.type] ?? const Color(0xFF455A64);

  String _fmt(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(0)} Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(0)} L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _color.withAlpha(25), borderRadius: BorderRadius.circular(6)),
                child: Text(option.type, style: TextStyle(fontSize: 11, color: _color, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.withAlpha(25), borderRadius: BorderRadius.circular(6)),
                child: const Text('Apply Now', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 10),
            Text(option.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(option.provider, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 10),
            Text(option.description, style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                _stat('Amount', '${_fmt(option.minAmount)} – ${_fmt(option.maxAmount)}', Icons.currency_rupee),
                _divider(),
                _stat('Interest', '${option.interestRate}% p.a.', Icons.percent),
                _divider(),
                _stat('Tenure', option.tenure ?? 'Flexible', Icons.schedule),
              ]),
            ),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(child: Text('Eligibility: ${option.eligibility ?? 'Contact provider for eligibility'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showDetail(context),
                  style: OutlinedButton.styleFrom(foregroundColor: _color, side: BorderSide(color: _color),
                      padding: const EdgeInsets.symmetric(vertical: 10)),
                  child: const Text('Learn More', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showApply(context),
                  style: ElevatedButton.styleFrom(backgroundColor: _color, padding: const EdgeInsets.symmetric(vertical: 10)),
                  child: const Text('Apply Now', style: TextStyle(fontSize: 13)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
      ]),
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 8));

  void _showDetail(BuildContext context) {
    activityService.log('view_funding', entityType: 'funding', entityId: option.id, entityName: option.name);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(option.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(option.provider, style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 14),
            Text(option.description, style: TextStyle(color: Colors.grey[700], height: 1.5)),
            const SizedBox(height: 14),
            _row('Min Amount', _fmt(option.minAmount)),
            _row('Max Amount', _fmt(option.maxAmount)),
            _row('Interest Rate', '${option.interestRate}% per annum'),
            _row('Repayment', option.tenure ?? 'Flexible'),
            _row('Eligibility', option.eligibility ?? 'Contact provider for eligibility'),
            if (option.documents != null) _row('Documents', option.documents!),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showApply(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: _color),
                child: const Text('Apply for This Scheme'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      SizedBox(width: 110, child: Text(l, style: const TextStyle(color: Colors.grey, fontSize: 13))),
      Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
    ]),
  );

  void _showApply(BuildContext context) {
    activityService.log('apply_funding', entityType: 'funding', entityId: option.id, entityName: option.name);
    final nameCtrl     = TextEditingController();
    final businessCtrl = TextEditingController();
    final phoneCtrl    = TextEditingController();
    final amountCtrl   = TextEditingController();
    bool submitting    = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Apply — ${option.name}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *')),
              const SizedBox(height: 10),
              TextField(controller: businessCtrl, decoration: const InputDecoration(labelText: 'Business Name')),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Mobile Number *')),
              const SizedBox(height: 10),
              TextField(controller: amountCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Loan Amount Required (₹)')),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Please enter your name and phone number')),
                            );
                            return;
                          }
                          setModalState(() => submitting = true);
                          try {
                            final res = await apiService.applyFunding({
                              'full_name':         nameCtrl.text.trim(),
                              'business_name':     businessCtrl.text.trim(),
                              'phone':             phoneCtrl.text.trim(),
                              'loan_amount':       double.tryParse(amountCtrl.text.trim()),
                              'funding_scheme_id': option.id,
                            });
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res['message'] ?? 'Application submitted!'),
                                  backgroundColor: Colors.green[700],
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          } catch (_) {
                            setModalState(() => submitting = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Submission failed. Please try again.')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: _color, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: submitting
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Application', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
