import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/telecaller_lead_model.dart';
import '../../providers/telecaller_provider.dart';
import 'call_outcome_sheet.dart';
import 'lead_call_history_sheet.dart';
import 'lead_source_line.dart';
import 'telecaller_pool_screen.dart' show launchDialer;

class TelecallerMyLeadsScreen extends StatefulWidget {
  const TelecallerMyLeadsScreen({super.key});

  @override
  State<TelecallerMyLeadsScreen> createState() =>
      _TelecallerMyLeadsScreenState();
}

class _TelecallerMyLeadsScreenState extends State<TelecallerMyLeadsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TelecallerProvider>().fetchMyLeads();
    });
    _searchCtrl.addListener(
      () => setState(() => _query = _searchCtrl.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Matches against the lead name and the client's phone number.
  bool _matches(TelecallerLeadModel lead) {
    if (_query.isEmpty) return true;
    if (lead.title.toLowerCase().contains(_query)) return true;
    if (lead.contact.toLowerCase().contains(_query)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TelecallerProvider>(
      builder: (context, prov, _) {
        final filtered = prov.myLeads.where(_matches).toList();
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Leads',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search by name or phone...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          suffixIcon:
                              _query.isEmpty
                                  ? null
                                  : IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => _searchCtrl.clear(),
                                  ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      prov.myLeads.isEmpty && prov.myLeadsLoading
                          ? const Center(child: CircularProgressIndicator())
                          : prov.myLeads.isEmpty
                          ? Center(
                            child: Text(
                              "You haven't claimed any leads yet.",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                          : filtered.isEmpty
                          ? Center(
                            child: Text(
                              'No leads match "${_searchCtrl.text}".',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                          : RefreshIndicator(
                            onRefresh: prov.fetchMyLeads,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: filtered.length,
                              itemBuilder:
                                  (_, i) => _MyLeadCard(lead: filtered[i]),
                            ),
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MyLeadCard extends StatefulWidget {
  final TelecallerLeadModel lead;
  const _MyLeadCard({required this.lead});

  @override
  State<_MyLeadCard> createState() => _MyLeadCardState();
}

class _MyLeadCardState extends State<_MyLeadCard> {
  bool _releasing = false;

  String? _formatDate(String? iso) {
    if (iso == null) return null;
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return null;
    return DateFormat('dd MMM yyyy').format(parsed.toLocal());
  }

  Future<void> _release() async {
    setState(() => _releasing = true);
    final ok = await context.read<TelecallerProvider>().release(widget.lead.id);
    if (!mounted) return;
    setState(() => _releasing = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not release this lead.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            () => showLeadCallHistorySheet(
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.history, size: 16, color: Colors.grey[500]),
                ],
              ),
              LeadSourceLine(lead: lead),
              if (_formatDate(lead.createdAt) != null ||
                  _formatDate(lead.claimedAt) != null) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 2,
                  children: [
                    if (_formatDate(lead.createdAt) != null)
                      _DateInfo(
                        icon: Icons.hourglass_empty,
                        label: 'Pending since ${_formatDate(lead.createdAt)}',
                      ),
                    if (_formatDate(lead.claimedAt) != null)
                      _DateInfo(
                        icon: Icons.call_made,
                        label: 'Claimed on ${_formatDate(lead.claimedAt)}',
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => launchDialer(lead.contact),
                      icon: const Icon(Icons.call_outlined, size: 15),
                      label: Text(
                        lead.contact,
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _releasing ? null : _release,
                    icon:
                        _releasing
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.undo, size: 20),
                    tooltip: 'Release back to pool',
                    color: Colors.grey[600],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => showCallOutcomeSheet(context, lead),
                  icon: const Icon(Icons.edit_note, size: 17),
                  label: const Text(
                    'Log Call Outcome',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
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

class _DateInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DateInfo({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey[500]),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}
