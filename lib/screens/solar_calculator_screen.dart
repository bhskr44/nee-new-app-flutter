import 'package:flutter/material.dart';
import '../services/estimate_pdf_service.dart';

class SolarCalculatorScreen extends StatefulWidget {
  const SolarCalculatorScreen({super.key});

  @override
  State<SolarCalculatorScreen> createState() => _SolarCalculatorScreenState();
}

class _SolarCalculatorScreenState extends State<SolarCalculatorScreen> {
  String _capacity = '3 KW';
  String _roofType = 'Tin Roof';
  bool _applyMnre = true;
  _SolarResult? _result;

  static const _capacities = [
    '1 KW', '2 KW', '3 KW', '4 KW', '5 KW', '6 KW', '7 KW',
    '8 KW', '9 KW', '10 KW', '14 KW', '15 KW', '16 KW', '18 KW', '20 KW',
  ];

  // Pricing table from official rate list (inc. GST, Solar System on Grid)
  // rccDiscount = price reduction for RCC roof over Tin Roof
  static const _table = {
    '1 KW':  (tin: 90000.0,   rccOff: 10000.0, mnre: 33000.0),
    '2 KW':  (tin: 135000.0,  rccOff: 10000.0, mnre: 66000.0),
    '3 KW':  (tin: 189000.0,  rccOff: 10000.0, mnre: 85800.0),
    '4 KW':  (tin: 245000.0,  rccOff: 10000.0, mnre: 85800.0),
    '5 KW':  (tin: 325000.0,  rccOff: 10000.0, mnre: 85800.0),
    '6 KW':  (tin: 360000.0,  rccOff: 15000.0, mnre: 85800.0),
    '7 KW':  (tin: 415000.0,  rccOff: 15000.0, mnre: 85800.0),
    '8 KW':  (tin: 460000.0,  rccOff: 15000.0, mnre: 85800.0),
    '9 KW':  (tin: 520000.0,  rccOff: 15000.0, mnre: 85800.0),
    '10 KW': (tin: 600000.0,  rccOff: 15000.0, mnre: 85800.0),
    '14 KW': (tin: 850000.0,  rccOff: 20000.0, mnre: 85800.0),
    '15 KW': (tin: 925000.0,  rccOff: 20000.0, mnre: 85800.0),
    '16 KW': (tin: 950000.0,  rccOff: 20000.0, mnre: 85800.0),
    '18 KW': (tin: 1100000.0, rccOff: 20000.0, mnre: 85800.0),
    '20 KW': (tin: 1210000.0, rccOff: 20000.0, mnre: 85800.0),
  };

  static const _solar = Color(0xFFF57F17);
  static const _solarDark = Color(0xFFE65100);

  bool get _is3Phase {
    final kw = int.parse(_capacity.replaceAll(' KW', ''));
    return kw >= 8;
  }

  void _calculate() {
    final row = _table[_capacity]!;
    final base = _roofType == 'RCC Roof' ? row.tin - row.rccOff : row.tin;
    final mnre = _applyMnre ? row.mnre : 0.0;
    setState(() => _result = _SolarResult(
      capacity: _capacity,
      roofType: _roofType,
      tinPrice: row.tin,
      rccSaving: _roofType == 'RCC Roof' ? row.rccOff : 0,
      basePrice: base,
      mnreSubsidy: mnre,
      netPayable: base - mnre,
      is3Phase: _is3Phase,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: const Text('Solar System Calculator'),
        backgroundColor: _solarDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_solarDark, _solar],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Solar System on Grid',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('Price inc. GST  •  MNRE subsidy included',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            // Config card
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('System Capacity', Icons.bolt),
                  const SizedBox(height: 10),
                  _capacityGrid(),
                  const SizedBox(height: 16),
                  _sectionLabel('Roof Type', Icons.roofing),
                  const SizedBox(height: 10),
                  _roofToggle(),
                  const SizedBox(height: 16),
                  _sectionLabel('Apply Subsidies', Icons.account_balance_outlined),
                  const SizedBox(height: 6),
                  _subsidyRow(
                    'Central Subsidy (MNRE)',
                    _applyMnre,
                    (v) => setState(() => _applyMnre = v),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _calculate,
                      icon: const Icon(Icons.calculate_outlined, size: 20),
                      label: const Text('Calculate Net Price',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _solarDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 14),
              _ResultCard(result: _result!),
            ],
            const SizedBox(height: 14),
            _infoCard(),
          ],
        ),
      ),
    );
  }

  Widget _capacityGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _capacities.map((cap) {
        final active = _capacity == cap;
        return GestureDetector(
          onTap: () => setState(() { _capacity = cap; _result = null; }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? _solarDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: active ? _solarDark : Colors.grey.shade300),
              boxShadow: active
                  ? [BoxShadow(color: _solarDark.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
                  : [],
            ),
            child: Text(
              cap,
              style: TextStyle(
                color: active ? Colors.white : Colors.grey[700],
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _roofToggle() {
    return Row(
      children: ['Tin Roof', 'RCC Roof'].map((type) {
        final active = _roofType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() { _roofType = type; _result = null; }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: type == 'Tin Roof' ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: active ? _solarDark : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: active ? _solarDark : Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Icon(
                    type == 'Tin Roof' ? Icons.roofing : Icons.business,
                    color: active ? Colors.white : Colors.grey[600],
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.grey[700],
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  if (type == 'RCC Roof')
                    Text(
                      '(- discount)',
                      style: TextStyle(
                        color: active ? Colors.white70 : Colors.grey[500],
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _subsidyRow(String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value ? _solarDark : Colors.white,
                border: Border.all(color: value ? _solarDark : Colors.grey.shade400, width: 1.5),
                borderRadius: BorderRadius.circular(5),
              ),
              child: value
                  ? const Icon(Icons.check, color: Colors.white, size: 15)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[800])),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _solarDark),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _solarDark)),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: child,
    );
  }

  Widget _infoCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.info_outline, size: 16, color: Colors.blueGrey),
            const SizedBox(width: 6),
            Text('Important Notes',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey[700])),
          ]),
          const SizedBox(height: 10),
          _infoLine('1KW–7KW uses Single Phase Inverter.'),
          _infoLine('8KW and above uses Single Ph / 3 Ph Hybrid Inverter (rates may differ).'),
          _infoLine('RCC Roof price is lower due to structural mounting savings.'),
          _infoLine('Subsidies are subject to government approval and availability.'),
          _infoLine('All prices include GST.'),
        ],
      ),
    );
  }

  Widget _infoLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('• ', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.blueGrey))),
      ]),
    );
  }
}

