import 'package:flutter/material.dart';
import '../data/interior_rate_card.dart' as rates;
import '../services/estimate_pdf_service.dart';

// ─── Rate Tables (from calculator app.js) ────────────────────────────────────

const Map<String, double> _bp   = {'Assam Type': 850, 'Medium RCC': 1050, 'Deluxe RCC': 1050, 'Luxury RCC': 1050};
const Map<String, double> _rr   = {'Assam Type': 1500, 'Medium RCC': 1800, 'Deluxe RCC': 2000, 'Luxury RCC': 2450};
const Map<String, double> _sr   = {'Assam': 0, 'Arunachal Pradesh': 100, 'Manipur': 100, 'Mizoram': 100, 'Nagaland': 100, 'Tripura': 100, 'Sikkim': 100, 'Meghalaya': 100};
const Map<String, double> _bath = {'Jaquar': 100, 'Hindware': 66, 'Kohler': 75, 'Cera': 66, 'Parryware': 75, 'Delta': 66};
const Map<String, double> _til  = {'Kajaria': 220, 'Johnson': 180, 'Mayra': 150, 'Somany': 180, 'Varmora': 150, 'Others': 220};
const Map<String, double> _efit = {'Paintshavels': 180, 'Polycab': 180, 'Anchor': 120, 'Philips': 180, 'Honeywell': 120, 'V-Guard': 150, 'Legrand': 120, 'Finolex': 150, 'RR Cables': 120};
const Map<String, double> _pnt  = {'Asian Paints': 160, 'Berger': 140, 'Nerolac': 150, 'Dulux': 120, 'Nippon': 120, 'Others': 160};
const Map<String, double> _drf  = {'Wood': 200, 'UPVC': 333, 'Aluminium': 133, 'TATA': 400};
const Map<String, double> _stl  = {'Durgapur': 0, 'Shyan Steel': 50000, 'Mithan': 0, 'TATA Steel': 200000, 'Essar Steel': 100000, 'JSW Steel': 100000, 'Jindal Steel': 200000};
const Map<String, double> _cem  = {'Star Cement': 30.5, 'UltraTech': 30.5, 'Tiger': 20, 'Dalmia': 20};
const Map<String, double> _brk  = {'Red Bricks': 20, 'Concrete Bricks': 20};

const Map<String, double> _floorRates = {'Floor Tiles': 150, 'Italian Marble': 350, 'Wooden Flooring': 160, 'SPC Flooring': 170, 'Vinyl Flooring': 70, 'Epoxy Flooring': 350, 'Rubber Flooring': 80};
const Map<String, double> _ewrkRates  = {'Ground Floor': 150, 'Upto 3rd Floor': 220, '4th Floor & Above': 350};
// Client rate card (Jul 2026): False Ceiling = Gypsum/Gyproc ₹85 (with material) / ₹25 (without); PVC ₹120 / ₹25.
// NOTE: this widget class is currently unused (dead code — no screen instantiates it); the
// live False Ceiling calculator is _calcFalseCeiling() in calculator_screen.dart.
const Map<String, double> _ceilRates  = {'Gypsum / Gyproc (with material)': 85, 'Gypsum / Gyproc (without material)': 25, 'PVC (with material)': 120, 'PVC (without material)': 25};
// Client rate card: Wallpaper = Modern ₹55/roll, Premium ₹80/roll (with material); ₹600/roll flat (without material, both types).
const Map<String, double> _wallpRates = {'Modern (with material)': 55, 'Premium (with material)': 80, 'Without material (any type)': 600};
const Map<String, double> _dwRates    = {'Wood': 450, 'UPVC': 900, 'Aluminium': 350, 'TATA Steel': 1250};
const Map<String, double> _pintRates  = {'Medium': 25, 'Premium': 30, 'Deluxe': 35, 'Texture': 60};
const Map<String, double> _pwoodRates = {'Medium': 220, 'Premium': 250, 'Deluxe': 350};
const Map<String, Map<String, double>> _pextRates = {
  'Ground Floor': {'Medium': 35, 'Premium': 40, 'Deluxe': 45, 'Texture': 70},
  'G+1 (2 Floors)': {'Medium': 42, 'Premium': 47, 'Deluxe': 52, 'Texture': 75},
  'G+2 & Above': {'Medium': 55, 'Premium': 61, 'Deluxe': 67, 'Texture': 82},
};
const Map<String, double> _mfWithRates    = {'Medium': 1500, 'Premium': 1800, 'Deluxe': 2000};
const Map<String, double> _mfWithoutRates = {'Medium': 400, 'Premium': 450, 'Deluxe': 500};
// Client rate card: Modular Kitchen = Medium ₹1800, Premium ₹2200, Duplex ₹2400 per sqft (with material).
const Map<String, double> _kitchRates     = {'Medium': 1800, 'Premium': 2200, 'Duplex': 2400};

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _fmt(double v) {
  if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
  if (v >= 100000)   return '₹${(v / 100000).toStringAsFixed(2)} L';
  if (v >= 1000)     return '₹${(v / 1000).toStringAsFixed(0)}K';
  return '₹${v.toStringAsFixed(0)}';
}

Widget _field(TextEditingController c, String label) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: TextField(
    controller: c,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    ),
  ),
);

Widget _drop(String label, String value, List<String> items, ValueChanged<String?> cb, {Map<String, double>? rateMap}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: DropdownButtonFormField<String>(
    value: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    ),
    items: items.map((k) => DropdownMenuItem(
      value: k,
      child: Text(
        k,
        style: const TextStyle(fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
    )).toList(),
    onChanged: cb,
  ),
);

Widget _simpleLayout({
  required Color color,
  required List<Widget> inputs,
  required VoidCallback onCalc,
  required Widget? result,
}) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        const SizedBox(height: 4),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF98A2B3), width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              ...inputs,
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onCalc,
                  icon: const Icon(Icons.calculate_outlined, size: 18),
                  label: const Text('Calculate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ]),
          ),
        ),
        if (result != null) ...[const SizedBox(height: 12), result],
      ],
    ),
  );
}

class _ResultCard extends StatelessWidget {
  final Color color;
  final String total;
  final List<MapEntry<String, String>> rows;
  final String title;

