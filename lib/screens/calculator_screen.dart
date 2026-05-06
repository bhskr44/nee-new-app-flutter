import 'dart:math';
import 'package:flutter/material.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  static const _calcs = [
    _CalcType('Concrete Mix', Icons.water_drop, Color(0xFF795548), 'RCC, Slabs, Columns', 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=300&h=300&fit=crop&auto=format'),
    _CalcType('TMT Steel', Icons.straighten, Color(0xFF37474F), 'Bars, Weight & Cost', 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300&h=300&fit=crop&auto=format'),
    _CalcType('Tiles', Icons.crop_square, Color(0xFF1565C0), 'Floor & Wall Area', 'https://images.unsplash.com/photo-1600585152220-90363fe7e115?w=300&h=300&fit=crop&auto=format'),
    _CalcType('Paint', Icons.format_paint, Color(0xFF6A1B9A), 'Interior & Exterior', 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=300&h=300&fit=crop&auto=format'),
    _CalcType('Plastering', Icons.layers, Color(0xFF00695C), 'Wall & Ceiling', 'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?w=300&h=300&fit=crop&auto=format'),
    _CalcType('False Ceiling', Icons.grid_on, Color(0xFF283593), 'Grid & Panels', 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=300&h=300&fit=crop&auto=format'),
    _CalcType('Brickwork', Icons.grid_4x4, Color(0xFFBF360C), 'Bricks & Mortar', 'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?w=300&h=300&fit=crop&auto=format'),
    _CalcType('Plumbing', Icons.water, Color(0xFF0277BD), 'Cost Estimate', 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300&h=300&fit=crop&auto=format'),
    _CalcType('Electrical', Icons.electrical_services, Color(0xFFF57F17), 'Points & Wiring', 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=300&h=300&fit=crop&auto=format'),
    _CalcType('Roofsheet', Icons.roofing, Color(0xFF2E7D32), 'Area & Quantity', 'https://images.unsplash.com/photo-1486325212027-8081e485255e?w=300&h=300&fit=crop&auto=format'),
    _CalcType('Doors & Windows', Icons.door_front_door, Color(0xFF4E342E), 'Frame & Area', 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=300&h=300&fit=crop&auto=format'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Construction Calculator')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.calculate, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Smart Calculators', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    Text('Instant estimates for all construction needs', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            const Text('Select Calculator', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.9,
                ),
                itemCount: _calcs.length,
                itemBuilder: (_, i) => _CalcCard(type: _calcs[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalcType {
  final String name, subtitle, imageUrl;
  final IconData icon;
  final Color color;
  const _CalcType(this.name, this.icon, this.color, this.subtitle, this.imageUrl);
}

class _CalcCard extends StatelessWidget {
  final _CalcType type;
  const _CalcCard({required this.type});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: type.color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                type.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    ColoredBox(color: type.color.withValues(alpha: 0.15)),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      type.color.withValues(alpha: 0.5),
                      type.color.withValues(alpha: 0.92),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(type.icon, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      type.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type.subtitle,
                      style: const TextStyle(fontSize: 8, color: Colors.white70),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CalculatorSheet(type: type),
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
    _c1.dispose(); _c2.dispose(); _c3.dispose(); _c4.dispose();
    super.dispose();
  }

  void _calculate() {
    final name = widget.type.name;
    try {
      if (name == 'Concrete Mix') _calcConcrete();
      else if (name == 'TMT Steel') _calcSteel();
      else if (name == 'Tiles') _calcTiles();
      else if (name == 'Paint') _calcPaint();
      else if (name == 'Plastering') _calcPlastering();
      else if (name == 'False Ceiling') _calcFalseCeiling();
      else if (name == 'Brickwork') _calcBrickwork();
      else if (name == 'Plumbing') _calcPlumbing();
      else if (name == 'Electrical') _calcElectrical();
      else if (name == 'Roofsheet') _calcRoofsheet();
      else if (name == 'Doors & Windows') _calcDoors();
    } catch (e) {
      setState(() => _results = {'Error': 'Please enter valid numbers'});
    }
  }

  void _calcConcrete() {
    final l = double.parse(_c1.text), w = double.parse(_c2.text), d = double.parse(_c3.text);
    final wetVol = l * w * d;
    final dryVol = wetVol * 1.54;
    final ratios = {'M15': [1, 2, 4], 'M20': [1, 1.5, 3], 'M25': [1, 1, 2], 'M30': [1, 0.75, 1.5]};
    final r = ratios[_mix]!;
    final sum = r[0] + r[1] + r[2];
    final cement = (r[0] / sum) * dryVol / 0.0347;
    final sand = (r[1] / sum) * dryVol;
    final agg = (r[2] / sum) * dryVol;
    setState(() => _results = {
      'Wet Volume': '${wetVol.toStringAsFixed(3)} m³',
      'Cement Bags (50kg)': '${cement.ceil()} bags',
      'Sand Required': '${sand.toStringAsFixed(3)} m³',
      'Aggregate Required': '${agg.toStringAsFixed(3)} m³',
      'Est. Material Cost': '₹${(cement.ceil() * 380 + sand * 1200 + agg * 950).toStringAsFixed(0)}',
    });
  }

  void _calcSteel() {
    final len = double.parse(_c1.text), dia = double.parse(_c2.text), qty = double.parse(_c3.text);
    final weight = (dia * dia / 162) * len * qty;
    final cost = weight * 65;
    setState(() => _results = {
      'Total Weight': '${weight.toStringAsFixed(2)} kg',
      'Weight in MT': '${(weight / 1000).toStringAsFixed(3)} MT',
      'Estimated Cost': '₹${cost.toStringAsFixed(0)} (@ ₹65/kg)',
    });
  }

  void _calcTiles() {
    final l = double.parse(_c1.text), w = double.parse(_c2.text);
    final tl = double.parse(_c3.text), tw = double.parse(_c4.text);
    final wastage = 0.10;
    final roomArea = l * w;
    final tileArea = (tl / 12) * (tw / 12);
    final tiles = (roomArea / tileArea * (1 + wastage)).ceil();
    setState(() => _results = {
      'Room Area': '${roomArea.toStringAsFixed(2)} sqft',
      'Tile Area': '${(tileArea * 144).toStringAsFixed(0)} sq.in',
      'Tiles Required (incl. 10% waste)': '$tiles tiles',
      'Est. Cost (@ ₹55/sqft)': '₹${(roomArea * 55 * 1.1).toStringAsFixed(0)}',
    });
  }

  void _calcPaint() {
    final l = double.parse(_c1.text), w = double.parse(_c2.text), h = double.parse(_c3.text);
    final coats = _c4.text.isEmpty ? 2 : int.parse(_c4.text);
    final wallArea = 2 * (l + w) * h;
    final ceilArea = l * w;
    final totalArea = wallArea + ceilArea;
    final coverage = 10.0;
    final paintLitres = (totalArea / 10.764) / coverage * coats;
    setState(() => _results = {
      'Wall Area': '${wallArea.toStringAsFixed(1)} sqft',
      'Ceiling Area': '${ceilArea.toStringAsFixed(1)} sqft',
      'Total Area': '${totalArea.toStringAsFixed(1)} sqft',
      'Paint Required': '${paintLitres.toStringAsFixed(1)} litres',
      'Est. Cost (@ ₹300/L)': '₹${(paintLitres * 300).toStringAsFixed(0)}',
    });
  }

  void _calcPlastering() {
    final l = double.parse(_c1.text), w = double.parse(_c2.text);
    final thick = _c3.text.isEmpty ? 12.0 : double.parse(_c3.text);
    final area = l * w;
    final vol = area * (thick / 1000) * 1.35;
    final cement = vol / (1 + 6) / 0.0347;
    final sand = vol * 6 / 7;
    setState(() => _results = {
      'Plaster Area': '${area.toStringAsFixed(2)} m²',
      'Cement Bags': '${cement.ceil()} bags',
      'Sand Required': '${sand.toStringAsFixed(3)} m³',
      'Est. Cost': '₹${(cement.ceil() * 380 + sand * 1200 + area * 15).toStringAsFixed(0)}',
    });
  }

  void _calcFalseCeiling() {
    final l = double.parse(_c1.text), w = double.parse(_c2.text);
    final area = l * w;
    final panels = (area / (2 * 2)).ceil();
    final mainT = (w / 4).ceil() * ((l / 4).ceil() + 1);
    final crossT = (l / 2).ceil() * ((w / 2).ceil() + 1);
    final wallAngle = (2 * (l + w) / 10).ceil();
    setState(() => _results = {
      'Room Area': '${area.toStringAsFixed(1)} sqft',
      '2×2 Panels': '$panels nos.',
      'Main T-Runners': '$mainT nos.',
      'Cross T-Runners': '$crossT nos.',
      'Wall Angle (10ft)': '$wallAngle nos.',
      'Est. Cost (@ ₹95/sqft)': '₹${(area * 95).toStringAsFixed(0)}',
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

  void _calcPlumbing() {
    final baths = int.parse(_c1.text);
    final kitchen = _c2.text.toLowerCase() == '1' || _c2.text.toLowerCase() == 'yes' ? 1 : 0;
    final area = _c3.text.isEmpty ? 0.0 : double.parse(_c3.text);
    final cost = baths * 28000 + kitchen * 18000 + area * 12;
    setState(() => _results = {
      'Bathrooms': '$baths nos.',
      'Kitchen': kitchen == 1 ? 'Yes' : 'No',
      'Rough Estimate': '₹${cost.toStringAsFixed(0)}',
      'Per Sqft (approx)': '₹${area > 0 ? (cost / area).toStringAsFixed(0) : "N/A"}/sqft',
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
    final cost = area * 55 + acs * 3500;
    setState(() => _results = {
      'Light Points': '$lightPts nos.',
      'Fan Points': '$fanPts nos.',
      'Power Points': '$powerPts nos.',
      'Wire Length (est.)': '${wireLen.toStringAsFixed(0)} metres',
      'Rough Estimate': '₹${cost.toStringAsFixed(0)}',
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
      'Sheets (0.9m×3m)': '$sheets sheets',
      'Fasteners (est.)': '${(sheets * 8)} nos.',
      'Est. Cost (@ ₹450/sheet)': '₹${(sheets * 450).toStringAsFixed(0)}',
    });
  }

  void _calcDoors() {
    final doors = int.parse(_c1.text);
    final windows = int.parse(_c2.text);
    final doorCost = doors * 8500;
    final winCost = windows * 5500;
    final frameLen = doors * (2 * 2.1 + 0.9) + windows * (2 * 1.2 + 1.2);
    setState(() => _results = {
      'Doors': '$doors nos.',
      'Windows': '$windows nos.',
      'Total Frame Length': '${frameLen.toStringAsFixed(1)} m',
      'Door Cost (std.)': '₹$doorCost',
      'Window Cost (std.)': '₹$winCost',
      'Total Estimate': '₹${doorCost + winCost}',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: widget.type.color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                child: Icon(widget.type.icon, color: widget.type.color, size: 22),
              ),
              const SizedBox(width: 10),
              Text('${widget.type.name} Calculator', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            ..._buildInputs(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate),
                label: const Text('Calculate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.type.color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.type.color.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.type.color.withAlpha(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.check_circle, color: widget.type.color, size: 16),
                      const SizedBox(width: 6),
                      Text('Results', style: TextStyle(fontWeight: FontWeight.bold, color: widget.type.color)),
                    ]),
                    const SizedBox(height: 10),
                    ..._results.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        Expanded(child: Text(e.key, style: TextStyle(color: Colors.grey[700], fontSize: 13))),
                        Text(e.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ]),
                    )),
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
        const SizedBox(height: 8),
        InputDecorator(
          decoration: const InputDecoration(labelText: 'Mix Grade'),
          child: DropdownButton<String>(
            value: _mix,
            isExpanded: true,
            underline: const SizedBox(),
            items: ['M15', 'M20', 'M25', 'M30'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => _mix = v!),
          ),
        ),
      ];
    }
    if (name == 'TMT Steel') return [_field(_c1, 'Bar Length (m)'), _field(_c2, 'Diameter (mm)'), _field(_c3, 'Number of Bars')];
    if (name == 'Tiles') return [_field(_c1, 'Room Length (ft)'), _field(_c2, 'Room Width (ft)'), _field(_c3, 'Tile Length (inches)'), _field(_c4, 'Tile Width (inches)')];
    if (name == 'Paint') return [_field(_c1, 'Room Length (ft)'), _field(_c2, 'Room Width (ft)'), _field(_c3, 'Room Height (ft)'), _field(_c4, 'Number of Coats (default: 2)')];
    if (name == 'Plastering') return [_field(_c1, 'Length (m)'), _field(_c2, 'Width (m)'), _field(_c3, 'Thickness in mm (default: 12mm)')];
    if (name == 'False Ceiling') return [_field(_c1, 'Room Length (ft)'), _field(_c2, 'Room Width (ft)')];
    if (name == 'Brickwork') return [_field(_c1, 'Wall Length (m)'), _field(_c2, 'Wall Height (m)'), _field(_c3, 'Wall Thickness (m, e.g. 0.23)')];
    if (name == 'Plumbing') return [_field(_c1, 'Number of Bathrooms'), _field(_c2, 'Kitchen? (1=Yes, 0=No)'), _field(_c3, 'Floor Area (sqft)')];
    if (name == 'Electrical') return [_field(_c1, 'Floor Area (sqft)'), _field(_c2, 'Number of Rooms'), _field(_c3, 'Number of ACs')];
    if (name == 'Roofsheet') return [_field(_c1, 'Roof Length (m)'), _field(_c2, 'Roof Width (m)'), _field(_c3, 'Pitch Angle (°, default: 15)')];
    if (name == 'Doors & Windows') return [_field(_c1, 'Number of Doors'), _field(_c2, 'Number of Windows')];
    return [];
  }

  Widget _field(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
