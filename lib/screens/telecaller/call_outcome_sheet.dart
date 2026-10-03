import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/telecaller_lead_model.dart';
import '../../providers/telecaller_provider.dart';
import '../../widgets/project_details_form.dart';
import 'lead_call_history_sheet.dart';

const _statusOptions = [
  (
    value: 'hot',
    label: 'Hot',
    hint: 'Urgent — wants it within 15 days to a month',
    color: Color(0xFFD32F2F),
  ),
  (
    value: 'cold',
    label: 'Cold',
    hint: 'Interested, but more than a month out',
    color: Color(0xFF1565C0),
  ),
  (
    value: 'callback',
    label: 'Call Again',
    hint: "Didn't get a decision — no answer, asked to call back, etc.",
    color: Color(0xFFEF6C00),
  ),
  (
    value: 'archive',
    label: 'Archive',
    hint: "Not interested right now",
    color: Color(0xFF757575),
  ),
  (
    value: 'closed',
    label: 'Closed',
    hint: 'Already completed the order',
    color: Color(0xFF2E7D32),
  ),
];

/// Bottom sheet for logging a call outcome — status first, then (for hot/cold
/// leads) an optional field-visit offer. Returns true if the outcome was saved.
Future<bool?> showCallOutcomeSheet(
  BuildContext context,
  TelecallerLeadModel lead,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _CallOutcomeSheet(lead: lead),
  );
}

class _CallOutcomeSheet extends StatefulWidget {
  final TelecallerLeadModel lead;
  const _CallOutcomeSheet({required this.lead});

  @override
  State<_CallOutcomeSheet> createState() => _CallOutcomeSheetState();
}

class _CallOutcomeSheetState extends State<_CallOutcomeSheet> {
  String? _status;
  DateTime? _followUpDate;
  bool _submitting = false;
  bool _outcomeSaved = false;
  Map<String, dynamic> _projectDetailsData = {};
  final _commentCtrl = TextEditingController();
  LeadCallHistoryResult? _history;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await context.read<TelecallerProvider>().fetchHistory(
        widget.lead.id,
      );
      if (!mounted) return;
      setState(() {
        _history = history;
        _loadingHistory = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child:
            _outcomeSaved
                ? _FieldVisitStep(
                  lead: widget.lead,
                  onDone: () => Navigator.pop(context, true),
                )
                : _buildOutcomeStep(),
      ),
    );
  }

  Future<void> _pickFollowUpDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _followUpDate = picked);
  }

  Future<void> _submit() async {
    if (_status == null) return;
    if (_status == 'callback' && _followUpDate == null) return;
    setState(() => _submitting = true);

    final ok = await context.read<TelecallerProvider>().submitCallLog(
      widget.lead.id,
      status: _status!,
      nextFollowUpAt:
          _followUpDate == null
              ? null
              : DateFormat('yyyy-MM-dd').format(_followUpDate!),
      comment:
          _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
      projectDetails: _projectDetailsData.isEmpty ? null : _projectDetailsData,
    );

    if (!mounted) return;
    if (ok) {
      if (_status == 'hot' || _status == 'cold') {
        setState(() {
          _outcomeSaved = true;
          _submitting = false;
        });
      } else {
        Navigator.pop(context, true);
      }
    } else {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the call outcome. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildOutcomeStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.lead.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (_loadingHistory) ...[
          const SizedBox(height: 14),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ] else if (_history != null &&
            (_history!.logs.isNotEmpty ||
                _history!.projectDetails != null)) ...[
          const SizedBox(height: 14),
          if (_history!.projectDetails != null) ...[
            ProjectDetailsSummary(details: _history!.projectDetails!),
            if (_history!.logs.isNotEmpty) const SizedBox(height: 10),
          ],
          if (_history!.logs.isNotEmpty)
            PreviousCallsPanel(logs: _history!.logs),
        ],
        const SizedBox(height: 18),
        const Text(
          'Status',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        ..._statusOptions.map((o) {
          final selected = _status == o.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap:
                  () => setState(() {
                    _status = o.value;
                    if (o.value != 'callback') _followUpDate = null;
                  }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? o.color : Colors.grey[300]!,
                    width: selected ? 1.5 : 1,
                  ),
                  color: selected ? o.color.withAlpha(15) : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: selected ? o.color : Colors.grey[400],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: o.color,
                              fontSize: 13.5,
                            ),
                          ),
                          Text(
                            o.hint,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        if (_status == 'callback') ...[
          const SizedBox(height: 4),
          const Text(
            'Call back on',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickFollowUpDate,
            icon: const Icon(Icons.event, size: 18),
            label: Text(
              _followUpDate == null
                  ? 'Pick a date'
                  : DateFormat('dd MMM yyyy').format(_followUpDate!),
            ),
          ),
        ],
        const SizedBox(height: 10),
        const Text(
          'Notes',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _commentCtrl,
          maxLines: 3,
          maxLength: 1000,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText:
                'What did the client say? Any details worth remembering...',
          ),
        ),
        ProjectDetailsForm(
          initial: widget.lead.projectDetails,
          onChanged: (data) => _projectDetailsData = data,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                (_status == null ||
                        _submitting ||
                        (_status == 'callback' && _followUpDate == null))
                    ? null
                    : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            child:
                _submitting
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Text('Save Outcome'),
          ),
        ),
      ],
    );
  }
}