  const _ResultCard({required this.color, required this.total, required this.rows,
      this.title = 'Cost Estimate'});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          const Text('Estimated Cost', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(total, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ]),
      ),
      const SizedBox(height: 8),
      Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF98A2B3), width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            ...rows.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(child: Text(e.key, style: TextStyle(color: Colors.grey[600], fontSize: 13))),
                Text(e.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
            )),
            const SizedBox(height: 4),
            Text('* Estimates only. Actual costs may vary.', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => EstimatePdfService.share(
            context: context,
            title: title,
            accent: color,
            details: {for (final e in rows) e.key: e.value},
            totalValue: total,
          ),
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: const Text('Generate & Share Quotation (PDF)',
              style: TextStyle(fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ]);
  }
}

// ─── House Calculator Screen (wizard only) ───────────────────────────────────

class HouseCalculatorScreen extends StatelessWidget {
  const HouseCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('House Construction Calculator'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const _HouseWizard(),
    );
  }
}

// ─── House Construction Wizard ───────────────────────────────────────────────

class _HouseWizard extends StatefulWidget {
  const _HouseWizard();

  @override
  State<_HouseWizard> createState() => _HouseWizardState();
}

class _HouseWizardState extends State<_HouseWizard> {
  String _state    = 'Assam';
  String _areaType = 'Urban';
  String _quality  = 'Medium RCC';

  final _areaCtrl  = TextEditingController();
  int    _floors   = 1;
  final _excavCtrl = TextEditingController(text: '1.5');

  String _bathroom = 'Hindware';
  String _tiles    = 'Johnson';
  String _elec     = 'Anchor';
  String _paint    = 'Nerolac';
  String _doors    = 'UPVC';
  String _steel    = 'Durgapur';
  String _cement   = 'Star Cement';
  String _bricks   = 'Red Bricks';
  bool   _kitchen  = true;
  bool   _furniture = false;

