import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/lead_project_details_model.dart';

/// The shared "Project Details" questionnaire — collapsed by default since
/// every field is optional — used by both the Area Manager's call-outcome
/// sheet and the Lead Manager's field-visit report sheet. Fires [onChanged]
/// with only the fields the user actually touched, matching the backend's
/// partial-upsert semantics (an empty field here means "leave it as is,"
/// not "clear it").
class ProjectDetailsForm extends StatefulWidget {
  final LeadProjectDetailsModel? initial;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const ProjectDetailsForm({super.key, this.initial, required this.onChanged});

  @override
  State<ProjectDetailsForm> createState() => _ProjectDetailsFormState();
}

class _ProjectDetailsFormState extends State<ProjectDetailsForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _numberCtrl;
  late final TextEditingController _mapUrlCtrl;
  late final TextEditingController _googleReviewCtrl;
  late final TextEditingController _facebookReviewCtrl;
  late final TextEditingController _instagramReviewCtrl;
  late final TextEditingController _advanceReceivedCtrl;
  late final TextEditingController _balanceNotesCtrl;

  late Set<String> _workStage;
  late Set<String> _interiorStage;
  String? _roomRequirement;
  DateTime? _workStartDate;
  DateTime? _workCompletionDate;
  int? _progressPercent;
  String? _siteVisitFrequency;
  int? _workStartingWindowDays;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _nameCtrl = TextEditingController(text: d?.projectName);
    _numberCtrl = TextEditingController(text: d?.projectNumber);
    _mapUrlCtrl = TextEditingController(text: d?.locationMapUrl);
    _googleReviewCtrl = TextEditingController(text: d?.googleReviewUrl);
    _facebookReviewCtrl = TextEditingController(text: d?.facebookReviewUrl);
    _instagramReviewCtrl = TextEditingController(text: d?.instagramReviewUrl);
    _advanceReceivedCtrl = TextEditingController(text: d?.advanceReceived?.toStringAsFixed(0));
    _balanceNotesCtrl = TextEditingController(text: d?.balancePaymentNotes);
    _workStage = {...(d?.workStage ?? const [])};
    _interiorStage = {...(d?.interiorStage ?? const [])};
    _roomRequirement = d?.roomRequirement;
    _workStartDate = d?.workStartDate != null ? DateTime.tryParse(d!.workStartDate!) : null;
    _workCompletionDate = d?.workCompletionDate != null ? DateTime.tryParse(d!.workCompletionDate!) : null;
    _progressPercent = d?.progressPercent;
    _siteVisitFrequency = d?.siteVisitFrequency;
    _workStartingWindowDays = d?.workStartingWindowDays;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    _mapUrlCtrl.dispose();
    _googleReviewCtrl.dispose();
    _facebookReviewCtrl.dispose();
    _instagramReviewCtrl.dispose();
    _advanceReceivedCtrl.dispose();
    _balanceNotesCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged({
      if (_nameCtrl.text.trim().isNotEmpty) 'project_name': _nameCtrl.text.trim(),
      if (_numberCtrl.text.trim().isNotEmpty) 'project_number': _numberCtrl.text.trim(),
      if (_mapUrlCtrl.text.trim().isNotEmpty) 'location_map_url': _mapUrlCtrl.text.trim(),
      if (_workStage.isNotEmpty) 'work_stage': _workStage.toList(),
      if (_interiorStage.isNotEmpty) 'interior_stage': _interiorStage.toList(),
      if (_roomRequirement != null) 'room_requirement': _roomRequirement,
      if (_workStartDate != null) 'work_start_date': DateFormat('yyyy-MM-dd').format(_workStartDate!),
      if (_workCompletionDate != null) 'work_completion_date': DateFormat('yyyy-MM-dd').format(_workCompletionDate!),
      if (_progressPercent != null) 'progress_percent': _progressPercent,
      if (_googleReviewCtrl.text.trim().isNotEmpty) 'google_review_url': _googleReviewCtrl.text.trim(),
      if (_facebookReviewCtrl.text.trim().isNotEmpty) 'facebook_review_url': _facebookReviewCtrl.text.trim(),
      if (_instagramReviewCtrl.text.trim().isNotEmpty) 'instagram_review_url': _instagramReviewCtrl.text.trim(),
      if (_siteVisitFrequency != null) 'site_visit_frequency': _siteVisitFrequency,
      if (_workStartingWindowDays != null) 'work_starting_window_days': _workStartingWindowDays,
      if (_advanceReceivedCtrl.text.trim().isNotEmpty)
        'advance_received': double.tryParse(_advanceReceivedCtrl.text.trim()),
      if (_balanceNotesCtrl.text.trim().isNotEmpty) 'balance_payment_notes': _balanceNotesCtrl.text.trim(),
    });
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _workStartDate : _workCompletionDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _workStartDate = picked;
      } else {
        _workCompletionDate = picked;
      }
    });
    _emit();
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 12),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
      );

  Widget _chipGroup<T>({
    required List<(T, String)> options,
    required T? selected,
    required ValueChanged<T> onSelect,
  }) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((o) {
        final (value, label) = o;
        final isSelected = selected == value;
        return ChoiceChip(
          label: Text(label, style: const TextStyle(fontSize: 12)),
          selected: isSelected,
          onSelected: (_) {
            setState(() => onSelect(value));
            _emit();
          },
          selectedColor: theme.colorScheme.primary,
          labelStyle: TextStyle(color: isSelected ? theme.colorScheme.onPrimary : null),
        );
      }).toList(),
    );
  }

  Widget _multiChipGroup(List<(String, String)> options, Set<String> selectedSet) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((o) {
        final (value, label) = o;
        final isSelected = selectedSet.contains(value);
        return FilterChip(
          label: Text(label, style: const TextStyle(fontSize: 12)),
          selected: isSelected,
          onSelected: (_) {
            setState(() => isSelected ? selectedSet.remove(value) : selectedSet.add(value));
            _emit();
          },
          selectedColor: theme.colorScheme.primary,
          labelStyle: TextStyle(color: isSelected ? theme.colorScheme.onPrimary : null),
        );
      }).toList(),
    );
  }

  Widget _textField(TextEditingController ctrl, String label, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: (_) => _emit(),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('Project Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
        subtitle: Text('Optional — fill in whatever you know', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        children: [
          _textField(_nameCtrl, 'Project Name'),
          const SizedBox(height: 10),
          _textField(_numberCtrl, 'Project No.'),
          const SizedBox(height: 10),
          _textField(_mapUrlCtrl, 'Location (Google Maps link)'),

          _label('Room Requirement'),
          _chipGroup(
            options: ProjectDetailsOptions.roomRequirement,
            selected: _roomRequirement,
            onSelect: (v) => _roomRequirement = v,
          ),

          _label('Work Stage'),
          _multiChipGroup(ProjectDetailsOptions.workStage, _workStage),

          _label('Interior Stage'),
          _multiChipGroup(ProjectDetailsOptions.interiorStage, _interiorStage),

          _label('Progress'),
          _chipGroup<int>(
            options: ProjectDetailsOptions.progressPercent.map((p) => (p, '$p%')).toList(),
            selected: _progressPercent,
            onSelect: (v) => _progressPercent = v,
          ),

          _label('Work Dates'),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(true),
                icon: const Icon(Icons.event, size: 15),
                label: Text(_workStartDate == null ? 'Start Date' : DateFormat('dd MMM yyyy').format(_workStartDate!),
                    style: const TextStyle(fontSize: 11.5)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(false),
                icon: const Icon(Icons.event_available, size: 15),
                label: Text(
                    _workCompletionDate == null ? 'Completion Date' : DateFormat('dd MMM yyyy').format(_workCompletionDate!),
                    style: const TextStyle(fontSize: 11.5)),
              ),
            ),
          ]),

          _label('Site Visit Frequency'),
          _chipGroup(
            options: ProjectDetailsOptions.siteVisitFrequency,
            selected: _siteVisitFrequency,
            onSelect: (v) => _siteVisitFrequency = v,
          ),

          _label('Work Starting Window'),
          _chipGroup<int>(
            options: ProjectDetailsOptions.workStartingWindowDays.map((d) => (d, '$d days')).toList(),
            selected: _workStartingWindowDays,
            onSelect: (v) => _workStartingWindowDays = v,
          ),

          _label('Payment'),
          _textField(_advanceReceivedCtrl, 'Advance Received (₹)', keyboardType: TextInputType.number),
          const SizedBox(height: 10),
          _textField(_balanceNotesCtrl, 'Balance Payment Notes (e.g. 3-step schedule)', maxLines: 2),

          _label('Client Reviews'),
          _textField(_googleReviewCtrl, 'Google Review URL'),
          const SizedBox(height: 10),
          _textField(_facebookReviewCtrl, 'Facebook Review URL'),
          const SizedBox(height: 10),
          _textField(_instagramReviewCtrl, 'Instagram Review URL'),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
