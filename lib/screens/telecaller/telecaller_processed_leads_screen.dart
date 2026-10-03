import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/telecaller_lead_model.dart';
import '../../providers/telecaller_provider.dart';
import '../../widgets/app_empty_state.dart';
import 'lead_call_history_sheet.dart';
import 'lead_source_line.dart';

const _statusFilters = [
  (null, 'All'),
  ('hot', 'Hot'),
  ('cold', 'Cold'),
  ('callback', 'Callback'),
  ('archive', 'Archive'),
  ('closed', 'Closed'),
];

const _statusColors = {
  'hot': Color(0xFFD32F2F),
  'cold': Color(0xFF1565C0),
  'callback': Color(0xFFEF6C00),
  'archive': Color(0xFF757575),
  'closed': Color(0xFF2E7D32),
};

/// Every lead this telecaller has ever logged a call outcome for — the pool
/// and "My Leads" both drop a lead the instant an outcome is saved (claim
/// cleared regardless of outcome), so without this screen a Hot/Cold/
/// Callback/Archive/Closed lead was simply gone from the telecaller's own
/// view forever. Filterable by outcome; tapping a card opens the same
/// call-history sheet used elsewhere for the full log + project details.
class TelecallerProcessedLeadsScreen extends StatefulWidget {
  const TelecallerProcessedLeadsScreen({super.key});

  @override
  State<TelecallerProcessedLeadsScreen> createState() =>
      _TelecallerProcessedLeadsScreenState();
}

class _TelecallerProcessedLeadsScreenState
    extends State<TelecallerProcessedLeadsScreen> {
  String? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TelecallerProvider>().fetchProcessedLeads(refresh: true);
    });
  }

  void _selectStatus(String? status) {
    setState(() => _status = status);
    context.read<TelecallerProvider>().fetchProcessedLeads(refresh: true, status: status);
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Processed Leads',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Every lead you\'ve logged a call outcome for',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey[600])),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statusFilters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final (value, label) = _statusFilters[i];
                      final selected = _status == value;
                      final color = value != null ? _statusColors[value] : null;
                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) => _selectStatus(value),
                        selectedColor: color ?? Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          fontSize: 12.5,
                          color: selected ? Colors.white : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: prov.processedLeads.isEmpty && prov.processedLoading
                    ? const Center(child: CircularProgressIndicator())
                    : prov.processedLeads.isEmpty && prov.error != null
                        ? AppEmptyState(
                            icon: Icons.cloud_off_outlined,
                            title: 'Could not load this list',
                            message: prov.error!,
                            actionLabel: 'Try again',
                            onAction: () => prov.fetchProcessedLeads(refresh: true, status: _status),
                          )
                        : prov.processedLeads.isEmpty
                            ? Center(
                                child: Text(
                                  "You haven't logged any call outcomes yet.",
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () => prov.fetchProcessedLeads(refresh: true, status: _status),
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                  itemCount: prov.processedLeads.length + (prov.processedHasMore ? 1 : 0),
                                  itemBuilder: (_, i) {
                                    if (i >= prov.processedLeads.length) {
                                      prov.fetchProcessedLeads(status: _status);
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 16),
                                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                      );
                                    }
                                    return _ProcessedLeadCard(lead: prov.processedLeads[i]);
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

class _ProcessedLeadCard extends StatelessWidget {
  final TelecallerLeadModel lead;
  const _ProcessedLeadCard({required this.lead});

  String _fmtValue(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final status = lead.telecallerStatus;
    final color = _statusColors[status] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showLeadCallHistorySheet(
          context,
          leadId: lead.id,
          leadTitle: lead.title,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lead.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      (status ?? '—').toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                ],
              ),
              LeadSourceLine(lead: lead, showLocation: false),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 13, color: Colors.grey),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(lead.location,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12), overflow: TextOverflow.ellipsis),
                  ),
                  Text(_fmtValue(lead.value),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF2E7D32))),
                ],
              ),
              if (status == 'callback' && lead.nextFollowUpAt != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.event_repeat, size: 13, color: Colors.grey),
                    const SizedBox(width: 2),
                    Text('Follow up: ${lead.nextFollowUpAt}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.history, size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 3),
                  Text('Tap to view full call history',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