  final List<MapEntry<String, String>> _breakdown = [];
  String? _totalStr;
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _areaCtrl.dispose();
    _excavCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final area = double.tryParse(_areaCtrl.text) ?? 0;
    if (area <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the built-up area in sqft')),
      );
      return;
    }
    final base    = _bp[_quality]!;
    final stAdj   = _sr[_state]!;
    final atAdj   = _areaType == 'Rural' ? 100.0 : 0.0;
    final bathAdj = _bath[_bathroom]!;
    final tilAdj  = _til[_tiles]!;
    final elAdj   = _efit[_elec]!;
    final pntAdj  = _pnt[_paint]!;
    final dorAdj  = _drf[_doors]!;
    final cemAdj  = _cem[_cement]!;
    final brkAdj  = _brk[_bricks]!;

    double excAdj = 0;
    final excD = double.tryParse(_excavCtrl.text) ?? 1.5;
    final extraSteps = ((excD - 1.5) / 0.5).floor().clamp(0, 999);
    excAdj = extraSteps * 50.0;

    final kitAdj   = _kitchen ? 100.0 : 0.0;
    final perSqft  = base + stAdj + atAdj + bathAdj + tilAdj + elAdj + pntAdj + dorAdj + cemAdj + brkAdj + excAdj + kitAdj;
    final steelAdj = _stl[_steel]!;

    final furnAdj = _furniture ? area * 1000.0 : 0.0;

    double total = area * perSqft;
    if (_floors > 1) total += (_floors - 1) * total * 0.85;
    total += furnAdj;
    total += steelAdj;

    final roofCost = area * _rr[_quality]!;

    setState(() {
      _breakdown
        ..clear()
        ..addAll([
          MapEntry('Built-up Area', '${area.toStringAsFixed(0)} sqft × $_floors floor(s)'),
          MapEntry('Base Rate ($_quality)', '₹${base.toStringAsFixed(0)}/sqft'),
          if (stAdj > 0) MapEntry('State Premium ($_state)', '+₹${stAdj.toStringAsFixed(0)}/sqft'),
          if (atAdj > 0) MapEntry('Rural Area Premium', '+₹${atAdj.toStringAsFixed(0)}/sqft'),
          MapEntry('Bathroom Fittings ($_bathroom)', '+₹${bathAdj.toStringAsFixed(0)}/sqft'),
          MapEntry('Tiles ($_tiles)', '+₹${tilAdj.toStringAsFixed(0)}/sqft'),
          MapEntry('Electrical ($_elec)', '+₹${elAdj.toStringAsFixed(0)}/sqft'),
          MapEntry('Paint ($_paint)', '+₹${pntAdj.toStringAsFixed(0)}/sqft'),
          MapEntry('Doors & Windows ($_doors)', '+₹${dorAdj.toStringAsFixed(0)}/sqft'),
          MapEntry('Cement ($_cement)', '+₹${cemAdj.toStringAsFixed(1)}/sqft'),
          MapEntry('Bricks ($_bricks)', '+₹${brkAdj.toStringAsFixed(0)}/sqft'),
          if (excAdj > 0) MapEntry('Deep Excavation Premium', '+₹${excAdj.toStringAsFixed(0)}/sqft'),
          if (_kitchen) MapEntry('Modular Kitchen', '+₹${kitAdj.toStringAsFixed(0)}/sqft'),
          MapEntry('★ Rate per sqft', '₹${perSqft.toStringAsFixed(0)}/sqft'),
          MapEntry('Ground Floor Cost', _fmt(area * perSqft)),
          if (_floors > 1) MapEntry('Additional ${_floors - 1} Floor(s)', '+${_fmt((_floors - 1) * area * perSqft * 0.85)}'),
          if (steelAdj > 0) MapEntry('Premium Steel ($_steel)', '+${_fmt(steelAdj)}'),
          if (_furniture) MapEntry('Modular Furniture', '+${_fmt(furnAdj)} @ ₹1000/sqft'),
          MapEntry('Roof / Slab Estimate', '${_fmt(roofCost)} @ ₹${_rr[_quality]!.toStringAsFixed(0)}/sqft'),
        ]);
      _totalStr = _fmt(total);
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 600), curve: Curves.easeOut);
      }
    });
  }

  Widget _qualityCard(String q) {
    final sel = _quality == q;
    return GestureDetector(
      onTap: () => setState(() => _quality = q),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF1B5E20) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sel ? const Color(0xFF1B5E20) : Colors.grey[300]!),
          boxShadow: sel ? [BoxShadow(color: const Color(0xFF1B5E20).withAlpha(50), blurRadius: 8, offset: const Offset(0, 2))] : [],
        ),
        child: Text(q, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: sel ? Colors.white : Colors.black87)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.only(bottom: 24),
      children: [
          _section(1, 'Location & Area', Icons.location_on_outlined, [
            _drop('State', _state, _sr.keys.toList(), (v) => setState(() => _state = v!)),
            Row(children: [
              for (final t in ['Urban', 'Rural']) Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: t == 'Urban' ? 6 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _areaType = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: _areaType == t ? const Color(0xFF1B5E20) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _areaType == t ? const Color(0xFF1B5E20) : Colors.grey[300]!),
                      ),
                      child: Text(t, textAlign: TextAlign.center,
                        style: TextStyle(color: _areaType == t ? Colors.white : Colors.grey[700], fontWeight: _areaType == t ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
                    ),
                  ),
                ),
              ),
            ]),
          ]),

          _section(2, 'Construction Type', Icons.home_work_outlined, [
            Row(children: [
              Expanded(child: _qualityCard('Assam Type')),
              const SizedBox(width: 10),
              Expanded(child: _qualityCard('Medium RCC')),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _qualityCard('Deluxe RCC')),
              const SizedBox(width: 10),
              Expanded(child: _qualityCard('Luxury RCC')),
            ]),
          ]),

          _section(3, 'Size & Floors', Icons.straighten_outlined, [
            _field(_areaCtrl, 'Built-up Area (sqft) *'),
            Row(children: [
              Text('Number of Floors:', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
              const Spacer(),
              for (int i = 1; i <= 6; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: GestureDetector(
                    onTap: () => setState(() => _floors = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: _floors == i ? const Color(0xFF1B5E20) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: _floors == i ? const Color(0xFF1B5E20) : Colors.grey[300]!),
                      ),
                      child: Center(child: Text('$i', style: TextStyle(fontWeight: FontWeight.bold, color: _floors == i ? Colors.white : Colors.grey[700], fontSize: 13))),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 12),
            _field(_excavCtrl, 'Excavation Depth in meters (default: 1.5)'),
          ]),

          _section(4, 'Material Selection', Icons.category_outlined, [
            _drop('Bathroom Fittings', _bathroom, _bath.keys.toList(), (v) => setState(() => _bathroom = v!), rateMap: _bath),
            _drop('Tiles Brand', _tiles, _til.keys.toList(), (v) => setState(() => _tiles = v!), rateMap: _til),
            _drop('Electrical Fittings', _elec, _efit.keys.toList(), (v) => setState(() => _elec = v!), rateMap: _efit),
            _drop('Paint Brand', _paint, _pnt.keys.toList(), (v) => setState(() => _paint = v!), rateMap: _pnt),
            _drop('Doors & Windows', _doors, _drf.keys.toList(), (v) => setState(() => _doors = v!), rateMap: _drf),
            _drop('Steel Brand', _steel, _stl.keys.toList(), (v) => setState(() => _steel = v!)),
            _drop('Cement Brand', _cement, _cem.keys.toList(), (v) => setState(() => _cement = v!), rateMap: _cem),
            _drop('Bricks Type', _bricks, _brk.keys.toList(), (v) => setState(() => _bricks = v!)),
            SwitchListTile(
              title: const Text('Include Modular Kitchen', style: TextStyle(fontSize: 13)),
              subtitle: const Text('Adds ₹100/sqft to the rate', style: TextStyle(fontSize: 11)),
              value: _kitchen, onChanged: (v) => setState(() => _kitchen = v),
              activeColor: const Color(0xFF1B5E20), contentPadding: EdgeInsets.zero, dense: true,
            ),
            SwitchListTile(
              title: const Text('Include Modular Furniture', style: TextStyle(fontSize: 13)),
              subtitle: const Text('Adds ₹1000/sqft to total', style: TextStyle(fontSize: 11)),
              value: _furniture, onChanged: (v) => setState(() => _furniture = v),
              activeColor: const Color(0xFF1B5E20), contentPadding: EdgeInsets.zero, dense: true,
            ),
          ]),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Calculate Total Cost', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),

          if (_totalStr != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF388E3C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Total Construction Estimate', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(_totalStr!, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('${_areaCtrl.text} sqft × $_floors floor(s) • $_state • $_quality', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFF98A2B3), width: 1.2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cost Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      ..._breakdown.map((e) {
                        final hi = e.key.startsWith('★') || e.key.startsWith('Roof');
                        return Container(
                          margin: const EdgeInsets.only(bottom: 5),
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                          decoration: BoxDecoration(
                            color: hi ? const Color(0xFF1B5E20).withAlpha(15) : Colors.grey[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(children: [
                            Expanded(child: Text(e.key, style: TextStyle(fontSize: 12, color: hi ? const Color(0xFF1B5E20) : Colors.grey[700], fontWeight: hi ? FontWeight.bold : FontWeight.normal))),
                            Text(e.value, style: TextStyle(fontSize: 13, fontWeight: hi ? FontWeight.bold : FontWeight.normal, color: hi ? const Color(0xFF1B5E20) : Colors.black87)),
                          ]),
                        );
                      }),
                      const SizedBox(height: 6),
                      Text('* Estimates only. Actual costs may vary.', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _sharePdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('Generate & Share Quotation (PDF)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1B5E20),
                    side: const BorderSide(color: Color(0xFF1B5E20)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ],
    );
  }

  Future<void> _sharePdf() async {
    if (_totalStr == null) return;
    await EstimatePdfService.share(
      context: context,
      title: 'House Construction Estimate',
      accent: const Color(0xFF1B5E20),
      specifications: {
        'State': _state,
        'Area Type': _areaType,
        'Construction Type': _quality,
        'Built-up Area': '${_areaCtrl.text} sqft',
        'Floors': '$_floors',
        'Excavation Depth': '${_excavCtrl.text} m',
        'Bathroom Fittings': _bathroom,
        'Tiles': _tiles,
        'Electrical': _elec,
        'Paint': _paint,
        'Doors & Windows': _doors,
        'Steel': _steel,
        'Cement': _cement,
        'Bricks': _bricks,
        'Modular Kitchen': _kitchen ? 'Included' : 'Not included',
        'Modular Furniture': _furniture ? 'Included' : 'Not included',
      },
      details: {for (final e in _breakdown) e.key: e.value},
      totalValue: _totalStr,
    );
  }

  Widget _section(int num, String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF98A2B3), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 13, backgroundColor: const Color(0xFF1B5E20), child: Text('$num', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
            const SizedBox(width: 10),
            Icon(icon, color: const Color(0xFF1B5E20), size: 18),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
          const Divider(height: 20),
          ...children,
        ]),
      ),
    );
  }
}

// ─── Public cost calculator widgets (used from main calculator screen) ────────

class PaintCostCalculator extends StatefulWidget {
  const PaintCostCalculator({super.key});
  @override State<PaintCostCalculator> createState() => _PaintCostState();
}