/// Second step, shown only after a hot/cold outcome is saved: optionally offer
/// a field visit, either open to any lead manager or assigned to one specific person.
class _FieldVisitStep extends StatefulWidget {
  final TelecallerLeadModel lead;
  final VoidCallback onDone;
  const _FieldVisitStep({required this.lead, required this.onDone});

  @override
  State<_FieldVisitStep> createState() => _FieldVisitStepState();
}

class _FieldVisitStepState extends State<_FieldVisitStep> {
  DateTime? _scheduledDate;
  bool _assignSpecific = false;
  List<EligibleLeadManager>? _eligible;
  bool _loadingEligible = false;
  int? _selectedLeadManagerId;
  bool _submitting = false;
  String? _error;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  Future<void> _toggleAssignSpecific(bool value) async {
    setState(() {
      _assignSpecific = value;
      _selectedLeadManagerId = null;
    });
    if (value && _eligible == null) {
      setState(() => _loadingEligible = true);
      try {
        final list = await context
            .read<TelecallerProvider>()
            .fetchEligibleLeadManagers(widget.lead.id);
        if (!mounted) return;
        setState(() {
          _eligible = list;
          _loadingEligible = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _loadingEligible = false);
      }
    }
  }

  Future<void> _schedule() async {
    if (_scheduledDate == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final dateStr = DateFormat('yyyy-MM-dd').format(_scheduledDate!);
    final error = await context.read<TelecallerProvider>().scheduleFieldVisit(
      widget.lead.id,
      dateStr,
      leadManagerId: _assignSpecific ? _selectedLeadManagerId : null,
    );

    if (!mounted) return;
    if (error == null) {
      widget.onDone();
    } else {
      setState(() {
        _submitting = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSchedule =
        _scheduledDate != null &&
        (!_assignSpecific || _selectedLeadManagerId != null);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Outcome saved',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Schedule a field visit? (optional)',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _pickDate,
          icon: const Icon(Icons.event, size: 18),
          label: Text(
            _scheduledDate == null
                ? 'Pick a date'
                : DateFormat('dd MMM yyyy').format(_scheduledDate!),
          ),
        ),
        if (_scheduledDate != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Open to anyone'),
                  selected: !_assignSpecific,
                  onSelected: (_) => _toggleAssignSpecific(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Assign a Lead Manager'),
                  selected: _assignSpecific,
                  onSelected: (_) => _toggleAssignSpecific(true),
                ),
              ),
            ],
          ),
          if (_assignSpecific) ...[
            const SizedBox(height: 10),
            if (_loadingEligible)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_eligible == null || _eligible!.isEmpty)
              Text(
                'No lead managers available.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12.5),
              )
            else
              ..._eligible!.map((lm) {
                final selected = _selectedLeadManagerId == lm.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _selectedLeadManagerId = lm.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              selected
                                  ? const Color(0xFF6A1B9A)
                                  : Colors.grey[300]!,
                        ),
                        color:
                            selected
                                ? const Color(0xFF6A1B9A).withAlpha(15)
                                : null,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            size: 16,
                            color:
                                selected
                                    ? const Color(0xFF6A1B9A)
                                    : Colors.grey[400],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lm.name,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                if (lm.address != null && lm.address!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.place_outlined, size: 12, color: Colors.grey[500]),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          lm.address!,
                                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (lm.districtMatch)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'District match',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 12.5),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _submitting ? null : widget.onDone,
                child: const Text('Skip'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: (!canSchedule || _submitting) ? null : _schedule,
                child:
                    _submitting
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text('Schedule Visit'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
