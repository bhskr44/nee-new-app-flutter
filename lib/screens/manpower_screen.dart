import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/worker_model.dart';
import '../providers/worker_provider.dart';
import '../services/activity_service.dart';

class ManpowerScreen extends StatefulWidget {
  const ManpowerScreen({super.key});

  @override
  State<ManpowerScreen> createState() => _ManpowerScreenState();
}

class _ManpowerScreenState extends State<ManpowerScreen> {
  static const _trades = [
    'All', 'Mason', 'Plumber', 'Electrician', 'Carpenter',
    'Painter', 'Tiler', 'Welder', 'Site Supervisor',
  ];

  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<WorkerProvider>().fetch();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkerProvider>(
      builder: (context, prov, _) => Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('Construction Manpower'),
          actions: [IconButton(icon: const Icon(Icons.tune), onPressed: () {})],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showRegisterWorker(context, prov),
          backgroundColor: const Color(0xFF1565C0),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Register as Worker', style: TextStyle(color: Colors.white)),
        ),
        body: Column(
          children: [
            _buildSearch(prov),
            _buildTrades(prov),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => prov.fetch(refresh: true),
                child: prov.workers.isEmpty && prov.loading
                    ? const Center(child: CircularProgressIndicator())
                    : prov.workers.isEmpty
                        ? const Center(child: Text('No workers found'))
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: prov.workers.length + (prov.hasMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i == prov.workers.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              return _WorkerCard(worker: prov.workers[i]);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch(WorkerProvider prov) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: prov.setSearch,
        decoration: InputDecoration(
          hintText: 'Search workers by name, trade...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                  _searchCtrl.clear();
                  prov.setSearch('');
                })
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          fillColor: Colors.white,
        ),
      ),
    );
  }

  void _showRegisterWorker(BuildContext context, WorkerProvider prov) {
    const tradeOptions = [
      'Mason', 'Plumber', 'Electrician', 'Carpenter', 'Painter',
      'Welder', 'Tiler', 'Roofer', 'Plasterer', 'Steel Fixer',
      'Concrete Mixer', 'Equipment Operator', 'Site Supervisor',
    ];
    final phoneCtrl    = TextEditingController();
    final locationCtrl = TextEditingController();
    final rateCtrl     = TextEditingController();
    final expCtrl      = TextEditingController();
    final bioCtrl      = TextEditingController();
    String selectedTrade = 'Mason';
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Register as Worker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Your profile will be visible to contractors on the platform.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedTrade,
                items: tradeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setModalState(() => selectedTrade = v!),
                decoration: const InputDecoration(labelText: 'Trade / Skill *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: locationCtrl,
                decoration: const InputDecoration(labelText: 'Location (District) *'),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: rateCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Daily Rate (₹) *'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: expCtrl,
                    decoration: const InputDecoration(labelText: 'Experience (e.g. 5 yrs)'),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              TextField(
                controller: bioCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'About You (optional)'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: submitting
                      ? null
                      : () async {
                          if (phoneCtrl.text.trim().isEmpty ||
                              locationCtrl.text.trim().isEmpty ||
                              rateCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Please fill all required fields')),
                            );
                            return;
                          }
                          setModalState(() => submitting = true);
                          final error = await prov.register({
                            'trade':      selectedTrade,
                            'phone':      phoneCtrl.text.trim(),
                            'location':   locationCtrl.text.trim(),
                            'daily_rate': double.tryParse(rateCtrl.text.trim()) ?? 0,
                            'experience': expCtrl.text.trim().isEmpty ? '1 yr' : expCtrl.text.trim(),
                            'bio':        bioCtrl.text.trim(),
                          });
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error ?? 'Profile registered! You are now visible to contractors.'),
                                backgroundColor: error == null ? Colors.green[700] : Colors.red[700],
                                duration: const Duration(seconds: 4),
                              ),
                            );
                            if (error == null) prov.fetch(refresh: true);
                          }
                        },
                  child: submitting
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Registration', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrades(WorkerProvider prov) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _trades.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t = _trades[i];
          final selected = t == prov.trade;
          return ChoiceChip(
            label: Text(t),
            selected: selected,
            onSelected: (_) => prov.setTrade(t),
            selectedColor: const Color(0xFF1565C0),
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.grey[700],
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final WorkerModel worker;
  const _WorkerCard({required this.worker});

  @override
  Widget build(BuildContext context) {
    final rating = worker.rating ?? 0.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF1565C0).withAlpha(26),
            child: Text(
              (worker.userName ?? worker.trade).substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 22, color: Color(0xFF1565C0), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(
                    worker.userName ?? 'Worker',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (worker.isVerified)
                  const Icon(Icons.verified, color: Color(0xFF1565C0), size: 16),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(worker.trade,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF1565C0), fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: worker.available ? Colors.green.withAlpha(25) : Colors.red.withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(worker.available ? 'Available' : 'Busy',
                      style: TextStyle(
                        fontSize: 10,
                        color: worker.available ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.location_on, size: 12, color: Colors.grey),
                Text(worker.location, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const Spacer(),
                if (rating > 0) ...[
                  const Icon(Icons.star, size: 13, color: Colors.amber),
                  Text(rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ]),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('₹${worker.dailyRate.toStringAsFixed(0)}/day',
                      style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(worker.experience, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ElevatedButton(
                    onPressed: () => _hire(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Hire', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              if (worker.skills.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: worker.skills.take(4).map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(s, style: TextStyle(fontSize: 10, color: Colors.grey[700])),
                  )).toList(),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  void _hire(BuildContext context) {
    final name = worker.userName ?? worker.trade;
    activityService.log(
      'hire_worker',
      entityType: 'worker',
      entityId: worker.id,
      entityName: name,
      extra: {'phone': worker.phone, 'trade': worker.trade},
    );
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text('${worker.trade} - ${worker.location}', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(worker.phone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1565C0))),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final uri = Uri(scheme: 'tel', path: worker.phone.replaceAll(RegExp(r'[^\d+]'), ''));
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                icon: const Icon(Icons.phone),
                label: const Text('Call'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final clean = worker.phone.replaceAll(RegExp(r'[^\d]'), '');
                  final uri = Uri.parse('https://wa.me/91$clean');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.chat),
                label: const Text('WhatsApp'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
