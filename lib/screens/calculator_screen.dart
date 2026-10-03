import '../widgets/app_search_field.dart';
import '../widgets/app_drawer.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/interior_rate_card.dart' as rates;
import '../services/estimate_pdf_service.dart';

enum _Category { all, structural, finishing, mep, woodwork, upvc }

class _CalcType {
  final String name, subtitle;
  final IconData icon;
  final Color color;
  final _Category category;
  const _CalcType(
    this.name,
    this.icon,
    this.color,
    this.subtitle,
    this.category,
  );
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  _Category _selected = _Category.all;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static const _calcs = [
    // Structural
    _CalcType(
      'Concrete Mix',
      Icons.water_drop,
      Color(0xFF5D4037),
      'RCC, Slabs & Columns',
      _Category.structural,
    ),
    _CalcType(
      'TMT Steel',
      Icons.straighten,
      Color(0xFF37474F),
      'Bar Weight & Cost',
      _Category.structural,
    ),
    _CalcType(
      'Brickwork',
      Icons.grid_4x4,
      Color(0xFFBF360C),
      'Bricks & Mortar',
      _Category.structural,
    ),
    _CalcType(
      'Foundation',
      Icons.foundation,
      Color(0xFF4E342E),
      'Footing & Raft',
      _Category.structural,
    ),
    _CalcType(
      'Roofsheet',
      Icons.roofing,
      Color(0xFF2E7D32),
      'Area & Quantity',
      _Category.structural,
    ),
    // Finishing
    _CalcType(
      'Tiles',
      Icons.crop_square,
      Color(0xFF1565C0),
      'With / Without Material',
      _Category.finishing,
    ),
    _CalcType(
      'Painting',
      Icons.format_paint,
      Color(0xFF6A1B9A),
      'With / Without Material',
      _Category.finishing,
    ),
    _CalcType(
      'Plastering',
      Icons.layers,
      Color(0xFF00695C),
      'Wall & Ceiling',
      _Category.finishing,
    ),
    _CalcType(
      'False Ceiling',
      Icons.grid_on,
      Color(0xFF283593),
      'Gypsum & PVC',
      _Category.finishing,
    ),
    _CalcType(
      'Wall Panel',
      Icons.wallpaper,
      Color(0xFF558B2F),
      'PVC & Laminate',
      _Category.finishing,
    ),
    _CalcType(
      'Wallpaper',
      Icons.format_paint_outlined,
      Color(0xFF558B2F),
      'Modern & Premium',
      _Category.finishing,
    ),
    _CalcType(
      'Waterproofing',
      Icons.water_damage,
      Color(0xFF0277BD),
      'Terrace & Bathroom',
      _Category.finishing,
    ),
    _CalcType(
      'Partition',
      Icons.vertical_split,
      Color(0xFF6D4C41),
      'Glass & Wooden',
      _Category.finishing,
    ),
    // MEP
    _CalcType(
      'Plumbing',
      Icons.water,
      Color(0xFF006064),
      'Normal, Premium & Duplex',
      _Category.mep,
    ),
    _CalcType(
      'Electrical',
      Icons.electrical_services,
      Color(0xFFF57F17),
      'Points & Wiring',
      _Category.mep,
    ),
    _CalcType(
      'Home Automation',
      Icons.sensors,
      Color(0xFF00838F),
      'Smart Room Control',
      _Category.mep,
    ),
    // Woodwork
    _CalcType(
      'Doors & Windows',
      Icons.door_front_door,
      Color(0xFF795548),
      'Frame & Area',
      _Category.woodwork,
    ),
    _CalcType(
      'Modular Kitchen',
      Icons.kitchen,
      Color(0xFF880E4F),
      'Cabinet & Counter',
      _Category.woodwork,
    ),
    _CalcType(
      'Wardrobe',
      Icons.checkroom,
      Color(0xFF4527A0),
      'Openable & Sliding',
      _Category.woodwork,
    ),
    _CalcType(
      'Bed',
      Icons.bed,
      Color(0xFF4527A0),
      'Medium, Premium & Duplex',
      _Category.woodwork,
    ),
    _CalcType(
      'TV Unit',
      Icons.tv,
      Color(0xFF880E4F),
      'Medium, Premium & Duplex',
      _Category.woodwork,
    ),
    _CalcType(
      'Basin Cabinet',
      Icons.countertops,
      Color(0xFF880E4F),
      'Medium, Premium & Duplex',
      _Category.woodwork,
    ),
    _CalcType(
      'MS Railing',
      Icons.fence,
      Color(0xFF37474F),
      'Medium, Premium & Duplex',
      _Category.structural,
    ),
    // UPVC
    _CalcType(
      'UPVC Window',
      Icons.window,
      Color(0xFF00838F),
      '2-Track & 3-Track',
      _Category.upvc,
    ),
    _CalcType(
      'UPVC Door',
      Icons.door_sliding,
      Color(0xFF006064),
      'UPVC Door Frame',
      _Category.upvc,
    ),
  ];

  List<_CalcType> get _filtered =>
      _calcs
          .where(
            (calc) =>
                (_selected == _Category.all || calc.category == _selected) &&
                '${calc.name} ${calc.subtitle}'.toLowerCase().contains(_query),
          )
          .toList();

