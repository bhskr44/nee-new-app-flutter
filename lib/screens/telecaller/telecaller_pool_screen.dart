import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/telecaller_lead_model.dart';
import '../../providers/telecaller_provider.dart';
import 'lead_source_line.dart';

Future<void> launchDialer(String phone) async {
  final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), ''));
  if (await canLaunchUrl(uri)) launchUrl(uri);
}

class TelecallerPoolScreen extends StatefulWidget {
  const TelecallerPoolScreen({super.key});

  @override
  State<TelecallerPoolScreen> createState() => _TelecallerPoolScreenState();
}

class _TelecallerPoolScreenState extends State<TelecallerPoolScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TelecallerProvider>().fetchPool(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TelecallerProvider>(
      builder: (context, prov, _) => Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Leads to Call', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('New leads and follow-ups due today', style: TextStyle(fontSize: 12.5, color: Colors.grey[600])),
                  if (prov.nextBatchAt != null) ...[
                    const SizedBox(height: 10),
                    _BatchBanner(batchSize: prov.batchSize ?? 0, nextBatchAt: prov.nextBatchAt!),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    onSubmitted: (v) => prov.fetchPool(refresh: true, search: v),
                    decoration: InputDecoration(
                      hintText: 'Search leads...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD0D5DD))),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                  ),
                ]),
              ),
              Expanded(
                child: prov.pool.isEmpty && prov.poolLoading
                    ? const Center(child: CircularProgressIndicator())
                    : prov.pool.isEmpty && prov.error != null
                        ? _PoolErrorState(
                            message: prov.error!,
                            onRetry: () => prov.fetchPool(refresh: true, search: _searchCtrl.text),
                          )
                        : prov.pool.isEmpty
                        ? RefreshIndicator(
                            onRefresh: () => prov.fetchPool(refresh: true, search: _searchCtrl.text),
                            child: ListView(children: [
                              const SizedBox(height: 120),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Text(
                                    prov.nextBatchAt != null
                                        ? "You're done with this batch. New leads arrive at ${_formatTime(prov.nextBatchAt!)} — pull down to refresh then."
                                        : 'No leads waiting to be called right now.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              ),
                            ]),
                          )
                        : RefreshIndicator(
                            onRefresh: () => prov.fetchPool(refresh: true, search: _searchCtrl.text),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: prov.pool.length + (prov.poolHasMore ? 1 : 0),
                              itemBuilder: (_, i) {
                                if (i >= prov.pool.length) {
                                  prov.fetchPool();
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  );
                                }
                                return _PoolLeadCard(lead: prov.pool[i]);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatTime(DateTime t) {
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$hour:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
}

/// Shown when the admin's per-hour lead limit is on — the list is then just
/// this telecaller's batch, not the whole pool.
class _BatchBanner extends StatelessWidget {
  final int batchSize;
  final DateTime nextBatchAt;
  const _BatchBanner({required this.batchSize, required this.nextBatchAt});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        const Icon(Icons.schedule, size: 16, color: Color(0xFF2E7D32)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Your batch: up to $batchSize leads · next batch at ${_formatTime(nextBatchAt)}',
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF1B5E20)),
          ),
        ),
      ]),
    );
  }
}

/// Shown instead of "No leads waiting" when the fetch actually failed —
/// otherwise a 403/500/network error looks identical to a genuinely empty
/// pool, which made a broken telecaller-role assignment or backend deploy
/// gap very hard to tell apart from "nobody's posted a lead yet."
class _PoolErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _PoolErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PoolLeadCard extends StatefulWidget {
  final TelecallerLeadModel lead;
  const _PoolLeadCard({required this.lead});

  @override
  State<_PoolLeadCard> createState() => _PoolLeadCardState();
}

class _PoolLeadCardState extends State<_PoolLeadCard> {
  bool _claiming = false;

  /// Claims the lead (locking it from other telecallers), dials the client,
  /// then moves it to "My Leads" where the outcome is logged after the call.
  Future<void> _claimAndCall() async {
    setState(() => _claiming = true);
    final error = await context.read<TelecallerProvider>().claim(widget.lead.id);

    if (!mounted) return;
    setState(() => _claiming = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.orange));
      return;
    }

    await launchDialer(widget.lead.contact);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Lead moved to My Leads — log what you found out after the call.'),
        backgroundColor: Color(0xFF2E7D32)));
  }

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(lead.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          LeadSourceLine(lead: lead),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.phone, size: 15, color: Colors.grey),
            const SizedBox(width: 4),
            Text(lead.contact, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _claiming ? null : _claimAndCall,
              icon: _claiming
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.call_outlined, size: 16),
              label: Text(_claiming ? 'Claiming...' : 'Call This Lead', style: const TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
