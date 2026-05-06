import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class ManpowerScreen extends StatefulWidget {
  const ManpowerScreen({super.key});

  @override
  State<ManpowerScreen> createState() => _ManpowerScreenState();
}

class _ManpowerScreenState extends State<ManpowerScreen> {
  String _selected = 'All';
  String _search = '';

  static const _trades = ['All', 'Mason', 'Plumber', 'Electrician', 'Carpenter', 'Painter', 'Tiler', 'Welder', 'Site Supervisor', 'False Ceiling Worker'];

  List<Worker> get _filtered => mockWorkers.where((w) {
        final matchTrade = _selected == 'All' || w.trade == _selected;
        final matchSearch = _search.isEmpty || w.name.toLowerCase().contains(_search.toLowerCase()) || w.trade.toLowerCase().contains(_search.toLowerCase());
        return matchTrade && matchSearch;
      }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Construction Manpower'),
        actions: [
          IconButton(icon: const Icon(Icons.tune), onPressed: () {}),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRegisterWorker(context),
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Register as Worker', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          _buildSearch(),
          _buildFilter(),
          _buildSummary(),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No workers found'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _WorkerCard(worker: _filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          hintText: 'Search by name or trade...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFilter() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _trades.length,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t = _trades[i];
          final sel = t == _selected;
          return ChoiceChip(
            label: Text(t),
            selected: sel,
            onSelected: (_) => setState(() => _selected = t),
            selectedColor: const Color(0xFF1565C0),
            labelStyle: TextStyle(color: sel ? Colors.white : Colors.grey[700], fontSize: 13,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }

  Widget _buildSummary() {
    final available = _filtered.where((w) => w.available).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          Text('${_filtered.length} workers found  •  ',
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text('$available available now', style: const TextStyle(color: Colors.green, fontSize: 13)),
        ],
      ),
    );
  }

  void _showRegisterWorker(BuildContext context) {
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
            const Text('Register as Worker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 10),
            const TextField(decoration: InputDecoration(labelText: 'Trade / Skill')),
            const SizedBox(height: 10),
            const TextField(decoration: InputDecoration(labelText: 'Years of Experience')),
            const SizedBox(height: 10),
            const TextField(decoration: InputDecoration(labelText: 'Daily Rate (₹)')),
            const SizedBox(height: 10),
            const TextField(decoration: InputDecoration(labelText: 'Location')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
                child: const Text('Register Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final Worker worker;
  const _WorkerCard({required this.worker});

  static const _tradeColors = {
    'Mason': Color(0xFF795548),
    'Plumber': Color(0xFF1565C0),
    'Electrician': Color(0xFFF57F17),
    'Carpenter': Color(0xFF4E342E),
    'Painter': Color(0xFF6A1B9A),
    'Tiler': Color(0xFF00695C),
    'Welder': Color(0xFF37474F),
    'Site Supervisor': Color(0xFFE65100),
    'False Ceiling Worker': Color(0xFF283593),
  };

  static const _tradeImages = {
    'Mason': 'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?w=600&h=200&fit=crop&auto=format',
    'Plumber': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&h=200&fit=crop&auto=format',
    'Electrician': 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=600&h=200&fit=crop&auto=format',
    'Carpenter': 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=600&h=200&fit=crop&auto=format',
    'Painter': 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=600&h=200&fit=crop&auto=format',
    'Tiler': 'https://images.unsplash.com/photo-1600585152220-90363fe7e115?w=600&h=200&fit=crop&auto=format',
    'Welder': 'https://images.unsplash.com/photo-1486325212027-8081e485255e?w=600&h=200&fit=crop&auto=format',
    'Site Supervisor': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=600&h=200&fit=crop&auto=format',
    'False Ceiling Worker': 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=600&h=200&fit=crop&auto=format',
  };

  Color get _color => _tradeColors[worker.trade] ?? const Color(0xFF455A64);
  String get _imageUrl => _tradeImages[worker.trade] ?? 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=600&h=200&fit=crop&auto=format';

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trade banner image
          SizedBox(
            height: 100,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  _imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => ColoredBox(color: _color.withValues(alpha: 0.2)),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _color.withValues(alpha: 0.3),
                        _color.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  top: 10, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: worker.available ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      worker.available ? '● Available' : '● Busy',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10, left: 14,
                  child: Row(children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      child: Text(
                        worker.name[0],
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _color),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(worker.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(worker.trade,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ]),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.location_on, size: 12, color: Colors.grey),
                  Text(worker.location, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(width: 8),
                  Text('· ${worker.experience}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const Spacer(),
                  ...List.generate(5, (i) => Icon(
                    i < worker.rating.floor() ? Icons.star : Icons.star_border,
                    size: 12, color: Colors.amber,
                  )),
                  const SizedBox(width: 3),
                  Text(worker.rating.toString(), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ]),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: worker.skills.map((s) => Chip(
                    label: Text(s, style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.grey[100],
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('₹${worker.dailyRate.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                      const Text('per day', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ]),
                    Row(children: [
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.phone_outlined, size: 15),
                        label: const Text('Call', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1565C0),
                          side: const BorderSide(color: Color(0xFF1565C0)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: worker.available ? () => _showBook(context) : null,
                        icon: const Icon(Icons.calendar_today, size: 15),
                        label: const Text('Book', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                    ]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBook(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Book ${worker.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Trade: ${worker.trade}'),
            const SizedBox(height: 8),
            Text('Rate: ₹${worker.dailyRate.toStringAsFixed(0)}/day'),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Start Date', prefixIcon: Icon(Icons.calendar_today))),
            const SizedBox(height: 8),
            const TextField(decoration: InputDecoration(labelText: 'Number of Days', prefixIcon: Icon(Icons.access_time))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Booking request sent to ${worker.name}!'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Confirm Booking'),
          ),
        ],
      ),
    );
  }
}