class _PaintCostState extends State<PaintCostCalculator> {
  static const _color = Color(0xFF6A1B9A);
  String _type    = 'Interior';
  String _quality = 'Medium';
  String _floors  = 'Ground Floor';
  final _areaCtrl = TextEditingController();
  _ResultCard? _result;

  @override void dispose() { _areaCtrl.dispose(); super.dispose(); }

  void _calc() {
    final area = double.tryParse(_areaCtrl.text) ?? 0;
    if (area <= 0) return;
    double rate;
    if (_type == 'Interior') {
      rate = _pintRates[_quality]!;
    } else if (_type == 'Exterior') {
      rate = _pextRates[_floors]![_quality]!;
    } else if (_type == 'Wood Furniture') {
      rate = _pwoodRates[_quality]!;
    } else {
      rate = 40; // Waterproofing — client rate card (Jul 2026): ₹40/sqft flat
    }
    final total = area * rate;
    setState(() => _result = _ResultCard(
      color: _color, total: _fmt(total), title: 'Painting Cost Estimate',
      rows: [
        MapEntry('Type', _type),
        if (_type != 'Waterproofing') MapEntry('Quality', _quality),
        if (_type == 'Exterior') MapEntry('Building Height', _floors),
        MapEntry('Paintable Area', '${area.toStringAsFixed(0)} sqft'),
        MapEntry('Rate', '₹${rate.toStringAsFixed(0)}/sqft'),
        MapEntry('Total Estimate', _fmt(total)),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return _simpleLayout(
      color: _color, onCalc: _calc, result: _result,
      inputs: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Wrap(spacing: 6, children: [
            for (final t in ['Interior', 'Exterior', 'Wood Furniture', 'Waterproofing'])
              GestureDetector(
                onTap: () => setState(() { _type = t; _quality = 'Medium'; }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _type == t ? _color : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(t, style: TextStyle(fontSize: 12, color: _type == t ? Colors.white : Colors.grey[700], fontWeight: _type == t ? FontWeight.bold : FontWeight.normal)),
                ),
              ),
          ]),
        ),
        if (_type != 'Waterproofing')
          _drop('Quality', _quality,
            _type == 'Wood Furniture' ? _pwoodRates.keys.toList() : _pintRates.keys.toList(),
            (v) => setState(() => _quality = v!)),
        if (_type == 'Exterior')
          _drop('Building Height', _floors, _pextRates.keys.toList(), (v) => setState(() => _floors = v!)),
        _field(_areaCtrl, _type == 'Exterior' ? 'Outer Wall Area (sqft)' : 'Paintable Area (sqft)'),
      ],
    );
  }
}

class FurnitureCostCalculator extends StatefulWidget {
  const FurnitureCostCalculator({super.key});
  @override State<FurnitureCostCalculator> createState() => _FurnitureCostState();
}

class _FurnitureCostState extends State<FurnitureCostCalculator> {
  static const _color = Color(0xFF37474F);
  bool   _withMat  = true;
  String _quality  = 'Medium';
  final _areaCtrl  = TextEditingController();
  _ResultCard? _result;

  @override void dispose() { _areaCtrl.dispose(); super.dispose(); }

  void _calc() {
    final area = double.tryParse(_areaCtrl.text) ?? 0;
    if (area <= 0) return;
    final rateMap = _withMat ? _mfWithRates : _mfWithoutRates;
    final rate    = rateMap[_quality]!;
    final total   = area * rate;
    setState(() => _result = _ResultCard(
      color: _color, total: _fmt(total), title: 'Modular Furniture Estimate',
      rows: [
        MapEntry('Material Provision', _withMat ? 'With Materials' : 'Without Materials'),
        MapEntry('Quality', _quality),
        MapEntry('Floor Area', '${area.toStringAsFixed(0)} sqft'),
        MapEntry('Rate', '₹${rate.toStringAsFixed(0)}/sqft'),
        MapEntry('Total Estimate', _fmt(total)),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return _simpleLayout(
      color: _color, onCalc: _calc, result: _result,
      inputs: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            for (final m in ['With Materials', 'Without Materials']) Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: m == 'With Materials' ? 6 : 0),
                child: GestureDetector(
                  onTap: () => setState(() => _withMat = m == 'With Materials'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: (_withMat == (m == 'With Materials')) ? _color : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(m, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: (_withMat == (m == 'With Materials')) ? Colors.white : Colors.grey[700])),
                  ),
                ),
              ),
            ),
          ]),
        ),
        _drop('Quality', _quality, (_withMat ? _mfWithRates : _mfWithoutRates).keys.toList(),
          (v) => setState(() => _quality = v!), rateMap: _withMat ? _mfWithRates : _mfWithoutRates),
        _field(_areaCtrl, 'Floor Area (sqft)'),
      ],
    );
  }
}

class KitchenCostCalculator extends StatefulWidget {
  const KitchenCostCalculator({super.key});
  @override State<KitchenCostCalculator> createState() => _KitchenCostState();
}

class _KitchenCostState extends State<KitchenCostCalculator> {
  static const _color = Color(0xFF880E4F);
  String _quality    = 'Medium';
  String _cabinetType = 'Upper Cabinet';
  final _lenCtrl  = TextEditingController();
  final _htCtrl   = TextEditingController();
  _ResultCard? _result;

  @override void dispose() { _lenCtrl.dispose(); _htCtrl.dispose(); super.dispose(); }