  String _label(_Category cat) {
    if (cat == _Category.structural) return 'Structural';
    if (cat == _Category.finishing) return 'Finishing';
    if (cat == _Category.mep) return 'Plumbing & Electrical';
    if (cat == _Category.woodwork) return 'Woodwork';
    if (cat == _Category.upvc) return 'UPVC';
    return 'All';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Construction Calculator'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        // Calculator is a bottom-nav tab, not a pushed route — nothing on
        // the Navigator stack to pop. MainShell wraps itself in
        // PopScope(canPop: false, ...) precisely so this falls through to
        // the same "switch back to the Home tab" handling as the hardware
        // back button.
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
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.construction,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Calculators',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '25 tools • Instant material & cost estimates',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // House Construction Wizard banner
            GestureDetector(
              onTap: () => context.push('/house-calculator'),
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.home_work_outlined,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Full Home Construction Calculator',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'All-in-one cost wizard for house construction',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            // Full Interior Calculator banner
            GestureDetector(
              onTap: () => context.push('/interior-calculator'),
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6A1B9A).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.chair_outlined,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Full Interior Calculator',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'One combined estimate across every finishing category',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            // Solar Installation Calculator banner
            GestureDetector(
              onTap: () => context.push('/solar-calculator'),
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE65100), Color(0xFFF57F17)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE65100).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.solar_power_outlined,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solar Installation Calculator',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'On-grid solar system size, cost & savings',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children:
                      _Category.values.map((cat) {
                        final active = _selected == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => setState(() => _selected = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    active
                                        ? const Color(0xFF1B5E20)
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      active
                                          ? const Color(0xFF1B5E20)
                                          : const Color(0xFFDDDDDD),
                                ),
                                boxShadow:
                                    active
                                        ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF1B5E20,
                                            ).withValues(alpha: 0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                        : [],
                              ),
                              child: Text(
                                _label(cat),
                                style: TextStyle(
                                  color:
                                      active ? Colors.white : Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight:
                                      active
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: AppSearchField(
                controller: _searchCtrl,
                hint: 'Find a calculator, e.g. tiles or steel',
                debounce: Duration.zero,
                onChanged:
                    (value) => setState(() => _query = value.toLowerCase()),
              ),
            ),
            if (_filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No calculators match. Try another term or select All.',
                ),
              ),
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.sizeOf(context).width >= 800 ? 5 : 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent:
                    150 *
                    MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0),
              ),
              itemCount: _filtered.length,
              itemBuilder: (_, i) => _CalcCard(type: _filtered[i]),
            ),
            const SizedBox(height: 12),
          ],
        ),
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
      onTap:
          () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _CalculatorSheet(type: type),
          ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF98A2B3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
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
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                textAlign: TextAlign.center,
                maxLines: 2,
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
  String _kitchenFinish = 'Medium';
  String _wardrobeFinish = 'Openable';
  // With/without-material toggle shared by Painting, False Ceiling, Wall Panel,
  // Wallpaper, Partition and Electrical — client rate card (Jul 2026) prices
  // each of these as a flat "with material" / "without material" pair.
  String _material = 'With Material';
  String _ceilingType = 'Gypsum / Gyproc';
  String _panelType = 'PVC';
  String _partitionType = 'Glass & Rubber';
  String _wallpaperType = 'Modern';
  String _plumbingTier = 'Normal';
  String _bedTier = 'Medium';
  String _tvUnitTier = 'Medium';
  String _basinCabinetTier = 'Medium';
  String _msRailingTier = 'Medium';

  // UPVC state
  String _upvcBrand = 'Prime-Tech STD (White)';
  String _upvcWinHeight = '≤ 4.5 ft';
  String _upvcProfileType = '2-Track Sliding';
  bool _upvcGeorgianBar = false;
  bool _upvcToughened = false;

  static const _upvcBrands = [
    'Prime-Tech STD (White)',
    'Auresta Luxury (Off White)',
    'Colour Profile',
  ];
  static const _upvcWinHeights = ['≤ 4.5 ft', '4.6 – 5.9 ft'];
  static const _upvcWinTypes = [
    '2-Track Sliding',
    '3-Track Sliding',
    'Casement / Openable',
  ];
  static const _upvcDoorTypes = [
    '2-Track Sliding',
    '3-Track Sliding',
    'Casement / Openable',
    'Slide & Fold',
  ];

  // Rates per sqft (from price list 18-05-2026)
  static const _upvcWindowRates = {
    'Prime-Tech STD (White)': {
      '≤ 4.5 ft': {
        '2-Track Sliding': 520.0,
        '3-Track Sliding': 580.0,
        'Casement / Openable': 600.0,
      },
      '4.6 – 5.9 ft': {
        '2-Track Sliding': 550.0,
        '3-Track Sliding': 630.0,
        'Casement / Openable': 650.0,
      },
    },
    'Auresta Luxury (Off White)': {
      '≤ 4.5 ft': {
        '2-Track Sliding': 550.0,
        '3-Track Sliding': 640.0,
        'Casement / Openable': 680.0,
      },
      '4.6 – 5.9 ft': {
        '2-Track Sliding': 600.0,
        '3-Track Sliding': 690.0,
        'Casement / Openable': 730.0,
      },
    },
    'Colour Profile': {
      '≤ 4.5 ft': {
        '2-Track Sliding': 800.0,
        '3-Track Sliding': 830.0,
        'Casement / Openable': 890.0,
      },
      '4.6 – 5.9 ft': {
        '2-Track Sliding': 850.0,
        '3-Track Sliding': 890.0,
        'Casement / Openable': 950.0,
      },
    },
  };

  static const _upvcDoorRates = {
    'Prime-Tech STD (White)': {
      '2-Track Sliding': 580.0,
      '3-Track Sliding': 650.0,
      'Casement / Openable': 700.0,
      'Slide & Fold': 1600.0,
    },
    'Auresta Luxury (Off White)': {
      '2-Track Sliding': 640.0,
      '3-Track Sliding': 700.0,
      'Casement / Openable': 750.0,
      'Slide & Fold': 1700.0,
    },
    'Colour Profile': {
      '2-Track Sliding': 900.0,
      '3-Track Sliding': 950.0,
      'Casement / Openable': 1050.0,
      'Slide & Fold': 2500.0,
    },
  };

  static const _upvcWarranty = {
    'Prime-Tech STD (White)': 'Hardware 1 Yr  •  Free AMC 6 Mo',
    'Auresta Luxury (Off White)': 'Hardware 2 Yr  •  Free AMC 12 Mo',
    'Colour Profile': 'Hardware 2 Yr  •  Free AMC 12 Mo',
  };

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
      if (name == 'Concrete Mix') {
        _calcConcrete();
      } else if (name == 'TMT Steel') {
        _calcSteel();
      } else if (name == 'Tiles') {
        _calcTiles();
      } else if (name == 'Paint') {
        _calcPaint();
      } else if (name == 'Plastering') {
        _calcPlastering();
      } else if (name == 'False Ceiling') {
        _calcFalseCeiling();
      } else if (name == 'Brickwork') {
        _calcBrickwork();
      } else if (name == 'Plumbing') {
        _calcPlumbing();
      } else if (name == 'Electrical') {
        _calcElectrical();
      } else if (name == 'Roofsheet') {
        _calcRoofsheet();
      } else if (name == 'Doors & Windows') {
        _calcDoors();
      } else if (name == 'Foundation') {
        _calcFoundation();
      } else if (name == 'Wall Panel') {
        _calcWallPanel();
      } else if (name == 'Waterproofing') {
        _calcWaterproofing();
      } else if (name == 'Wallpaper') {
        _calcWallpaper();
      } else if (name == 'Partition') {
        _calcPartition();
      } else if (name == 'Home Automation') {
        _calcHomeAutomation();
      } else if (name == 'MS Railing') {
        _calcMsRailing();
      } else if (name == 'TV Unit') {
        _calcTvUnit();
      } else if (name == 'Basin Cabinet') {
        _calcBasinCabinet();
      } else if (name == 'Bed') {
        _calcBed();
      } else if (name == 'Modular Kitchen') {
        _calcKitchen();
      } else if (name == 'Wardrobe') {
        _calcWardrobe();
      } else if (name == 'UPVC Window' || name == 'UPVC Door') {
        _calcUPVC();
      }
    } catch (_) {
      setState(() => _results = {'Error': 'Please enter valid numbers'});
    }
  }

  // ─── Structural ───────────────────────────────────────────────────────────

  void _calcConcrete() {
    final l = double.parse(_c1.text),
        w = double.parse(_c2.text),
        d = double.parse(_c3.text);
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
    setState(
      () =>
          _results = {
            'Wet Volume': '${wetVol.toStringAsFixed(3)} m³',
            'Cement Bags (50 kg)': '${cement.ceil()} bags',
            'Sand Required': '${sand.toStringAsFixed(3)} m³',
            'Aggregate Required': '${agg.toStringAsFixed(3)} m³',
            'Est. Material Cost':
                '₹${(cement.ceil() * 380 + sand * 1200 + agg * 950).toStringAsFixed(0)}',
          },
    );
  }

  void _calcSteel() {
    final len = double.parse(_c1.text),
        dia = double.parse(_c2.text),
        qty = double.parse(_c3.text);
    final weight = (dia * dia / 162) * len * qty;
    setState(
      () =>
          _results = {
            'Total Weight': '${weight.toStringAsFixed(2)} kg',
            'Weight in MT': '${(weight / 1000).toStringAsFixed(3)} MT',
            'Estimated Cost (@ ₹65/kg)': '₹${(weight * 65).toStringAsFixed(0)}',
          },
    );
  }

  void _calcBrickwork() {
    final l = double.parse(_c1.text),
        h = double.parse(_c2.text),
        t = double.parse(_c3.text);
    final vol = l * h * t;
    final bricks = (vol / (0.19 * 0.09 * 0.09) * 0.7).ceil();
    final mortar = vol * 0.3 * 1.3;
    final cement = mortar / 7 / 0.0347;
    final sand = mortar * 6 / 7;
    setState(
      () =>
          _results = {
            'Wall Volume': '${vol.toStringAsFixed(3)} m³',
            'Bricks Required': '$bricks nos.',
            'Cement Bags': '${cement.ceil()} bags',
            'Sand Required': '${sand.toStringAsFixed(3)} m³',
            'Est. Cost':
                '₹${(bricks * 7 + cement.ceil() * 380 + sand * 1200).toStringAsFixed(0)}',
          },
    );
  }

  void _calcFoundation() {
    final l = double.parse(_c1.text),
        w = double.parse(_c2.text),
        d = double.parse(_c3.text);
    final footings =
        _c4.text.isEmpty ? 1 : (double.tryParse(_c4.text) ?? 1).round();
    final volEach = l * w * d;
    final totalVol = volEach * footings;
    final dryVol = totalVol * 1.54;
    // M20 mix (1:1.5:3), sum = 5.5
    const sum = 5.5;
    final cement = (1.0 / sum) * dryVol / 0.0347;
    final sand = (1.5 / sum) * dryVol;
    final agg = (3.0 / sum) * dryVol;
    final steel = totalVol * 0.01 * 7850; // ~1% steel ratio by volume
    setState(
      () =>
          _results = {
            'Volume per Footing': '${volEach.toStringAsFixed(3)} m³',
            'Total Concrete Volume': '${totalVol.toStringAsFixed(3)} m³',
            'Cement Bags (M20)': '${cement.ceil()} bags',
            'Sand': '${sand.toStringAsFixed(3)} m³',
            'Aggregate': '${agg.toStringAsFixed(3)} m³',
            'Steel (est.)': '${steel.toStringAsFixed(0)} kg',
            'Est. Material Cost':
                '₹${(cement.ceil() * 380 + sand * 1200 + agg * 950 + steel * 65).toStringAsFixed(0)}',
          },
    );
  }

  void _calcRoofsheet() {
    final l = double.parse(_c1.text), w = double.parse(_c2.text);
    final pitch = _c3.text.isEmpty ? 15.0 : double.parse(_c3.text);
    final slopeFactor = 1 / cos(pitch * pi / 180);
    final roofArea = l * w * slopeFactor;
    final sheets = (roofArea / (0.9 * 3.0)).ceil();
    setState(
      () =>
          _results = {
            'Plan Area': '${(l * w).toStringAsFixed(1)} m²',
            'Sloped Roof Area': '${roofArea.toStringAsFixed(1)} m²',
            'Sheets (0.9 m × 3 m)': '$sheets sheets',
            'Fasteners (est.)': '${sheets * 8} nos.',
            'Est. Cost (@ ₹450/sheet)': '₹${(sheets * 450).toStringAsFixed(0)}',
          },
    );
  }

  // ─── Finishing ────────────────────────────────────────────────────────────

  void _calcTiles() {
    final l = double.parse(_c1.text), w = double.parse(_c2.text);
    final tl = double.parse(_c3.text), tw = double.parse(_c4.text);
    final roomArea = l * w;
    final tileArea = (tl / 12) * (tw / 12);
    final tiles = (roomArea / tileArea * 1.10).ceil();
    final rate =
        _material == 'With Material'
            ? rates.tileWithRate
            : rates.tileWithoutRate;
    setState(
      () =>
          _results = {
            'Material Provision': _material,
            'Room Area': '${roomArea.toStringAsFixed(2)} sqft',
            'Tiles Required (+10% waste)': '$tiles tiles',
            'Rate': '₹${rate.toStringAsFixed(0)}/sqft',
            'Total Cost': '₹${(roomArea * rate).toStringAsFixed(0)}',
          },
    );
  }

  void _calcPaint() {
    final l = double.parse(_c1.text),
        w = double.parse(_c2.text),
        h = double.parse(_c3.text);
    final wallArea = 2 * (l + w) * h;
    final ceilArea = l * w;
    final totalArea = wallArea + ceilArea;
    final rate =
        _material == 'With Material'
            ? rates.paintWithRate
            : rates.paintWithoutRate;
    setState(
      () =>
          _results = {
            'Wall Area': '${wallArea.toStringAsFixed(1)} sqft',
            'Ceiling Area': '${ceilArea.toStringAsFixed(1)} sqft',
            'Total Paintable Area': '${totalArea.toStringAsFixed(1)} sqft',
            'Material Provision': _material,
            'Rate': '₹${rate.toStringAsFixed(0)}/sqft',
            'Total Cost': '₹${(totalArea * rate).toStringAsFixed(0)}',
          },
    );
  }

  void _calcPlastering() {
    final l = double.parse(_c1.text), w = double.parse(_c2.text);
    final thick = _c3.text.isEmpty ? 12.0 : double.parse(_c3.text);
    final area = l * w;
    final vol = area * (thick / 1000) * 1.35;
    final cement = vol / 7 / 0.0347;
    final sand = vol * 6 / 7;
    setState(
      () =>
          _results = {
            'Plaster Area': '${area.toStringAsFixed(2)} m²',
            'Cement Bags': '${cement.ceil()} bags',
            'Sand Required': '${sand.toStringAsFixed(3)} m³',
            'Labour Cost': '₹${(area * 55).toStringAsFixed(0)}',
            'Est. Total Cost':
                '₹${(cement.ceil() * 380 + sand * 1200 + area * 55).toStringAsFixed(0)}',
          },
    );
  }

  void _calcFalseCeiling() {
    final l = double.parse(_c1.text), w = double.parse(_c2.text);
    final area = l * w;
    final panels = (area / 4).ceil();
    final mainT = (w / 4).ceil() * ((l / 4).ceil() + 1);
    final crossT = (l / 2).ceil() * ((w / 2).ceil() + 1);
    final wallAngle = (2 * (l + w) / 10).ceil();
    final rate =
        (_material == 'With Material'
            ? rates.ceilingWithRates
            : rates.ceilingWithoutRates)[_ceilingType]!;
    setState(
      () =>
          _results = {
            'Room Area': '${area.toStringAsFixed(1)} sqft',
            'Ceiling Type': _ceilingType,
            'Material Provision': _material,
            '2×2 Panels': '$panels nos.',
            'Main T-Runners': '$mainT nos.',
            'Cross T-Runners': '$crossT nos.',
            'Wall Angle (10 ft each)': '$wallAngle nos.',
            'Rate': '₹${rate.toStringAsFixed(0)}/sqft',
            'Total Cost': '₹${(area * rate).toStringAsFixed(0)}',
          },
    );
  }

  void _calcWallPanel() {
    final l = double.parse(_c1.text), h = double.parse(_c2.text);
    final wastage = _c3.text.isEmpty ? 10.0 : double.parse(_c3.text);
    final area = l * h;
    final withWaste = area * (1 + wastage / 100);
    final panels = (withWaste / 8).ceil(); // 2×4 ft panel = 8 sqft
    final rate =
        (_material == 'With Material'
            ? rates.panelWithRates
            : rates.panelWithoutRates)[_panelType]!;
    setState(
      () =>
          _results = {
            'Panel Type': _panelType,
            'Material Provision': _material,
            'Panel Area': '${area.toStringAsFixed(2)} sqft',
            'Area with Wastage': '${withWaste.toStringAsFixed(2)} sqft',
            'Panels (2×4 ft)': '$panels nos.',
            'Rate': '₹${rate.toStringAsFixed(0)}/sqft',
            'Total Cost': '₹${(area * rate).toStringAsFixed(0)}',
          },
    );
  }

  void _calcWaterproofing() {
    final area = double.parse(_c1.text);
    final coats = _c2.text.isEmpty ? 2 : int.parse(_c2.text);
    final membrane = (area * coats / 40).ceil() * 4; // 4 L covers 40 sqft/coat
    final primer = (area / 60).ceil() * 4;
    final rate =
        _material == 'With Material'
            ? rates.waterproofWithRate
            : rates.waterproofWithoutRate;
    setState(
      () =>
          _results = {
            'Waterproofing Area': '${area.toStringAsFixed(1)} sqft',
            'Coats Applied': '$coats',
            'Membrane Required': '$membrane litres',
            'Primer Required': '$primer litres',
            'Material Provision': _material,
            'Rate': '₹${rate.toStringAsFixed(0)}/sqft',
            'Total Cost': '₹${(area * rate).toStringAsFixed(0)}',
          },
    );
  }

  void _calcWallpaper() {
    final rolls = double.parse(_c1.text);
    final rate =
        _material == 'With Material'
            ? rates.wallpaperWithRates[_wallpaperType]!
            : rates.wallpaperWithoutRate;
    setState(
      () =>
          _results = {
            'Wallpaper Type': _wallpaperType,
            'Material Provision': _material,
            'Rolls': rolls.toStringAsFixed(0),
            'Rate': '₹${rate.toStringAsFixed(0)}/roll',
            'Total Cost': '₹${(rolls * rate).toStringAsFixed(0)}',
          },
    );
  }

  void _calcPartition() {
    final area = double.parse(_c1.text);
    final rate =
        (_material == 'With Material'
            ? rates.partitionWithRates
            : rates.partitionWithoutRates)[_partitionType]!;
    setState(
      () =>
          _results = {
            'Partition Type': _partitionType,
            'Material Provision': _material,
            'Area': '${area.toStringAsFixed(1)} sqft',
            'Rate': '₹${rate.toStringAsFixed(0)}/sqft',
            'Total Cost': '₹${(area * rate).toStringAsFixed(0)}',
          },
    );
  }

  // ─── MEP ─────────────────────────────────────────────────────────────────

  void _calcPlumbing() {
    final baths = int.parse(_c1.text);
    final rate =
        (_material == 'With Material'
            ? rates.plumbingWithRates
            : rates.plumbingWithoutRates)[_plumbingTier]!;
    setState(
      () =>
          _results = {
            'Bathrooms': '$baths nos.',
            'Package': _plumbingTier,
            'Material Provision': _material,
            'Rate': '₹${rate.toStringAsFixed(0)}/bathroom',
            'Total Cost': '₹${(baths * rate).toStringAsFixed(0)}',
          },
    );
  }

  void _calcElectrical() {
    final area = double.parse(_c1.text);
    final rooms = int.parse(_c2.text);
    final acs = _c3.text.isEmpty ? 0 : int.parse(_c3.text);
    final lightPts = rooms * 3 + 4;
    final fanPts = rooms + 2;
    final powerPts = rooms * 3 + 6 + acs * 2;
    final wireLen = area * 3.5;
    final rate =
        _material == 'With Material'
            ? rates.electricalWithRate
            : rates.electricalWithoutRate;
    setState(
      () =>
          _results = {
            'Light Points': '$lightPts nos.',
            'Fan Points': '$fanPts nos.',
            'Power Points': '$powerPts nos.',
            'Wire Length (est.)': '${wireLen.toStringAsFixed(0)} metres',
            'Material Provision': _material,
            'Rate': '₹${rate.toStringAsFixed(0)}/sqft (Floor Area)',
            'Total Cost': '₹${(area * rate).toStringAsFixed(0)}',
          },
    );
  }

  void _calcHomeAutomation() {
    final rooms = int.parse(_c1.text);
    setState(
      () =>
          _results = {
            'Rooms': '$rooms nos.',
            'Rate': '₹${rates.homeAutomationRate.toStringAsFixed(0)}/room',
            'Total Cost':
                '₹${(rooms * rates.homeAutomationRate).toStringAsFixed(0)}',
          },
    );
  }

  // ─── Woodwork ─────────────────────────────────────────────────────────────

  void _calcDoors() {
    final doors = int.parse(_c1.text);
    final windows = int.parse(_c2.text);
    final frameLen = doors * (2 * 2.1 + 0.9) + windows * (2 * 1.2 + 1.2);
    final doorCost = doors * 8500;
    final winCost = windows * 5500;
    setState(
      () =>
          _results = {
            'Doors': '$doors nos.',
            'Windows': '$windows nos.',
            'Total Frame Length': '${frameLen.toStringAsFixed(1)} m',
            'Door Cost (std.)': '₹$doorCost',
            'Window Cost (std.)': '₹$winCost',
            'Total Estimate': '₹${doorCost + winCost}',
          },
    );
  }

  void _calcKitchen() {
    final lowerLen = double.parse(_c1.text);
    final lowerH = double.parse(_c2.text);
    final upperLen = double.parse(_c3.text);
    final upperB = double.parse(_c4.text);
    final rate =
        (_material == 'With Material'
            ? rates.kitchenWithRates
            : rates.kitchenWithoutRates)[_kitchenFinish]!;
    final lowerCost = lowerLen * 1.5 * lowerH * rate;
    final upperCost = upperLen * upperB * rate;
    setState(
      () =>
          _results = {
            'Finish': '$_kitchenFinish  @₹${rate.toStringAsFixed(0)}/sqft',
            'Material Provision': _material,
            'Lower Cabinet Area':
                '${(lowerLen * 1.5 * lowerH).toStringAsFixed(2)} sqft',
            'Lower Cabinet Cost': '₹${lowerCost.toStringAsFixed(0)}',
            'Upper Cabinet Area':
                '${(upperLen * upperB).toStringAsFixed(2)} sqft',
            'Upper Cabinet Cost': '₹${upperCost.toStringAsFixed(0)}',
            'Total Estimate': '₹${(lowerCost + upperCost).toStringAsFixed(0)}',
          },
    );
  }

  /// The current inputs, with the same labels shown in the app — used for the
  /// "Specifications" section of the shared PDF estimate.
  Map<String, String> _inputSummary() {
    final name = widget.type.name;
    Map<String, String> withValues(
      Map<String, TextEditingController> fields, [
      Map<String, String> extra = const {},
    ]) {
      return {
        ...extra,
        for (final e in fields.entries)
          if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
      };
    }

    switch (name) {
      case 'Concrete Mix':
        return withValues(
          {'Length (m)': _c1, 'Width (m)': _c2, 'Depth / Thickness (m)': _c3},
          {'Mix Grade': _mix},
        );
      case 'TMT Steel':
        return withValues({
          'Bar Length (m)': _c1,
          'Diameter (mm)': _c2,
          'Number of Bars': _c3,
        });
      case 'Brickwork':
        return withValues({
          'Wall Length (m)': _c1,
          'Wall Height (m)': _c2,
          'Wall Thickness (m)': _c3,
        });
      case 'Foundation':
        return withValues({
          'Footing Length (m)': _c1,
          'Footing Width (m)': _c2,
          'Footing Depth (m)': _c3,
          'Number of Footings': _c4,
        });
      case 'Roofsheet':
        return withValues({
          'Roof Length (m)': _c1,
          'Roof Width (m)': _c2,
          'Pitch Angle (deg)': _c3,
        });
      case 'Tiles':
        return withValues(
          {
            'Room Length (ft)': _c1,
            'Room Width (ft)': _c2,
            'Tile Length (inches)': _c3,
            'Tile Width (inches)': _c4,
          },
          {'Material Provision': _material},
        );
      case 'Painting':
        return withValues(
          {
            'Room Length (ft)': _c1,
            'Room Width (ft)': _c2,
            'Room Height (ft)': _c3,
          },
          {'Material Provision': _material},
        );
      case 'Plastering':
        return withValues({
          'Length (m)': _c1,
          'Width (m)': _c2,
          'Thickness (mm)': _c3,
        });
      case 'False Ceiling':
        return withValues(
          {'Room Length (ft)': _c1, 'Room Width (ft)': _c2},
          {'Ceiling Type': _ceilingType, 'Material Provision': _material},
        );
      case 'Wall Panel':
        return withValues(
          {'Wall Length (ft)': _c1, 'Wall Height (ft)': _c2, 'Wastage %': _c3},
          {'Panel Type': _panelType, 'Material Provision': _material},
        );
      case 'Waterproofing':
        return withValues(
          {'Area (sqft)': _c1, 'Number of Coats': _c2},
          {'Material Provision': _material},
        );
      case 'Wallpaper':
        return withValues(
          {'Number of Rolls': _c1},
          {'Wallpaper Type': _wallpaperType, 'Material Provision': _material},
        );
      case 'Partition':
        return withValues(
          {'Partition Area (sqft)': _c1},
          {'Partition Type': _partitionType, 'Material Provision': _material},
        );
      case 'Plumbing':
        return withValues(
          {'Bathrooms': _c1},
          {'Package': _plumbingTier, 'Material Provision': _material},
        );
      case 'Electrical':
        return withValues(
          {
            'Floor Area (sqft)': _c1,
            'Number of Rooms': _c2,
            'Number of ACs': _c3,
          },
          {'Material Provision': _material},
        );
      case 'Home Automation':
        return withValues({'Number of Rooms': _c1});
      case 'MS Railing':
        return withValues(
          {'Running Length (RFT)': _c1},
          {'Package': _msRailingTier, 'Material Provision': _material},
        );
      case 'TV Unit':
        return withValues(
          {'TV Unit Area (sqft)': _c1},
          {'Package': _tvUnitTier, 'Material Provision': _material},
        );
      case 'Basin Cabinet':
        return withValues(
          {'Basin Cabinet Area (sqft)': _c1},
          {'Package': _basinCabinetTier, 'Material Provision': _material},
        );
      case 'Bed':
        return withValues(
          {'Quantity': _c1},
          {'Package': _bedTier, 'Material Provision': _material},
        );
      case 'Doors & Windows':
        return withValues({'Number of Doors': _c1, 'Number of Windows': _c2});
      case 'Modular Kitchen':
        return withValues(
          {
            'Lower Cabinet Length (ft)': _c1,
            'Lower Cabinet Height (ft)': _c2,
            'Upper Cabinet Length (ft)': _c3,
            'Upper Cabinet Breadth (ft)': _c4,
          },
          {'Finish Type': _kitchenFinish, 'Material Provision': _material},
        );
      case 'Wardrobe':
        return withValues(
          {'Length (ft)': _c1, 'Height (ft)': _c2},
          {'Type': _wardrobeFinish, 'Material Provision': _material},
        );
      case 'UPVC Window':
        return withValues(
          {'Width (ft)': _c1, 'Height (ft)': _c2},
          {
            'Brand': _upvcBrand,
            'Window Height Range': _upvcWinHeight,
            'Window Type': _upvcProfileType,
            if (_upvcGeorgianBar) 'Georgian Bar': 'Yes',
            if (_upvcToughened) 'Toughened Glass': 'Yes',
          },
        );
      case 'UPVC Door':
        return withValues(
          {'Width (ft)': _c1, 'Height (ft)': _c2},
          {
            'Brand': _upvcBrand,
            'Door Type': _upvcProfileType,
            if (_upvcGeorgianBar) 'Georgian Bar': 'Yes',
            if (_upvcToughened) 'Toughened Glass': 'Yes',
          },
        );
    }
    return {};
  }

  Future<void> _shareEstimatePdf() async {
    if (_results.isEmpty || _results.containsKey('Error')) return;
    await EstimatePdfService.share(
      context: context,
      title: '${widget.type.name} Estimate',
      accent: widget.type.color,
      specifications: _inputSummary(),
      details: _results,
    );
  }

  void _calcWardrobe() {
    final length = double.parse(_c1.text);
    final height = double.parse(_c2.text);
    final rate =
        (_material == 'With Material'
            ? rates.wardrobeWithRates
            : rates.wardrobeWithoutRates)[_wardrobeFinish]!;
    final area = length * height;
    final cost = area * rate;
    setState(
      () =>
          _results = {
            'Type': '$_wardrobeFinish  @₹${rate.toStringAsFixed(0)}/sqft',
            'Material Provision': _material,
            'Wardrobe Area': '${area.toStringAsFixed(2)} sqft',
            'Total Estimate': '₹${cost.toStringAsFixed(0)}',
          },
    );
  }

  void _calcMsRailing() {
    final length = double.parse(_c1.text);
    final rate =
        (_material == 'With Material'
            ? rates.msRailingWithRates
            : rates.msRailingWithoutRates)[_msRailingTier]!;
    setState(
      () =>
          _results = {
            'Package': _msRailingTier,
            'Material Provision': _material,
            'Running Length': '${length.toStringAsFixed(1)} RFT',
            'Rate': '₹${rate.toStringAsFixed(0)}/RFT',
            'Total Cost': '₹${(length * rate).toStringAsFixed(0)}',
          },
    );
  }

  void _calcTvUnit() {
    final area = double.parse(_c1.text);
    final rate =
        (_material == 'With Material'
            ? rates.tvUnitWithRates
            : rates.tvUnitWithoutRates)[_tvUnitTier]!;
    setState(
      () =>
          _results = {
            'Package': _tvUnitTier,
            'Material Provision': _material,
            'Area': '${area.toStringAsFixed(1)} sqft',
            'Rate': '₹${rate.toStringAsFixed(0)}/sqft',
            'Total Cost': '₹${(area * rate).toStringAsFixed(0)}',
          },
    );
  }

  void _calcBasinCabinet() {
    final area = double.parse(_c1.text);
    final rate =
        (_material == 'With Material'
            ? rates.basinCabinetWithRates
            : rates.basinCabinetWithoutRates)[_basinCabinetTier]!;
    setState(
      () =>
          _results = {
            'Package': _basinCabinetTier,
            'Material Provision': _material,
            'Area': '${area.toStringAsFixed(1)} sqft',
            'Rate': '₹${rate.toStringAsFixed(0)}/sqft',
            'Total Cost': '₹${(area * rate).toStringAsFixed(0)}',
          },
    );
  }

  void _calcBed() {
    final qty = int.parse(_c1.text);
    final rate =
        (_material == 'With Material'
            ? rates.bedWithRates
            : rates.bedWithoutRates)[_bedTier]!;
    setState(
      () =>
          _results = {
            'Package': _bedTier,
            'Material Provision': _material,
            'Quantity': '$qty nos.',
            'Rate per Bed': '₹${rate.toStringAsFixed(0)}',
            'Total Cost': '₹${(qty * rate).toStringAsFixed(0)}',
          },
    );
  }

  void _calcUPVC() {
    final w = double.parse(_c1.text);
    final h = double.parse(_c2.text);
    final area = w * h;

    final isDoor = widget.type.name == 'UPVC Door';
    final baseRate =
        isDoor
            ? _upvcDoorRates[_upvcBrand]![_upvcProfileType]!
            : _upvcWindowRates[_upvcBrand]![_upvcWinHeight]![_upvcProfileType]!;

    final addon =
        (_upvcGeorgianBar ? 20.0 : 0.0) + (_upvcToughened ? 35.0 : 0.0);
    final rate = baseRate + addon;
    final cost = area * rate;

    setState(
      () =>
          _results = {
            'Brand': _upvcBrand,
            if (!isDoor) 'Window Height': _upvcWinHeight,
            'Type': _upvcProfileType,
            'Size': '${w.toStringAsFixed(1)} × ${h.toStringAsFixed(1)} ft',
            'Area': '${area.toStringAsFixed(2)} sqft',
            'Base Rate': '₹${baseRate.toStringAsFixed(0)}/sqft',
            if (addon > 0) 'Add-ons': '+₹${addon.toStringAsFixed(0)}/sqft',
            'Rate': '₹${rate.toStringAsFixed(0)}/sqft',
            'Total Estimate': '₹${cost.toStringAsFixed(0)}',
            'Warranty': _upvcWarranty[_upvcBrand]!,
            if (area > 2500) 'Large Order': 'Eligible for ₹20–40/sqft discount',
          },
    );
  }

  // ─── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.type.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.type.icon,
                    color: widget.type.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.type.name} Calculator',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.type.subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._buildInputs(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate_outlined, size: 20),
                label: const Text(
                  'Calculate',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.type.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                  border: Border.all(
                    color: widget.type.color.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: widget.type.color,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Calculation Results',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: widget.type.color,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._results.entries.map(
                      (e) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.key,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              e.value,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '* Estimates only. Actual quantities may vary.',
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              if (!_results.containsKey('Error')) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _shareEstimatePdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text(
                      'Generate & Share Quotation (PDF)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: widget.type.color,
                      side: BorderSide(color: widget.type.color),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
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
        _dropdown('Mix Grade', _mix, [
          'M15',
          'M20',
          'M25',
          'M30',
        ], (v) => setState(() => _mix = v!)),
      ];
    }
    if (name == 'TMT Steel') {
      return [
        _field(_c1, 'Bar Length (m)'),
        _field(_c2, 'Diameter (mm)'),
        _field(_c3, 'Number of Bars'),
      ];
    }
    if (name == 'Brickwork') {
      return [
        _field(_c1, 'Wall Length (m)'),
        _field(_c2, 'Wall Height (m)'),
        _field(_c3, 'Wall Thickness (m, e.g. 0.23)'),
      ];
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
      return [
        _field(_c1, 'Roof Length (m)'),
        _field(_c2, 'Roof Width (m)'),
        _field(_c3, 'Pitch Angle (°, default: 15)'),
      ];
    }
    if (name == 'Tiles') {
      return [
        _materialDropdown(),
        _field(_c1, 'Room Length (ft)'),
        _field(_c2, 'Room Width (ft)'),
        _field(_c3, 'Tile Length (inches)'),
        _field(_c4, 'Tile Width (inches)'),
      ];
    }
    if (name == 'Painting') {
      return [
        _materialDropdown(),
        _field(_c1, 'Room Length (ft)'),
        _field(_c2, 'Room Width (ft)'),
        _field(_c3, 'Room Height (ft)'),
      ];
    }
    if (name == 'Plastering') {
      return [
        _field(_c1, 'Length (m)'),
        _field(_c2, 'Width (m)'),
        _field(_c3, 'Thickness in mm (default: 12)'),
      ];
    }
    if (name == 'False Ceiling') {
      return [
        _dropdown(
          'Ceiling Type',
          _ceilingType,
          rates.ceilingWithRates.keys.toList(),
          (v) => setState(() => _ceilingType = v!),
        ),
        _materialDropdown(),
        _field(_c1, 'Room Length (ft)'),
        _field(_c2, 'Room Width (ft)'),
      ];
    }
    if (name == 'Wall Panel') {
      return [
        _dropdown(
          'Panel Type',
          _panelType,
          rates.panelWithRates.keys.toList(),
          (v) => setState(() => _panelType = v!),
        ),
        _materialDropdown(),
        _field(_c1, 'Wall Length (ft)'),
        _field(_c2, 'Wall Height (ft)'),
        _field(_c3, 'Wastage % (default: 10)'),
      ];
    }
    if (name == 'Waterproofing') {
      return [
        _materialDropdown(),
        _field(_c1, 'Area to Waterproof (sqft)'),
        _field(_c2, 'Number of Coats (default: 2)'),
      ];
    }
    if (name == 'Wallpaper') {
      return [
        _dropdown(
          'Wallpaper Type',
          _wallpaperType,
          rates.wallpaperWithRates.keys.toList(),
          (v) => setState(() => _wallpaperType = v!),
        ),
        _materialDropdown(),
        _field(_c1, 'Number of Rolls'),
      ];
    }
    if (name == 'Partition') {
      return [
        _dropdown(
          'Partition Type',
          _partitionType,
          rates.partitionWithRates.keys.toList(),
          (v) => setState(() => _partitionType = v!),
        ),
        _materialDropdown(),
        _field(_c1, 'Partition Area (sqft)'),
      ];
    }
    if (name == 'Plumbing') {
      return [
        _dropdown(
          'Package',
          _plumbingTier,
          rates.plumbingWithRates.keys.toList(),
          (v) => setState(() => _plumbingTier = v!),
        ),
        _materialDropdown(),
        _field(_c1, 'Number of Bathrooms'),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            'Interior sanitary work only, with piping & fitting',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ),
      ];
    }
    if (name == 'Electrical') {
      return [
        _materialDropdown(),
        _field(_c1, 'Floor Area (sqft)'),
        _field(_c2, 'Number of Rooms'),
        _field(_c3, 'Number of ACs (0 if none)'),
      ];
    }
    if (name == 'Home Automation') {
      return [_field(_c1, 'Number of Rooms')];
    }
    if (name == 'MS Railing') {
      return [
        _dropdown(
          'Package',
          _msRailingTier,
          rates.msRailingWithRates.keys.toList(),
          (v) => setState(() => _msRailingTier = v!),
        ),
        _materialDropdown(),
        _field(_c1, 'Running Length (RFT)'),
      ];
    }
    if (name == 'TV Unit') {
      return [
        _dropdown(
          'Package',
          _tvUnitTier,
          rates.tvUnitWithRates.keys.toList(),
          (v) => setState(() => _tvUnitTier = v!),
        ),
        _materialDropdown(),
        _field(_c1, 'TV Unit Area (sqft)'),
      ];
    }
    if (name == 'Basin Cabinet') {
      return [
        _dropdown(
          'Package',
          _basinCabinetTier,
          rates.basinCabinetWithRates.keys.toList(),
          (v) => setState(() => _basinCabinetTier = v!),
        ),
        _materialDropdown(),
        _field(_c1, 'Basin Cabinet Area (sqft)'),
      ];
    }
    if (name == 'Bed') {
      return [
        _dropdown(
          'Package',
          _bedTier,
          rates.bedWithRates.keys.toList(),
          (v) => setState(() => _bedTier = v!),
        ),
        _materialDropdown(),
        _field(_c1, 'Quantity (number of beds)'),
      ];
    }
    if (name == 'Doors & Windows') {
      return [_field(_c1, 'Number of Doors'), _field(_c2, 'Number of Windows')];
    }
    if (name == 'Modular Kitchen') {
      return [
        _dropdown(
          'Package',
          _kitchenFinish,
          rates.kitchenWithRates.keys.toList(),
          (v) => setState(() => _kitchenFinish = v!),
        ),
        _materialDropdown(),
        _field(_c1, 'Lower Cabinet Length (ft)'),
        _field(_c2, 'Lower Cabinet Height (ft)'),
        _field(_c3, 'Upper Cabinet Length (ft)'),
        _field(_c4, 'Upper Cabinet Breadth (ft)'),
      ];
    }
    if (name == 'Wardrobe') {
      return [
        _dropdown(
          'Type',
          _wardrobeFinish,
          rates.wardrobeWithRates.keys.toList(),
          (v) => setState(() => _wardrobeFinish = v!),
        ),
        _materialDropdown(),
        _field(_c1, 'Length (ft)'),
        _field(_c2, 'Height (ft)'),
      ];
    }
    if (name == 'UPVC Window') {
      return [
        _dropdown(
          'Brand',
          _upvcBrand,
          _upvcBrands,
          (v) => setState(() {
            _upvcBrand = v!;
            _results = {};
          }),
        ),
        _dropdown(
          'Window Height Range',
          _upvcWinHeight,
          _upvcWinHeights,
          (v) => setState(() => _upvcWinHeight = v!),
        ),
        _dropdown(
          'Window Type',
          _upvcProfileType,
          _upvcWinTypes,
          (v) => setState(() => _upvcProfileType = v!),
        ),
        _field(_c1, 'Width (ft)'),
        _field(_c2, 'Height (ft)'),
        _upvcAddonRow(),
      ];
    }
    if (name == 'UPVC Door') {
      return [
        _dropdown(
          'Brand',
          _upvcBrand,
          _upvcBrands,
          (v) => setState(() {
            _upvcBrand = v!;
            _results = {};
          }),
        ),
        _dropdown(
          'Door Type',
          _upvcProfileType,
          _upvcDoorTypes,
          (v) => setState(() => _upvcProfileType = v!),
        ),
        _field(_c1, 'Width (ft)'),
        _field(_c2, 'Height (ft)'),
        _upvcAddonRow(),
      ];
    }
    return [];
  }

  Widget _upvcAddonRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add-ons',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Row(
            children: [
              Checkbox(
                value: _upvcGeorgianBar,
                onChanged: (v) => setState(() => _upvcGeorgianBar = v!),
                visualDensity: VisualDensity.compact,
              ),
              const Text(
                'Georgian Bar (+₹20/sqft)',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
          Row(
            children: [
              Checkbox(
                value: _upvcToughened,
                onChanged: (v) => setState(() => _upvcToughened = v!),
                visualDensity: VisualDensity.compact,
              ),
              const Text(
                '5mm Toughened Glass (+₹35/sqft)',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _materialDropdown() => _dropdown(
    'Material Provision',
    _material,
    const ['With Material', 'Without Material'],
    (v) => setState(() => _material = v!),
  );

  Widget _dropdown(
    String label,
    String initialValue,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          isDense: true,
        ),
        items:
            items
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
