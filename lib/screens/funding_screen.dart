import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class FundingScreen extends StatefulWidget {
  const FundingScreen({super.key});

  @override
  State<FundingScreen> createState() => _FundingScreenState();
}

class _FundingScreenState extends State<FundingScreen> {
  String _selected = 'All';

  static const _filters = ['All', 'Government Scheme', 'Government Subsidy', 'Government Guarantee Scheme', 'Bank Loan', 'NBFC / Private'];
  static const _filterLabels = ['All', 'Govt Schemes', 'Subsidies', 'Guarantee', 'Bank Loans', 'Private'];

  List<FundingOption> get _filtered => _selected == 'All'
      ? mockFunding
      : mockFunding.where((f) => f.type == _selected).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Funding Support')),
      body: Column(
        children: [
          _buildHero(),
          _buildFilters(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: _filtered.length,
              itemBuilder: (_, i) => _FundingCard(option: _filtered[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return SizedBox(
      height: 170,
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

  Widget _buildFilters() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _filterLabels.length,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final val = _filters[i];
          final sel = _selected == val;
          return ChoiceChip(
            label: Text(_filterLabels[i], style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.grey[700], fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
            selected: sel,
            onSelected: (_) => setState(() => _selected = val),
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
  final FundingOption option;
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
                _stat('Tenure', option.duration, Icons.schedule),
              ]),
            ),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(child: Text('Eligibility: ${option.eligibility}',
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
            _row('Repayment', option.duration),
            _row('Eligibility', option.eligibility),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
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
            Text('Apply — ${option.name}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 10),
            const TextField(decoration: InputDecoration(labelText: 'Business Name')),
            const SizedBox(height: 10),
            const TextField(keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Mobile Number')),
            const SizedBox(height: 10),
            const TextField(keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Loan Amount Required (₹)')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Application submitted! Our team will contact you within 24 hours.'), backgroundColor: Colors.green),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: _color, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Submit Application'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