  void _calc() {
    final len = double.tryParse(_lenCtrl.text) ?? 0;
    final rate = _kitchRates[_quality]!;

    if (_cabinetType == 'Upper Cabinet') {
      final ht = double.tryParse(_htCtrl.text) ?? 0;
      if (len <= 0 || ht <= 0) return;
      final area  = len * ht;
      final total = area * rate;
      setState(() => _result = _ResultCard(
        color: _color, total: _fmt(total), title: 'Modular Kitchen Estimate',
        rows: [
          MapEntry('Type', 'Upper Cabinet'),
          MapEntry('Quality', _quality),
          MapEntry('Length', '${len.toStringAsFixed(1)} ft'),
          MapEntry('Height', '${ht.toStringAsFixed(1)} ft'),
          MapEntry('Area', '${area.toStringAsFixed(2)} sqft'),
          MapEntry('Rate', '₹${rate.toStringAsFixed(0)}/sqft'),
          MapEntry('Total Estimate', _fmt(total)),
        ],
      ));
    } else {
      if (len <= 0) return;
      final total = len * rate;
      setState(() => _result = _ResultCard(
        color: _color, total: _fmt(total), title: 'Modular Kitchen Estimate',
        rows: [
          MapEntry('Type', 'Lower Counter'),
          MapEntry('Quality', _quality),
          MapEntry('Running Length', '${len.toStringAsFixed(1)} ft'),
          MapEntry('Rate', '₹${rate.toStringAsFixed(0)}/running ft'),
          MapEntry('Total Estimate', _fmt(total)),
        ],
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpper = _cabinetType == 'Upper Cabinet';
    return _simpleLayout(
      color: _color, onCalc: _calc, result: _result,
      inputs: [
        _drop('Cabinet Type', _cabinetType, const ['Upper Cabinet', 'Lower Counter'],
          (v) => setState(() { _cabinetType = v!; _result = null; })),
        _drop('Finish Quality', _quality, _kitchRates.keys.toList(),
          (v) => setState(() => _quality = v!), rateMap: _kitchRates),
        _field(_lenCtrl, 'Length (ft)'),
        if (isUpper) _field(_htCtrl, 'Height (ft)'),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            isUpper
                ? 'Upper cabinet: Length × Height × rate/sqft'
                : 'Lower counter: Running length × rate/ft',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ),
      ],
    );
  }
}

class FlooringCostCalculator extends StatefulWidget {
  const FlooringCostCalculator({super.key});
  @override State<FlooringCostCalculator> createState() => _FlooringCostState();
}

class _FlooringCostState extends State<FlooringCostCalculator> {
  static const _color = Color(0xFF5D4037);
  String _type    = 'Floor Tiles';
  final _areaCtrl = TextEditingController();
  _ResultCard? _result;

  @override void dispose() { _areaCtrl.dispose(); super.dispose(); }

  void _calc() {
    final area = double.tryParse(_areaCtrl.text) ?? 0;
    if (area <= 0) return;
    final rate = _floorRates[_type]!;
    final total = area * rate;
    setState(() => _result = _ResultCard(
      color: _color, total: _fmt(total), title: 'Flooring Cost Estimate',
      rows: [MapEntry('Type', _type), MapEntry('Area', '${area.toStringAsFixed(0)} sqft'), MapEntry('Rate', '₹${rate.toStringAsFixed(0)}/sqft'), MapEntry('Total', _fmt(total))],
    ));
  }

  @override
  Widget build(BuildContext context) => _simpleLayout(
    color: _color, onCalc: _calc, result: _result,
    inputs: [_drop('Flooring Type', _type, _floorRates.keys.toList(), (v) => setState(() => _type = v!), rateMap: _floorRates), _field(_areaCtrl, 'Floor Area (sqft)')],
  );
}

class ElectricalCostCalculator extends StatefulWidget {
  const ElectricalCostCalculator({super.key});
  @override State<ElectricalCostCalculator> createState() => _ElectricalCostState();
}

class _ElectricalCostState extends State<ElectricalCostCalculator> {
  static const _color = Color(0xFFF57F17);
  String _level   = 'Ground Floor';
  final _areaCtrl = TextEditingController();
  _ResultCard? _result;

  @override void dispose() { _areaCtrl.dispose(); super.dispose(); }

  void _calc() {
    final area = double.tryParse(_areaCtrl.text) ?? 0;
    if (area <= 0) return;
    final rate = _ewrkRates[_level]!;
    final total = area * rate;
    setState(() => _result = _ResultCard(
      color: _color, total: _fmt(total), title: 'Electrical Work Estimate',
      rows: [MapEntry('Floor Level', _level), MapEntry('Area', '${area.toStringAsFixed(0)} sqft'), MapEntry('Rate', '₹${rate.toStringAsFixed(0)}/sqft'), MapEntry('Total', _fmt(total))],
    ));
  }

  @override
  Widget build(BuildContext context) => _simpleLayout(
    color: _color, onCalc: _calc, result: _result,
    inputs: [_drop('Floor Level', _level, _ewrkRates.keys.toList(), (v) => setState(() => _level = v!), rateMap: _ewrkRates), _field(_areaCtrl, 'Floor Area (sqft)')],
  );
}

class FalseCeilingCostCalculator extends StatefulWidget {
  const FalseCeilingCostCalculator({super.key});
  @override State<FalseCeilingCostCalculator> createState() => _FalseCeilingCostState();
}

class _FalseCeilingCostState extends State<FalseCeilingCostCalculator> {
  static const _color = Color(0xFF283593);
  String _type    = 'Gypsum / Gyproc (with material)';
  final _areaCtrl = TextEditingController();
  _ResultCard? _result;

  @override void dispose() { _areaCtrl.dispose(); super.dispose(); }

  void _calc() {
    final area = double.tryParse(_areaCtrl.text) ?? 0;
    if (area <= 0) return;
    final rate = _ceilRates[_type]!;
    final total = area * rate;
    setState(() => _result = _ResultCard(
      color: _color, total: _fmt(total), title: 'False Ceiling Estimate',
      rows: [MapEntry('Type', _type), MapEntry('Area', '${area.toStringAsFixed(0)} sqft'), MapEntry('Rate', '₹${rate.toStringAsFixed(0)}/sqft'), MapEntry('Total', _fmt(total))],
    ));
  }

  @override
  Widget build(BuildContext context) => _simpleLayout(
    color: _color, onCalc: _calc, result: _result,
    inputs: [_drop('Ceiling Type', _type, _ceilRates.keys.toList(), (v) => setState(() => _type = v!), rateMap: _ceilRates), _field(_areaCtrl, 'Ceiling Area (sqft)')],
  );
}

class WallpaperCostCalculator extends StatefulWidget {
  const WallpaperCostCalculator({super.key});
  @override State<WallpaperCostCalculator> createState() => _WallpaperCostState();
}

class _WallpaperCostState extends State<WallpaperCostCalculator> {
  static const _color = Color(0xFF558B2F);
  String _type    = 'Modern (with material)';
  final _areaCtrl = TextEditingController();
  _ResultCard? _result;

  @override void dispose() { _areaCtrl.dispose(); super.dispose(); }

  void _calc() {
    final area = double.tryParse(_areaCtrl.text) ?? 0;
    if (area <= 0) return;
    final rate = _wallpRates[_type]!;
    final total = area * rate;
    setState(() => _result = _ResultCard(
      color: _color, total: _fmt(total), title: 'Wallpaper Cost Estimate',
      rows: [MapEntry('Type', _type), MapEntry('Wall Area', '${area.toStringAsFixed(0)} sqft'), MapEntry('Rate', '₹${rate.toStringAsFixed(0)}/sqft'), MapEntry('Total', _fmt(total))],
    ));
  }

  @override
  Widget build(BuildContext context) => _simpleLayout(
    color: _color, onCalc: _calc, result: _result,
    inputs: [_drop('Wallpaper Type', _type, _wallpRates.keys.toList(), (v) => setState(() => _type = v!), rateMap: _wallpRates), _field(_areaCtrl, 'Wall Area (sqft) = Length × Height')],
  );
}

class DoorsWindowsCostCalculator extends StatefulWidget {
  const DoorsWindowsCostCalculator({super.key});
  @override State<DoorsWindowsCostCalculator> createState() => _DoorsWindowsCostState();
}

class _DoorsWindowsCostState extends State<DoorsWindowsCostCalculator> {
  static const _color = Color(0xFF795548);
  String _type    = 'UPVC';
  final _areaCtrl = TextEditingController();
  _ResultCard? _result;

  @override void dispose() { _areaCtrl.dispose(); super.dispose(); }

  void _calc() {
    final area = double.tryParse(_areaCtrl.text) ?? 0;
    if (area <= 0) return;
    final rate = _dwRates[_type]!;
    final total = area * rate;
    setState(() => _result = _ResultCard(
      color: _color, total: _fmt(total), title: 'Doors & Windows Estimate',
      rows: [MapEntry('Material', _type), MapEntry('Total Area', '${area.toStringAsFixed(0)} sqft'), MapEntry('Rate', '₹${rate.toStringAsFixed(0)}/sqft'), MapEntry('Total', _fmt(total))],
    ));
  }

  @override
  Widget build(BuildContext context) => _simpleLayout(
    color: _color, onCalc: _calc, result: _result,
    inputs: [
      _drop('Door & Window Material', _type, _dwRates.keys.toList(), (v) => setState(() => _type = v!), rateMap: _dwRates),
      _field(_areaCtrl, 'Total Door + Window Area (sqft)'),
      Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('Tip: Door ≈ 21 sqft, Window ≈ 12–15 sqft', style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
    ],
  );
}

// ─── Full Interior Calculator (wizard) ───────────────────────────────────────
//
// Combines every finishing/MEP/woodwork category from the client rate card
// (rates.* — shared with calculator_screen.dart's per-category tools) into a
// single toggle-what-you-need estimate, the same way _HouseWizard combines
// whole-house construction categories.

class InteriorCalculatorScreen extends StatelessWidget {
  const InteriorCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Full Interior Calculator'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const _InteriorWizard(),
    );
  }
}

class _InteriorWizard extends StatefulWidget {
  const _InteriorWizard();

