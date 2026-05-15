import 'dart:math';
import 'package:flutter/material.dart';

enum _Category { all, structural, finishing, mep, woodwork }

class _CalcType {
  final String name, subtitle;
  final IconData icon;
  final Color color;
  final _Category category;
  const _CalcType(this.name, this.icon, this.color, this.subtitle, this.category);
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  _Category _selected = _Category.all;

  static const _calcs = [
    // Structural
    _CalcType('Concrete Mix', Icons.water_drop, Color(0xFF5D4037), 'RCC, Slabs & Columns', _Category.structural),
    _CalcType('TMT Steel', Icons.straighten, Color(0xFF37474F), 'Bar Weight & Cost', _Category.structural),
    _CalcType('Brickwork', Icons.grid_4x4, Color(0xFFBF360C), 'Bricks & Mortar', _Category.structural),
    _CalcType('Foundation', Icons.foundation, Color(0xFF4E342E), 'Footing & Raft', _Category.structural),
    _CalcType('Roofsheet', Icons.roofing, Color(0xFF2E7D32), 'Area & Quantity', _Category.structural),
    // Finishing
    _CalcType('Tiles', Icons.crop_square, Color(0xFF1565C0), 'Floor & Wall Area', _Category.finishing),
    _CalcType('Paint', Icons.format_paint, Color(0xFF6A1B9A), 'Interior & Exterior', _Category.finishing),
    _CalcType('Plastering', Icons.layers, Color(0xFF00695C), 'Wall & Ceiling', _Category.finishing),
    _CalcType('False Ceiling', Icons.grid_on, Color(0xFF283593), 'Grid & Panels', _Category.finishing),
    _CalcType('Wall Cladding', Icons.wallpaper, Color(0xFF558B2F), 'Stone & Wallpaper', _Category.finishing),
    _CalcType('Waterproofing', Icons.water_damage, Color(0xFF0277BD), 'Terrace & Bathroom', _Category.finishing),
    // MEP
    _CalcType('Plumbing', Icons.water, Color(0xFF006064), 'Cost Estimate', _Category.mep),
    _CalcType('Electrical', Icons.electrical_services, Color(0xFFF57F17), 'Points & Wiring', _Category.mep),
    // Woodwork
    _CalcType('Doors & Windows', Icons.door_front_door, Color(0xFF795548), 'Frame & Area', _Category.woodwork),
    _CalcType('Modular Kitchen', Icons.kitchen, Color(0xFF880E4F), 'Cabinet & Counter', _Category.woodwork),
    _CalcType('Wardrobe', Icons.checkroom, Color(0xFF4527A0), 'Panels & Shutters', _Category.woodwork),
  ];

  List<_CalcType> get _filtered => _selected == _Category.all
      ? _calcs
      : _calcs.where((c) => c.category == _selected).toList();

