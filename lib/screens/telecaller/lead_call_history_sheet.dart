import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/lead_project_details_model.dart';
import '../../models/telecaller_lead_model.dart';
import '../../providers/telecaller_provider.dart';
import '../../widgets/field_visit_report_card.dart';

const _statusColors = {
  'hot': Color(0xFFD32F2F),
  'cold': Color(0xFF1565C0),
  'callback': Color(0xFFEF6C00),
  'archive': Color(0xFF757575),
  'closed': Color(0xFF2E7D32),
};

/// Opens a bottom sheet with everything an Area Manager has found out about a
/// lead over the phone — every previous call log, plus the shared
/// project-details questionnaire (filled in by an Area Manager's call or a
/// Lead Manager's site visit). Viewable by both roles.
void showLeadCallHistorySheet(BuildContext context, {required int leadId, required String leadTitle}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _LeadCallHistorySheetContent(leadId: leadId, leadTitle: leadTitle),
  );
}

class _LeadCallHistorySheetContent extends StatefulWidget {
  final int leadId;
  final String leadTitle;
  const _LeadCallHistorySheetContent({required this.leadId, required this.leadTitle});

  @override
  State<_LeadCallHistorySheetContent> createState() => _LeadCallHistorySheetContentState();
}

class _LeadCallHistorySheetContentState extends State<_LeadCallHistorySheetContent> {
  LeadCallHistoryResult? _result;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await context.read<TelecallerProvider>().fetchHistory(widget.leadId);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load call history. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final logs = result?.logs ?? const [];
    final projectDetails = result?.projectDetails;
    final fieldVisitReports = result?.fieldVisitReports ?? const [];
    final hasLogs = logs.isNotEmpty;
    final hasProjectDetails = projectDetails != null;
    final hasFieldVisitReports = fieldVisitReports.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.leadTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          const Text('Call History', style: TextStyle(fontSize: 12.5, color: Colors.black54)),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            )
          else if (!hasLogs && !hasProjectDetails && !hasFieldVisitReports)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('No previous calls logged for this lead yet.',
                    style: TextStyle(color: Colors.grey[600])),
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasProjectDetails) ...[
                      ProjectDetailsSummary(details: projectDetails),
                      if (hasLogs || hasFieldVisitReports) const SizedBox(height: 12),
                    ],
                    if (hasFieldVisitReports) ...[
                      Row(children: [
                        const Icon(Icons.fact_check_outlined, size: 15, color: Colors.black54),
                        const SizedBox(width: 6),
                        Text('Field Visit Reports (${fieldVisitReports.length})',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                      ]),
                      const SizedBox(height: 8),
                      ...fieldVisitReports.map((v) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: FieldVisitReportCard(visit: v),
                          )),
                      if (hasLogs) const SizedBox(height: 4),
                    ],
                    if (hasLogs) PreviousCallsPanel(logs: logs),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Renders a list of previous call log entries — status badge, who called and
/// when, and their notes.
class PreviousCallsPanel extends StatelessWidget {
  final List<TelecallerCallLog> logs;
  const PreviousCallsPanel({super.key, required this.logs});

  Color _colorFor(String status) => _statusColors[status] ?? Colors.grey;

  String _formatDate(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return DateFormat('dd MMM, hh:mm a').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.history, size: 15, color: Colors.black54),
            const SizedBox(width: 6),
            Text('Previous Calls (${logs.length})',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
          ]),
          const SizedBox(height: 8),
          ...logs.map((log) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _colorFor(log.status).withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(log.status.toUpperCase(),
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: _colorFor(log.status))),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          [
                            if (log.telecallerName != null) log.telecallerName!,
                            _formatDate(log.createdAt),
                          ].join(' — '),
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                    if (log.comment != null && log.comment!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(log.comment!, style: const TextStyle(fontSize: 12.5)),
                    ],
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

/// Renders the shared project-details questionnaire, read-only — only the
/// fields someone has actually filled in.
class ProjectDetailsSummary extends StatelessWidget {
  final LeadProjectDetailsModel details;
  const ProjectDetailsSummary({super.key, required this.details});

  List<MapEntry<String, String>> _rows() {
    String labelFor(List<(String, String)> options, String value) =>
        options.firstWhere((o) => o.$1 == value, orElse: () => (value, value)).$2;

    final rows = <MapEntry<String, String>>[];
    void add(String label, String? value) {
      if (value != null && value.isNotEmpty) rows.add(MapEntry(label, value));
    }

    add('Project Name', details.projectName);
    add('Project Number', details.projectNumber);
    add('Location / Map', details.locationMapUrl);
    add('Room Requirement',
        details.roomRequirement == null ? null : labelFor(ProjectDetailsOptions.roomRequirement, details.roomRequirement!));
    add(
      'Work Stage',
      details.workStage.isEmpty
          ? null
          : details.workStage.map((v) => labelFor(ProjectDetailsOptions.workStage, v)).join(', '),
    );
    add(
      'Interior Stage',
      details.interiorStage.isEmpty
          ? null
          : details.interiorStage.map((v) => labelFor(ProjectDetailsOptions.interiorStage, v)).join(', '),
    );
    add('Work Start Date', details.workStartDate);
    add('Work Completion Date', details.workCompletionDate);
    add('Progress', details.progressPercent == null ? null : '${details.progressPercent}%');
    add(
      'Site Visit Frequency',
      details.siteVisitFrequency == null
          ? null
          : labelFor(ProjectDetailsOptions.siteVisitFrequency, details.siteVisitFrequency!),
    );
    add('Work Starting Window', details.workStartingWindowDays == null ? null : '${details.workStartingWindowDays} days');
    add('Advance Received', details.advanceReceived == null ? null : '₹${details.advanceReceived}');
    add('Balance Payment Notes', details.balancePaymentNotes);
    add('Google Review', details.googleReviewUrl);
    add('Facebook Review', details.facebookReviewUrl);
    add('Instagram Review', details.instagramReviewUrl);

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows();
    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD8CEEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.assignment_outlined, size: 15, color: Color(0xFF6A1B9A)),
            SizedBox(width: 6),
            Text('Project Details',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF6A1B9A))),
          ]),
          const SizedBox(height: 8),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    children: [
                      TextSpan(text: '${r.key}: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                      TextSpan(text: r.value),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