  @override
  State<_InteriorWizard> createState() => _InteriorWizardState();
}

class _InteriorWizardState extends State<_InteriorWizard> {
  static const _color = Color(0xFF6A1B9A);

  bool _incWaterproof = false;
  bool _incTiles = false;
  bool _incPaint = false;
  bool _incCeiling = false;
  bool _incPanel = false;
  bool _incWallpaper = false;
  bool _incPartition = false;
  bool _incElectrical = false;
  bool _incPlumbing = false;
  bool _incHomeAutomation = false;
  bool _incKitchen = false;
  bool _incWardrobe = false;
  bool _incBed = false;
  bool _incTvUnit = false;
  bool _incBasinCabinet = false;
  bool _incMsRailing = false;

  String _tileMat = 'With Material';
  String _waterproofMat = 'With Material';
  String _paintMat = 'With Material';
  String _ceilType = 'Gypsum / Gyproc';
  String _ceilMat = 'With Material';
  String _panelType = 'PVC';
  String _panelMat = 'With Material';
  String _wallpaperType = 'Modern';
  String _wallpaperMat = 'With Material';
  String _partitionType = 'Glass & Rubber';
  String _partitionMat = 'With Material';
  String _electricalMat = 'With Material';
  String _plumbingTier = 'Normal';
  String _plumbingMat = 'With Material';
  String _kitchenTier = 'Medium';
  String _kitchenMat = 'With Material';
  String _wardrobeType = 'Openable';
  String _wardrobeMat = 'With Material';
  String _bedTier = 'Medium';
  String _bedMat = 'With Material';
  String _tvUnitTier = 'Medium';
  String _tvUnitMat = 'With Material';
  String _basinCabinetTier = 'Medium';
  String _basinCabinetMat = 'With Material';
  String _msRailingTier = 'Medium';
  String _msRailingMat = 'With Material';

  final _waterproofArea = TextEditingController();
  final _tileArea = TextEditingController();
  final _paintArea = TextEditingController();
  final _ceilArea = TextEditingController();
  final _panelArea = TextEditingController();
  final _wallpaperRolls = TextEditingController();
  final _partitionArea = TextEditingController();
  final _electricalArea = TextEditingController();
  final _plumbingBaths = TextEditingController();
  final _homeAutomationRooms = TextEditingController();
  final _kitchenArea = TextEditingController();
  final _wardrobeArea = TextEditingController();
  final _bedQty = TextEditingController();
  final _tvUnitArea = TextEditingController();
  final _basinCabinetArea = TextEditingController();
  final _msRailingLength = TextEditingController();

  final List<MapEntry<String, String>> _breakdown = [];
  String? _totalStr;
  double _total = 0;
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    for (final c in [
      _waterproofArea, _tileArea, _paintArea, _ceilArea, _panelArea, _wallpaperRolls,
      _partitionArea, _electricalArea, _plumbingBaths, _homeAutomationRooms,
      _kitchenArea, _wardrobeArea, _bedQty, _tvUnitArea, _basinCabinetArea, _msRailingLength,
    ]) {
      c.dispose();
    }
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _addLine(String label, double qty, double rate, String unit) {
    if (qty <= 0) return;
    final cost = qty * rate;
    _total += cost;
    final qtyStr = qty == qty.roundToDouble() ? qty.toStringAsFixed(0) : qty.toStringAsFixed(1);
    _breakdown.add(MapEntry(label, '$qtyStr $unit × ₹${rate.toStringAsFixed(0)} = ${_fmt(cost)}'));
  }