  String _label(_Category cat) {
    if (cat == _Category.structural) return 'Structural';
    if (cat == _Category.finishing) return 'Finishing';
    if (cat == _Category.mep) return 'MEP';
    if (cat == _Category.woodwork) return 'Woodwork';
    return 'All';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Construction Calculator'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF388E3C)]),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.construction, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Smart Calculators', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('16 tools • Instant material & cost estimates', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _Category.values.map((cat) {
                  final active = _selected == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFF1B5E20) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active ? const Color(0xFF1B5E20) : const Color(0xFFDDDDDD),
                          ),
                          boxShadow: active
                              ? [BoxShadow(color: const Color(0xFF1B5E20).withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))]
                              : [],
                        ),
                        child: Text(
                          _label(cat),
                          style: TextStyle(
                            color: active ? Colors.white : Colors.grey[600],
                            fontSize: 12,
                            fontWeight: active ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.88,
              ),
              itemCount: _filtered.length,
              itemBuilder: (_, i) => _CalcCard(type: _filtered[i]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Calculator Card ──────────────────────────────────────────────────────────

class _CalcCard extends StatelessWidget {
  final _CalcType type;
  const _CalcCard({required this.type});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _CalculatorSheet(type: type),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(type.icon, color: type.color, size: 26),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                type.name,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                type.subtitle,
                style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Calculator Sheet ─────────────────────────────────────────────────────────

class _CalculatorSheet extends StatefulWidget {
  final _CalcType type;
  const _CalculatorSheet({required this.type});

  @override
  State<_CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<_CalculatorSheet> {
  final _c1 = TextEditingController();
  final _c2 = TextEditingController();
  final _c3 = TextEditingController();
  final _c4 = TextEditingController();
  Map<String, String> _results = {};
  String _mix = 'M20';

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    _c3.dispose();
    _c4.dispose();
    super.dispose();
  }

  void _calculate() {
    final name = widget.type.name;
    try {
      if (name == 'Concrete Mix') { _calcConcrete(); }
      else if (name == 'TMT Steel') { _calcSteel(); }
      else if (name == 'Tiles') { _calcTiles(); }
      else if (name == 'Paint') { _calcPaint(); }
      else if (name == 'Plastering') { _calcPlastering(); }
      else if (name == 'False Ceiling') { _calcFalseCeiling(); }
      else if (name == 'Brickwork') { _calcBrickwork(); }
      else if (name == 'Plumbing') { _calcPlumbing(); }
      else if (name == 'Electrical') { _calcElectrical(); }
      else if (name == 'Roofsheet') { _calcRoofsheet(); }
      else if (name == 'Doors & Windows') { _calcDoors(); }
      else if (name == 'Foundation') { _calcFoundation(); }
      else if (name == 'Wall Cladding') { _calcWallCladding(); }
      else if (name == 'Waterproofing') { _calcWaterproofing(); }
      else if (name == 'Modular Kitchen') { _calcKitchen(); }
      else if (name == 'Wardrobe') { _calcWardrobe(); }
    } catch (_) {
      setState(() => _results = {'Error': 'Please enter valid numbers'});
    }
  }

  // ─── Structural ───────────────────────────────────────────────────────────

  void _calcConcrete() {
    final l = double.parse(_c1.text), w = double.parse(_c2.text), d = double.parse(_c3.text);
    final wetVol = l * w * d;
    final dryVol = wetVol * 1.54;
    const ratios = {
      'M15': [1.0, 2.0, 4.0],
      'M20': [1.0, 1.5, 3.0],
      'M25': [1.0, 1.0, 2.0],
      'M30': [1.0, 0.75, 1.5],
    };
    final r = ratios[_mix]!;
    final sum = r[0] + r[1] + r[2];
    final cement = (r[0] / sum) * dryVol / 0.0347;
    final sand = (r[1] / sum) * dryVol;
    final agg = (r[2] / sum) * dryVol;
    setState(() => _results = {
      'Wet Volume': '${wetVol.toStringAsFixed(3)} m³',
      'Cement Bags (50 kg)': '${cement.ceil()} bags',
      'Sand Required': '${sand.toStringAsFixed(3)} m³',
      'Aggregate Required': '${agg.toStringAsFixed(3)} m³',
      'Est. Material Cost': '₹${(cement.ceil() * 380 + sand * 1200 + agg * 950).toStringAsFixed(0)}',
    });
  }

  void _calcSteel() {
    final len = double.parse(_c1.text), dia = double.parse(_c2.text), qty = double.parse(_c3.text);
    final weight = (dia * dia / 162) * len * qty;
    setState(() => _results = {
      'Total Weight': '${weight.toStringAsFixed(2)} kg',
      'Weight in MT': '${(weight / 1000).toStringAsFixed(3)} MT',
      'Estimated Cost (@ ₹65/kg)': '₹${(weight * 65).toStringAsFixed(0)}',
    });
  }

  void _calcBrickwork() {
    final l = double.parse(_c1.text), h = double.parse(_c2.text), t = double.parse(_c3.text);
    final vol = l * h * t;
    final bricks = (vol / (0.19 * 0.09 * 0.09) * 0.7).ceil();
    final mortar = vol * 0.3 * 1.3;
    final cement = mortar / 7 / 0.0347;
    final sand = mortar * 6 / 7;
    setState(() => _results = {
      'Wall Volume': '${vol.toStringAsFixed(3)} m³',
      'Bricks Required': '$bricks nos.',
      'Cement Bags': '${cement.ceil()} bags',
      'Sand Required': '${sand.toStringAsFixed(3)} m³',
      'Est. Cost': '₹${(bricks * 7 + cement.ceil() * 380 + sand * 1200).toStringAsFixed(0)}',
    });
  }

  void _calcFoundation() {
    final l = double.parse(_c1.text), w = double.parse(_c2.text), d = double.parse(_c3.text);
    final footings = _c4.text.isEmpty ? 1 : (double.tryParse(_c4.text) ?? 1).round();
    final volEach = l * w * d;
    final totalVol = volEach * footings;
    final dryVol = totalVol * 1.54;
    // M20 mix (1:1.5:3), sum = 5.5
    const sum = 5.5;
    final cement = (1.0 / sum) * dryVol / 0.0347;
    final sand = (1.5 / sum) * dryVol;
    final agg = (3.0 / sum) * dryVol;
    final steel = totalVol * 0.01 * 7850; // ~1% steel ratio by volume
    setState(() => _results = {
      'Volume per Footing': '${volEach.toStringAsFixed(3)} m³',
      'Total Concrete Volume': '${totalVol.toStringAsFixed(3)} m³',
      'Cement Bags (M20)': '${cement.ceil()} bags',
      'Sand': '${sand.toStringAsFixed(3)} m³',
      'Aggregate': '${agg.toStringAsFixed(3)} m³',
      'Steel (est.)': '${steel.toStringAsFixed(0)} kg',
      'Est. Material Cost': '₹${(cement.ceil() * 380 + sand * 1200 + agg * 950 + steel * 65).toStringAsFixed(0)}',
    });
  }

  void _calcRoofsheet() {
    final l = double.parse(_c1.text), w = double.parse(_c2.text);
    final pitch = _c3.text.isEmpty ? 15.0 : double.parse(_c3.text);
    final slopeFactor = 1 / cos(pitch * pi / 180);
    final roofArea = l * w * slopeFactor;
    final sheets = (roofArea / (0.9 * 3.0)).ceil();
    setState(() => _results = {
      'Plan Area': '${(l * w).toStringAsFixed(1)} m²',
      'Sloped Roof Area': '${roofArea.toStringAsFixed(1)} m²',
      'Sheets (0.9 m × 3 m)': '$sheets sheets',
      'Fasteners (est.)': '${sheets * 8} nos.',
      'Est. Cost (@ ₹450/sheet)': '₹${(sheets * 450).toStringAsFixed(0)}',
    });
  }

  // ─── Finishing ────────────────────────────────────────────────────────────

  void _calcTiles() {
    final l = double.parse(_c1.text), w = double.parse(_c2.text);
    final tl = double.parse(_c3.text), tw = double.parse(_c4.text);
    final roomArea = l * w;
    final tileArea = (tl / 12) * (tw / 12);
    final tiles = (roomArea / tileArea * 1.10).ceil();
    setState(() => _results = {
      'Room Area': '${roomArea.toStringAsFixed(2)} sqft',
      'Tiles Required (+10% waste)': '$tiles tiles',
      'Material Cost (@ ₹55/sqft)': '₹${(roomArea * 55 * 1.1).toStringAsFixed(0)}',
      'Installation Cost': '₹${(roomArea * 25).toStringAsFixed(0)}',
      'Total Cost': '₹${(roomArea * 55 * 1.1 + roomArea * 25).toStringAsFixed(0)}',
    });
  }

  void _calcPaint() {
    final l = double.parse(_c1.text), w = double.parse(_c2.text), h = double.parse(_c3.text);
    final coats = _c4.text.isEmpty ? 2 : int.parse(_c4.text);
    final wallArea = 2 * (l + w) * h;
    final ceilArea = l * w;
    final totalArea = wallArea + ceilArea;
    final areaSqm = totalArea / 10.764;
    final primerLitres = areaSqm / 12;
    final paintLitres = areaSqm / 10.0 * coats;
    setState(() => _results = {
      'Wall Area': '${wallArea.toStringAsFixed(1)} sqft',
      'Ceiling Area': '${ceilArea.toStringAsFixed(1)} sqft',
      'Total Paintable Area': '${totalArea.toStringAsFixed(1)} sqft',
      'Primer Required': '${primerLitres.toStringAsFixed(1)} L',
      'Paint Required': '${paintLitres.toStringAsFixed(1)} L',
      'Material Cost': '₹${(paintLitres * 300 + primerLitres * 150).toStringAsFixed(0)}',
      'Total with Labour': '₹${(paintLitres * 300 + primerLitres * 150 + areaSqm * 20).toStringAsFixed(0)}',
    });
  }

  void _calcPlastering() {
    final l = double.parse(_c1.text), w = double.parse(_c2.text);
    final thick = _c3.text.isEmpty ? 12.0 : double.parse(_c3.text);
    final area = l * w;
    final vol = area * (thick / 1000) * 1.35;
    final cement = vol / 7 / 0.0347;
    final sand = vol * 6 / 7;
    setState(() => _results = {
      'Plaster Area': '${area.toStringAsFixed(2)} m²',
      'Cement Bags': '${cement.ceil()} bags',
      'Sand Required': '${sand.toStringAsFixed(3)} m³',
      'Labour Cost': '₹${(area * 55).toStringAsFixed(0)}',
      'Est. Total Cost': '₹${(cement.ceil() * 380 + sand * 1200 + area * 55).toStringAsFixed(0)}',
    });
  }

  void _calcFalseCeiling() {
    final l = double.parse(_c1.text), w = double.parse(_c2.text);
    final area = l * w;
    final panels = (area / 4).ceil();
    final mainT = (w / 4).ceil() * ((l / 4).ceil() + 1);
    final crossT = (l / 2).ceil() * ((w / 2).ceil() + 1);
    final wallAngle = (2 * (l + w) / 10).ceil();
    setState(() => _results = {
      'Room Area': '${area.toStringAsFixed(1)} sqft',
      '2×2 Panels': '$panels nos.',
      'Main T-Runners': '$mainT nos.',
      'Cross T-Runners': '$crossT nos.',
      'Wall Angle (10 ft each)': '$wallAngle nos.',
      'Est. Cost (@ ₹95/sqft)': '₹${(area * 95).toStringAsFixed(0)}',
    });
  }

  void _calcWallCladding() {
    final l = double.parse(_c1.text), h = double.parse(_c2.text);
    final wastage = _c3.text.isEmpty ? 10.0 : double.parse(_c3.text);
    final area = l * h;
    final withWaste = area * (1 + wastage / 100);
    final panels = (withWaste / 8).ceil(); // 2×4 ft panel = 8 sqft
    final adhesive = (area / 40).ceil();   // 1 bag covers 40 sqft
    setState(() => _results = {
      'Cladding Area': '${area.toStringAsFixed(2)} sqft',
      'Area with Wastage': '${withWaste.toStringAsFixed(2)} sqft',
      'Panels (2×4 ft)': '$panels nos.',
      'Adhesive Bags': '$adhesive bags',
      'Material Cost': '₹${(area * 120).toStringAsFixed(0)}',
      'Labour Cost': '₹${(area * 40).toStringAsFixed(0)}',
      'Total Cost': '₹${(area * 160).toStringAsFixed(0)}',
    });
  }

  void _calcWaterproofing() {
    final area = double.parse(_c1.text);
    final coats = _c2.text.isEmpty ? 2 : int.parse(_c2.text);
    final membrane = (area * coats / 40).ceil() * 4; // 4 L covers 40 sqft/coat
    final primer = (area / 60).ceil() * 4;
    setState(() => _results = {
      'Waterproofing Area': '${area.toStringAsFixed(1)} sqft',
      'Coats Applied': '$coats',
      'Membrane Required': '$membrane litres',
      'Primer Required': '$primer litres',
      'Labour Cost': '₹${(area * 25).toStringAsFixed(0)}',
      'Est. Total Cost': '₹${(area * 85).toStringAsFixed(0)}',
    });
  }

  // ─── MEP ─────────────────────────────────────────────────────────────────

  void _calcPlumbing() {
    final baths = int.parse(_c1.text);
    final kitchen = _c2.text.isEmpty || _c2.text.trim() == '0' ? 0 : 1;
    final area = _c3.text.isEmpty ? 0.0 : double.parse(_c3.text);
    final cost = baths * 28000 + kitchen * 18000 + area * 12;
    setState(() => _results = {
      'Bathrooms': '$baths nos.',
      'Kitchen': kitchen == 1 ? 'Yes' : 'No',
      'Rough Estimate': '₹${cost.toStringAsFixed(0)}',
      'Per Sqft': '₹${area > 0 ? (cost / area).toStringAsFixed(0) : "N/A"}/sqft',
    });
  }

  void _calcElectrical() {
    final area = double.parse(_c1.text);
    final rooms = int.parse(_c2.text);
    final acs = _c3.text.isEmpty ? 0 : int.parse(_c3.text);
    final lightPts = rooms * 3 + 4;
    final fanPts = rooms + 2;
    final powerPts = rooms * 3 + 6 + acs * 2;
    final wireLen = area * 3.5;
    setState(() => _results = {
      'Light Points': '$lightPts nos.',
      'Fan Points': '$fanPts nos.',
      'Power Points': '$powerPts nos.',
      'Wire Length (est.)': '${wireLen.toStringAsFixed(0)} metres',
      'Rough Estimate': '₹${(area * 55 + acs * 3500).toStringAsFixed(0)}',
    });
  }

  // ─── Woodwork ─────────────────────────────────────────────────────────────

  void _calcDoors() {
    final doors = int.parse(_c1.text);
    final windows = int.parse(_c2.text);
    final frameLen = doors * (2 * 2.1 + 0.9) + windows * (2 * 1.2 + 1.2);
    final doorCost = doors * 8500;
    final winCost = windows * 5500;
    setState(() => _results = {
      'Doors': '$doors nos.',
      'Windows': '$windows nos.',
      'Total Frame Length': '${frameLen.toStringAsFixed(1)} m',
      'Door Cost (std.)': '₹$doorCost',
      'Window Cost (std.)': '₹$winCost',
      'Total Estimate': '₹${doorCost + winCost}',
    });
  }

  void _calcKitchen() {
    final len = double.parse(_c1.text);
    final type = int.tryParse(_c2.text) ?? 1;
    final multiplier = type == 3 ? 2.5 : type == 2 ? 1.7 : 1.0;
    final totalLen = len * multiplier;
    final baseModules = (totalLen / 2).ceil();
    final wallModules = (totalLen * 0.7 / 2).ceil();
    final cost = baseModules * 12000 + wallModules * 7000 + totalLen * 1500;
    final typeName = type == 3 ? 'U-Shape' : type == 2 ? 'L-Shape' : 'Straight';
    setState(() => _results = {
      'Kitchen Type': typeName,
      'Counter Length': '${totalLen.toStringAsFixed(1)} ft',
      'Base Cabinets': '$baseModules modules',
      'Wall Cabinets': '$wallModules modules',
      'Countertop': '${totalLen.toStringAsFixed(1)} running ft',
      'Est. Cost (mid-range)': '₹${cost.toStringAsFixed(0)}',
    });
  }

  void _calcWardrobe() {
    final width = double.parse(_c1.text);
    final height = double.parse(_c2.text);
    final depth = _c3.text.isEmpty ? 2.0 : double.parse(_c3.text);
    final doors = _c4.text.isEmpty ? 2 : (double.tryParse(_c4.text) ?? 2).round();
    final shutterArea = width * height;
    final panelArea = 2 * (width * height + width * depth + height * depth);
    final cost = panelArea * 1200 + shutterArea * 1800 + doors * 1200;
    setState(() => _results = {
      'Size (W×H×D)': '$width×$height×$depth ft',
      'Panel Area': '${panelArea.toStringAsFixed(1)} sqft',
      'Shutter Area': '${shutterArea.toStringAsFixed(1)} sqft',
      'Doors / Shutters': '$doors nos.',
      'Hardware & Fittings': '₹${(doors * 1200).toStringAsFixed(0)}',
      'Est. Total Cost': '₹${cost.toStringAsFixed(0)}',
    });
  }

  // ─── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.type.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.type.icon, color: widget.type.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    '${widget.type.name} Calculator',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  Text(widget.type.subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            ..._buildInputs(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate_outlined, size: 20),
                label: const Text('Calculate', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.type.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.type.color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: widget.type.color.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.check_circle_outline, color: widget.type.color, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Calculation Results',
                        style: TextStyle(fontWeight: FontWeight.bold, color: widget.type.color, fontSize: 14),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    ..._results.entries.map((e) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Expanded(child: Text(e.key, style: TextStyle(color: Colors.grey[600], fontSize: 13))),
                        Text(e.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ]),
                    )),
                    const SizedBox(height: 4),
                    Text(
                      '* Estimates only. Actual quantities may vary.',
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildInputs() {
    final name = widget.type.name;
    if (name == 'Concrete Mix') {
      return [
        _field(_c1, 'Length (m)'),
        _field(_c2, 'Width (m)'),
        _field(_c3, 'Depth / Thickness (m)'),
        _dropdown('Mix Grade', _mix, ['M15', 'M20', 'M25', 'M30'], (v) => setState(() => _mix = v!)),
      ];
    }
    if (name == 'TMT Steel') {
      return [_field(_c1, 'Bar Length (m)'), _field(_c2, 'Diameter (mm)'), _field(_c3, 'Number of Bars')];
    }
    if (name == 'Brickwork') {
      return [_field(_c1, 'Wall Length (m)'), _field(_c2, 'Wall Height (m)'), _field(_c3, 'Wall Thickness (m, e.g. 0.23)')];
    }
    if (name == 'Foundation') {
      return [
        _field(_c1, 'Footing Length (m)'),
        _field(_c2, 'Footing Width (m)'),
        _field(_c3, 'Footing Depth (m)'),
        _field(_c4, 'Number of Footings (default: 1)'),
      ];
    }
    if (name == 'Roofsheet') {
      return [_field(_c1, 'Roof Length (m)'), _field(_c2, 'Roof Width (m)'), _field(_c3, 'Pitch Angle (°, default: 15)')];
    }
    if (name == 'Tiles') {
      return [
        _field(_c1, 'Room Length (ft)'),
        _field(_c2, 'Room Width (ft)'),
        _field(_c3, 'Tile Length (inches)'),
        _field(_c4, 'Tile Width (inches)'),
      ];
    }
    if (name == 'Paint') {
      return [
        _field(_c1, 'Room Length (ft)'),
        _field(_c2, 'Room Width (ft)'),
        _field(_c3, 'Room Height (ft)'),
        _field(_c4, 'Number of Coats (default: 2)'),
      ];
    }
    if (name == 'Plastering') {
      return [_field(_c1, 'Length (m)'), _field(_c2, 'Width (m)'), _field(_c3, 'Thickness in mm (default: 12)')];
    }
    if (name == 'False Ceiling') {
      return [_field(_c1, 'Room Length (ft)'), _field(_c2, 'Room Width (ft)')];
    }
    if (name == 'Wall Cladding') {
      return [_field(_c1, 'Wall Length (ft)'), _field(_c2, 'Wall Height (ft)'), _field(_c3, 'Wastage % (default: 10)')];
    }
    if (name == 'Waterproofing') {
      return [_field(_c1, 'Area to Waterproof (sqft)'), _field(_c2, 'Number of Coats (default: 2)')];
    }
    if (name == 'Plumbing') {
      return [
        _field(_c1, 'Number of Bathrooms'),
        _field(_c2, 'Kitchen? (1 = Yes, 0 = No)'),
        _field(_c3, 'Floor Area (sqft)'),
      ];
    }
    if (name == 'Electrical') {
      return [_field(_c1, 'Floor Area (sqft)'), _field(_c2, 'Number of Rooms'), _field(_c3, 'Number of ACs (0 if none)')];
    }
    if (name == 'Doors & Windows') {
      return [_field(_c1, 'Number of Doors'), _field(_c2, 'Number of Windows')];
    }
    if (name == 'Modular Kitchen') {
      return [
        _field(_c1, 'Kitchen Length (ft)'),
        _hintField(_c2, 'Kitchen Type (1 / 2 / 3)', '1 = Straight   2 = L-Shape   3 = U-Shape'),
      ];
    }
    if (name == 'Wardrobe') {
      return [
        _field(_c1, 'Width (ft)'),
        _field(_c2, 'Height (ft)'),
        _field(_c3, 'Depth (ft, default: 2)'),
        _field(_c4, 'Number of Doors (default: 2)'),
      ];
    }
    return [];
  }

  Widget _field(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          isDense: true,
        ),
      ),
    );
  }

  Widget _hintField(TextEditingController c, String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            isDense: true,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(hint, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ),
      ]),
    );
  }

  Widget _dropdown(String label, String initialValue, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          isDense: true,
        ),
        items: items.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
