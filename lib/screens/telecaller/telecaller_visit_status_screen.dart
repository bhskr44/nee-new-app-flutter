import '../../widgets/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/field_visit_model.dart';
import '../../providers/telecaller_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/field_visit_report_card.dart';
import 'lead_call_history_sheet.dart';
import 'telecaller_pool_screen.dart' show launchDialer;

/// Lets an Area Manager track what happened to the field visits they've
/// scheduled/assigned — waiting on the Lead Manager to accept, accepted and
/// awaiting the site visit, declined and needing reassignment, or completed
/// with the inspection outcome.
class TelecallerVisitStatusScreen extends StatefulWidget {
  const TelecallerVisitStatusScreen({super.key});

  @override
  State<TelecallerVisitStatusScreen> createState() =>
      _TelecallerVisitStatusScreenState();
}

class _TelecallerVisitStatusScreenState
    extends State<TelecallerVisitStatusScreen> {
  List<FieldVisitModel> _visits = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchCtrl.addListener(
      () => setState(() => _query = _searchCtrl.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await apiService.getMyScheduledFieldVisits();
      setState(() {
        _visits =
            (data['data'] as List)
                .map((e) => FieldVisitModel.fromJson(e))
                .toList();
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Could not load field visit status. Pull down to retry.';
      });
    }
  }

  /// Matches against the lead name, the assigned/accepted lead manager's
  /// name, and the scheduled date (raw or friendly-formatted).
  bool _matches(FieldVisitModel v) {
    if (_query.isEmpty) return true;
    if (v.leadTitle.toLowerCase().contains(_query)) return true;
    if ((v.assignedLeadManagerName ?? '').toLowerCase().contains(_query)) {
      return true;
    }
    if ((v.acceptedByName ?? '').toLowerCase().contains(_query)) return true;
    if (v.scheduledDate.toLowerCase().contains(_query)) return true;
    final parsed = DateTime.tryParse(v.scheduledDate);
    if (parsed != null &&
        DateFormat(
          'dd MMM yyyy',
        ).format(parsed).toLowerCase().contains(_query)) {
      return true;
    }
    return false;
  }

  List<FieldVisitModel> get _filtered => _visits.where(_matches).toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
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
                    'Field Visit Status',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by lead, lead manager, or date...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? AppEmptyState(
                        icon: Icons.cloud_off_outlined,
                        title: 'Could not load this list',
                        message: 'Check your connection and try again.',
                        actionLabel: 'Try again',
                        onAction: _fetch,
                      )
                      : _visits.isEmpty
                      ? Center(
                        child: Text(
                          "You haven't scheduled any field visits yet.",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                      : filtered.isEmpty
                      ? Center(
                        child: Text(
                          'No visits match "${_searchCtrl.text}".',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: _fetch,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: filtered.length,
                          itemBuilder:
                              (_, i) => _ScheduledVisitCard(
                                visit: filtered[i],
                                onChanged: _fetch,
                              ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduledVisitCard extends StatefulWidget {
  final FieldVisitModel visit;
  final VoidCallback onChanged;
  const _ScheduledVisitCard({required this.visit, required this.onChanged});

  @override
  State<_ScheduledVisitCard> createState() => _ScheduledVisitCardState();
}

class _ScheduledVisitCardState extends State<_ScheduledVisitCard> {
  static const _statusColors = {
    'pending': Color(0xFFF9A825),
    'accepted': Color(0xFF6A1B9A),
    'declined': Color(0xFFC62828),
    'completed': Color(0xFF2E7D32),
    'cancelled': Color(0xFF757575),
  };

  static const _statusLabels = {
    'pending': 'Waiting for acceptance',
    'accepted': 'Accepted — visit pending',
    'declined': 'Declined — needs reassignment',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
  };

  bool _reassigning = false;
  bool _calling = false;

  /// Re-claims the lead (even though it already has a field visit attached —
  /// scheduling a visit doesn't mean the conversation with the client is
  /// over) and dials it, same as the pool/"My Leads" flow. The outcome gets
  /// logged from "My Leads" after the call, once it lands there.
  Future<void> _callAgain() async {
    setState(() => _calling = true);
    final error = await context.read<TelecallerProvider>().claim(
      widget.visit.leadId,
    );

    if (!mounted) return;
    setState(() => _calling = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.orange),
      );
      return;
    }

    final contact = widget.visit.leadContact;
    if (contact != null && contact.isNotEmpty) {
      await launchDialer(contact);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Lead moved to My Leads — log what you found out after the call.',
        ),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  Future<void> _reassignFlow() async {
    List<dynamic> leadManagers;
    try {
      leadManagers = await apiService.getLeadManagers();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load lead managers. Try again.'),
        ),
      );
      return;
    }
    if (!mounted) return;

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            expand: false,
            builder:
                (ctx, scrollController) => Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Reassign to...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child:
                          leadManagers.isEmpty
                              ? Center(
                                child: Text(
                                  'No lead managers available.',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              )
                              : ListView.builder(
                                controller: scrollController,
                                itemCount: leadManagers.length,
                                itemBuilder: (_, i) {
                                  final lm =
                                      leadManagers[i] as Map<String, dynamic>;
                                  final active = lm['active_visits'] ?? 0;
                                  return ListTile(
                                    leading: const CircleAvatar(
                                      child: Icon(Icons.person_outline),
                                    ),
                                    title: Text(lm['name'] ?? ''),
                                    subtitle: Text(
                                      active == 0
                                          ? 'No active visits'
                                          : '$active active visit${active == 1 ? '' : 's'}',
                                    ),
                                    onTap: () => Navigator.pop(ctx, lm),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
          ),
    );

    if (selected == null || !mounted) return;

    setState(() => _reassigning = true);
    try {
      await apiService.reassignFieldVisit(
        widget.visit.id,
        selected['id'] as int,
      );
      widget.onChanged();
    } on Exception catch (_) {
      if (!mounted) return;
      setState(() => _reassigning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reassign this visit.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visit = widget.visit;
    final color = _statusColors[visit.status] ?? Colors.grey;
    final label = _statusLabels[visit.status] ?? visit.status.toUpperCase();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            () => showLeadCallHistorySheet(
              context,
              leadId: visit.leadId,
              leadTitle: visit.leadTitle,
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
                      visit.leadTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.history, size: 15, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 13, color: Colors.grey),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      visit.leadLocation,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                  const Icon(Icons.event, size: 13, color: Colors.grey),
                  const SizedBox(width: 2),
                  Text(
                    visit.scheduledDate,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _calling ? null : _callAgain,
                  icon:
                      _calling
                          ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.call_outlined, size: 16),
                  label: Text(
                    _calling ? 'Calling...' : 'Call Lead Again',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              if (visit.assignedLeadManagerName != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 13,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      visit.isDeclined
                          ? 'Declined by: ${visit.assignedLeadManagerName}'
                          : 'Assigned to: ${visit.assignedLeadManagerName}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ],
                ),
              ],
              if (visit.status != 'pending' &&
                  visit.status != 'declined' &&
                  visit.acceptedByName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 13,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Accepted by: ${visit.acceptedByName}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ],
                ),
              ],
              if (visit.isDeclined) ...[
                const Divider(height: 20),
                if (visit.declineReason != null &&
                    visit.declineReason!.isNotEmpty) ...[
                  Text(
                    'Reason: ${visit.declineReason}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _reassigning ? null : _reassignFlow,
                    icon:
                        _reassigning
                            ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.swap_horiz, size: 17),
                    label: Text(
                      _reassigning
                          ? 'Reassigning...'
                          : 'Reassign to Someone Else',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
              if (visit.isCompleted) ...[
                const Divider(height: 20),
                FieldVisitReportCard(visit: visit),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