  void _calculate() {
    _breakdown.clear();
    _total = 0;

    if (_incWaterproof) {
      final rate = _waterproofMat == 'With Material' ? rates.waterproofWithRate : rates.waterproofWithoutRate;
      _addLine('Waterproofing ($_waterproofMat)', double.tryParse(_waterproofArea.text) ?? 0, rate, 'sqft');
    }
    if (_incTiles) {
      final rate = _tileMat == 'With Material' ? rates.tileWithRate : rates.tileWithoutRate;
      _addLine('Tiles ($_tileMat)', double.tryParse(_tileArea.text) ?? 0, rate, 'sqft');
    }
    if (_incPaint) {
      final rate = _paintMat == 'With Material' ? rates.paintWithRate : rates.paintWithoutRate;
      _addLine('Painting ($_paintMat)', double.tryParse(_paintArea.text) ?? 0, rate, 'sqft');
    }
    if (_incCeiling) {
      final rate = (_ceilMat == 'With Material' ? rates.ceilingWithRates : rates.ceilingWithoutRates)[_ceilType]!;
      _addLine('False Ceiling ($_ceilType, $_ceilMat)', double.tryParse(_ceilArea.text) ?? 0, rate, 'sqft');
    }
    if (_incPanel) {
      final rate = (_panelMat == 'With Material' ? rates.panelWithRates : rates.panelWithoutRates)[_panelType]!;
      _addLine('Wall Panel ($_panelType, $_panelMat)', double.tryParse(_panelArea.text) ?? 0, rate, 'sqft');
    }
    if (_incWallpaper) {
      final rate = _wallpaperMat == 'With Material' ? rates.wallpaperWithRates[_wallpaperType]! : rates.wallpaperWithoutRate;
      _addLine('Wallpaper ($_wallpaperType, $_wallpaperMat)', double.tryParse(_wallpaperRolls.text) ?? 0, rate, 'roll(s)');
    }
    if (_incPartition) {
      final rate = (_partitionMat == 'With Material' ? rates.partitionWithRates : rates.partitionWithoutRates)[_partitionType]!;
      _addLine('Partition ($_partitionType, $_partitionMat)', double.tryParse(_partitionArea.text) ?? 0, rate, 'sqft');
    }
    if (_incElectrical) {
      final rate = _electricalMat == 'With Material' ? rates.electricalWithRate : rates.electricalWithoutRate;
      _addLine('Electrical ($_electricalMat)', double.tryParse(_electricalArea.text) ?? 0, rate, 'sqft');
    }
    if (_incPlumbing) {
      final rate = (_plumbingMat == 'With Material' ? rates.plumbingWithRates : rates.plumbingWithoutRates)[_plumbingTier]!;
      _addLine('Plumbing ($_plumbingTier, $_plumbingMat)', double.tryParse(_plumbingBaths.text) ?? 0, rate, 'bathroom(s)');
    }
    if (_incHomeAutomation) _addLine('Home Automation', double.tryParse(_homeAutomationRooms.text) ?? 0, rates.homeAutomationRate, 'room(s)');
    if (_incKitchen) {
      final rate = (_kitchenMat == 'With Material' ? rates.kitchenWithRates : rates.kitchenWithoutRates)[_kitchenTier]!;
      _addLine('Modular Kitchen ($_kitchenTier, $_kitchenMat)', double.tryParse(_kitchenArea.text) ?? 0, rate, 'sqft');
    }
    if (_incWardrobe) {
      final rate = (_wardrobeMat == 'With Material' ? rates.wardrobeWithRates : rates.wardrobeWithoutRates)[_wardrobeType]!;
      _addLine('Wardrobe ($_wardrobeType, $_wardrobeMat)', double.tryParse(_wardrobeArea.text) ?? 0, rate, 'sqft');
    }
    if (_incBed) {
      final rate = (_bedMat == 'With Material' ? rates.bedWithRates : rates.bedWithoutRates)[_bedTier]!;
      _addLine('Bed ($_bedTier, $_bedMat)', double.tryParse(_bedQty.text) ?? 0, rate, 'nos.');
    }
    if (_incTvUnit) {
      final rate = (_tvUnitMat == 'With Material' ? rates.tvUnitWithRates : rates.tvUnitWithoutRates)[_tvUnitTier]!;
      _addLine('TV Unit ($_tvUnitTier, $_tvUnitMat)', double.tryParse(_tvUnitArea.text) ?? 0, rate, 'sqft');
    }
    if (_incBasinCabinet) {
      final rate = (_basinCabinetMat == 'With Material' ? rates.basinCabinetWithRates : rates.basinCabinetWithoutRates)[_basinCabinetTier]!;
      _addLine('Basin Cabinet ($_basinCabinetTier, $_basinCabinetMat)', double.tryParse(_basinCabinetArea.text) ?? 0, rate, 'sqft');
    }
    if (_incMsRailing) {
      final rate = (_msRailingMat == 'With Material' ? rates.msRailingWithRates : rates.msRailingWithoutRates)[_msRailingTier]!;
      _addLine('MS Railing ($_msRailingTier, $_msRailingMat)', double.tryParse(_msRailingLength.text) ?? 0, rate, 'RFT');
    }

    if (_breakdown.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Turn on at least one item and enter its quantity')),
      );
      return;
    }

    setState(() => _totalStr = _fmt(_total));

    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 600), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _sharePdf() async {
    if (_totalStr == null) return;
    await EstimatePdfService.share(
      context: context,
      title: 'Full Interior Cost Estimate',
      accent: _color,
      details: {for (final e in _breakdown) e.key: e.value},
      totalValue: _totalStr,
    );
  }