// ─── Result Model ─────────────────────────────────────────────────────────────

class _SolarResult {
  final String capacity, roofType;
  final double tinPrice, rccSaving, basePrice, mnreSubsidy, netPayable;
  final bool is3Phase;

  const _SolarResult({
    required this.capacity,
    required this.roofType,
    required this.tinPrice,
    required this.rccSaving,
    required this.basePrice,
    required this.mnreSubsidy,
    required this.netPayable,
    required this.is3Phase,
  });
}

// ─── Result Card ──────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final _SolarResult result;
  const _ResultCard({required this.result});

  static const _solar = Color(0xFFF57F17);
  static const _solarDark = Color(0xFFE65100);

  String _fmt(double v) {
    final s = v.round().toString();
    if (s.length <= 3) return '₹$s';
    String rem = s.substring(s.length - 3);
    String head = s.substring(0, s.length - 3);
    while (head.length > 2) {
      rem = '${head.substring(head.length - 2)},$rem';
      head = head.substring(0, head.length - 2);
    }
    return '₹$head,$rem';
  }

  @override
  Widget build(BuildContext context) {
    final savingPct = ((result.mnreSubsidy + result.rccSaving) / result.tinPrice * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_solarDark, _solar]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              const Icon(Icons.wb_sunny, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${result.capacity} Solar System — ${result.roofType}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              if (result.is3Phase)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('3-Ph Hybrid',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Base price row
                _priceLine('Base Price (inc. GST)', _fmt(result.tinPrice), isBase: true),
                if (result.rccSaving > 0)
                  _priceLine('RCC Roof Saving', '– ${_fmt(result.rccSaving)}', isDeduction: true),
                if (result.mnreSubsidy > 0)
                  _priceLine('Central Subsidy (MNRE)', '– ${_fmt(result.mnreSubsidy)}', isDeduction: true),
                const Divider(height: 20),
                // Net payable
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Net Payable Amount',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          Text('After all applicable subsidies',
                              style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Text(
                      _fmt(result.netPayable),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _solarDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Saving chip
                if (savingPct > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _solar.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.savings_outlined, color: _solar, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'You save $savingPct% on the gross price!',
                          style: const TextStyle(
                            color: _solarDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _sharePdf(context),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Generate & Share Quotation (PDF)',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _solarDark,
                      side: const BorderSide(color: _solarDark),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePdf(BuildContext context) async {
    await EstimatePdfService.share(
      context: context,
      title: 'Solar Installation Estimate',
      accent: _solarDark,
      specifications: {
        'System Capacity': result.capacity,
        'System Type': 'Solar System on Grid',
        'Roof Type': result.roofType,
        'Inverter': result.is3Phase ? 'Single Ph / 3 Ph Hybrid' : 'Single Phase',
      },
      details: {
        'Base Price (inc. GST)': _fmt(result.tinPrice),
        if (result.rccSaving > 0) 'RCC Roof Saving': '- ${_fmt(result.rccSaving)}',
        if (result.mnreSubsidy > 0) 'Central Subsidy (MNRE)': '- ${_fmt(result.mnreSubsidy)}',
        'Net Payable Amount': _fmt(result.netPayable),
      },
      totalValue: _fmt(result.netPayable),
      extraNote: 'Subsidies are subject to government approval and availability.',
    );
  }

  Widget _priceLine(String label, String value, {bool isBase = false, bool isDeduction = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isBase ? Colors.grey[800] : Colors.grey[600],
                fontWeight: isBase ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBase ? FontWeight.bold : FontWeight.w600,
              color: isDeduction ? const Color(0xFF2E7D32) : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