  Widget _itemToggle(String title, bool included, ValueChanged<bool> onChanged, List<Widget> details) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: included ? _color.withAlpha(12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            value: included,
            onChanged: onChanged,
            activeColor: _color,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            dense: true,
          ),
          if (included)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Column(children: details),
            ),
        ],
      ),
    );
  }

  Widget _group(String title, IconData icon, List<Widget> items) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF98A2B3), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: _color, size: 18),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
          const Divider(height: 18),
          ...items,
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Turn on the items you need and enter their quantity — the total combines every category into one estimate.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),

        _group('Ceilings, Walls & Surfaces', Icons.format_paint_outlined, [
          _itemToggle('Waterproofing', _incWaterproof, (v) => setState(() => _incWaterproof = v), [
            _drop('Material Provision', _waterproofMat, const ['With Material', 'Without Material'], (v) => setState(() => _waterproofMat = v!)),
            _field(_waterproofArea, 'Area (sqft)'),
          ]),
          _itemToggle('Tiles', _incTiles, (v) => setState(() => _incTiles = v), [
            _drop('Material Provision', _tileMat, const ['With Material', 'Without Material'], (v) => setState(() => _tileMat = v!)),
            _field(_tileArea, 'Area (sqft)'),
          ]),
          _itemToggle('Painting', _incPaint, (v) => setState(() => _incPaint = v), [
            _drop('Material Provision', _paintMat, const ['With Material', 'Without Material'], (v) => setState(() => _paintMat = v!)),
            _field(_paintArea, 'Paintable Area (sqft)'),
          ]),
          _itemToggle('False Ceiling', _incCeiling, (v) => setState(() => _incCeiling = v), [
            _drop('Ceiling Type', _ceilType, rates.ceilingWithRates.keys.toList(), (v) => setState(() => _ceilType = v!)),
            _drop('Material Provision', _ceilMat, const ['With Material', 'Without Material'], (v) => setState(() => _ceilMat = v!)),
            _field(_ceilArea, 'Ceiling Area (sqft)'),
          ]),
          _itemToggle('Wall Panel', _incPanel, (v) => setState(() => _incPanel = v), [
            _drop('Panel Type', _panelType, rates.panelWithRates.keys.toList(), (v) => setState(() => _panelType = v!)),
            _drop('Material Provision', _panelMat, const ['With Material', 'Without Material'], (v) => setState(() => _panelMat = v!)),
            _field(_panelArea, 'Panel Area (sqft)'),
          ]),
          _itemToggle('Wallpaper', _incWallpaper, (v) => setState(() => _incWallpaper = v), [
            _drop('Wallpaper Type', _wallpaperType, rates.wallpaperWithRates.keys.toList(), (v) => setState(() => _wallpaperType = v!)),
            _drop('Material Provision', _wallpaperMat, const ['With Material', 'Without Material'], (v) => setState(() => _wallpaperMat = v!)),
            _field(_wallpaperRolls, 'Number of Rolls'),
          ]),
          _itemToggle('Partition', _incPartition, (v) => setState(() => _incPartition = v), [
            _drop('Partition Type', _partitionType, rates.partitionWithRates.keys.toList(), (v) => setState(() => _partitionType = v!)),
            _drop('Material Provision', _partitionMat, const ['With Material', 'Without Material'], (v) => setState(() => _partitionMat = v!)),
            _field(_partitionArea, 'Partition Area (sqft)'),
          ]),
        ]),

        _group('Electrical & Plumbing', Icons.bolt_outlined, [
          _itemToggle('Electrical', _incElectrical, (v) => setState(() => _incElectrical = v), [
            _drop('Material Provision', _electricalMat, const ['With Material', 'Without Material'], (v) => setState(() => _electricalMat = v!)),
            _field(_electricalArea, 'Floor Area (sqft)'),
          ]),
          _itemToggle('Plumbing', _incPlumbing, (v) => setState(() => _incPlumbing = v), [
            _drop('Package', _plumbingTier, rates.plumbingWithRates.keys.toList(), (v) => setState(() => _plumbingTier = v!)),
            _drop('Material Provision', _plumbingMat, const ['With Material', 'Without Material'], (v) => setState(() => _plumbingMat = v!)),
            _field(_plumbingBaths, 'Number of Bathrooms'),
          ]),
          _itemToggle('Home Automation', _incHomeAutomation, (v) => setState(() => _incHomeAutomation = v), [
            _field(_homeAutomationRooms, 'Number of Rooms'),
          ]),
        ]),

        _group('Furniture & Fixtures', Icons.chair_outlined, [
          _itemToggle('Modular Kitchen', _incKitchen, (v) => setState(() => _incKitchen = v), [
            _drop('Package', _kitchenTier, rates.kitchenWithRates.keys.toList(), (v) => setState(() => _kitchenTier = v!)),
            _drop('Material Provision', _kitchenMat, const ['With Material', 'Without Material'], (v) => setState(() => _kitchenMat = v!)),
            _field(_kitchenArea, 'Cabinet Area (sqft)'),
          ]),
          _itemToggle('Wardrobe', _incWardrobe, (v) => setState(() => _incWardrobe = v), [
            _drop('Type', _wardrobeType, rates.wardrobeWithRates.keys.toList(), (v) => setState(() => _wardrobeType = v!)),
            _drop('Material Provision', _wardrobeMat, const ['With Material', 'Without Material'], (v) => setState(() => _wardrobeMat = v!)),
            _field(_wardrobeArea, 'Wardrobe Area (sqft)'),
          ]),
          _itemToggle('Bed', _incBed, (v) => setState(() => _incBed = v), [
            _drop('Package', _bedTier, rates.bedWithRates.keys.toList(), (v) => setState(() => _bedTier = v!)),
            _drop('Material Provision', _bedMat, const ['With Material', 'Without Material'], (v) => setState(() => _bedMat = v!)),
            _field(_bedQty, 'Quantity (number of beds)'),
          ]),
          _itemToggle('TV Unit', _incTvUnit, (v) => setState(() => _incTvUnit = v), [
            _drop('Package', _tvUnitTier, rates.tvUnitWithRates.keys.toList(), (v) => setState(() => _tvUnitTier = v!)),
            _drop('Material Provision', _tvUnitMat, const ['With Material', 'Without Material'], (v) => setState(() => _tvUnitMat = v!)),
            _field(_tvUnitArea, 'TV Unit Area (sqft)'),
          ]),
          _itemToggle('Basin Cabinet', _incBasinCabinet, (v) => setState(() => _incBasinCabinet = v), [
            _drop('Package', _basinCabinetTier, rates.basinCabinetWithRates.keys.toList(), (v) => setState(() => _basinCabinetTier = v!)),
            _drop('Material Provision', _basinCabinetMat, const ['With Material', 'Without Material'], (v) => setState(() => _basinCabinetMat = v!)),
            _field(_basinCabinetArea, 'Basin Cabinet Area (sqft)'),
          ]),
          _itemToggle('MS Railing', _incMsRailing, (v) => setState(() => _incMsRailing = v), [
            _drop('Package', _msRailingTier, rates.msRailingWithRates.keys.toList(), (v) => setState(() => _msRailingTier = v!)),
            _drop('Material Provision', _msRailingMat, const ['With Material', 'Without Material'], (v) => setState(() => _msRailingMat = v!)),
            _field(_msRailingLength, 'Running Length (RFT)'),
          ]),
        ]),

        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Calculate Total Cost', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),

        if (_totalStr != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Total Interior Estimate', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(_totalStr!, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('${_breakdown.length} item(s) included', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFF98A2B3), width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cost Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    ..._breakdown.map((e) => Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(6)),
                      child: Row(children: [
                        Expanded(child: Text(e.key, style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600))),
                        Text(e.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
                      ]),
                    )),
                    const SizedBox(height: 6),
                    Text('* Estimates only. Actual costs may vary.', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _sharePdf,
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Generate & Share Quotation (PDF)', style: TextStyle(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _color,
                  side: const BorderSide(color: _color),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
