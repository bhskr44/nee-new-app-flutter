import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/lead_project_details_model.dart';
import '../services/api_service.dart';
import '../widgets/voice_memo_recorder.dart';
import 'my_estimate_requests_screen.dart';

const _timelineOptions = [
  'Immediately',
  '1–3 months',
  '3–6 months',
  '6–12 months',
  'Not sure yet',
];

/// A buyer's request for a full construction-project estimate — a
/// systematic brief (project type, plot size, floors, room requirement,
/// budget, location, timeline) plus free-text notes and an optional voice
/// memo. Emailed to admin and reminded daily until closed (see
/// SendBuildingEstimateReminders on the backend).
class RequestEstimateScreen extends StatefulWidget {
  const RequestEstimateScreen({super.key});

  @override
  State<RequestEstimateScreen> createState() => _RequestEstimateScreenState();
}

const _otherProjectType = 'Other';

class _RequestEstimateScreenState extends State<RequestEstimateScreen> {
  String? _projectType;
  final _projectTypeOtherCtrl = TextEditingController();
  final _plotSizeCtrl = TextEditingController();
  final _floorsCtrl = TextEditingController();
  String? _roomRequirement;
  final _budgetMinCtrl = TextEditingController();
  final _budgetMaxCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String? _timeline;
  final _notesCtrl = TextEditingController();
  String? _voiceMemoPath;
  bool _submitting = false;

  @override
  void dispose() {
    _projectTypeOtherCtrl.dispose();
    _plotSizeCtrl.dispose();
    _floorsCtrl.dispose();
    _budgetMinCtrl.dispose();
    _budgetMaxCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  /// The project type actually meant, resolving "Other" to whatever the
  /// buyer typed in the follow-up text field instead of the literal word.
  String? get _resolvedProjectType {
    if (_projectType == _otherProjectType) {
      final custom = _projectTypeOtherCtrl.text.trim();
      return custom.isEmpty ? null : custom;
    }
    return _projectType;
  }

  bool get _hasAnyInput =>
      _resolvedProjectType != null ||
      _plotSizeCtrl.text.trim().isNotEmpty ||
      _floorsCtrl.text.trim().isNotEmpty ||
      _roomRequirement != null ||
      _budgetMinCtrl.text.trim().isNotEmpty ||
      _budgetMaxCtrl.text.trim().isNotEmpty ||
      _locationCtrl.text.trim().isNotEmpty ||
      _timeline != null ||
      _notesCtrl.text.trim().isNotEmpty ||
      _voiceMemoPath != null;

  Future<void> _submit() async {
    if (!_hasAnyInput) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one detail about what you want to build.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await apiService.submitEstimateRequest(
        {
          if (_resolvedProjectType != null) 'project_type': _resolvedProjectType,
          if (_plotSizeCtrl.text.trim().isNotEmpty) 'plot_size_sqft': int.tryParse(_plotSizeCtrl.text.trim()),
          if (_floorsCtrl.text.trim().isNotEmpty) 'floors': int.tryParse(_floorsCtrl.text.trim()),
          if (_roomRequirement != null) 'room_requirement': _roomRequirement,
          if (_budgetMinCtrl.text.trim().isNotEmpty) 'budget_min': int.tryParse(_budgetMinCtrl.text.trim()),
          if (_budgetMaxCtrl.text.trim().isNotEmpty) 'budget_max': int.tryParse(_budgetMaxCtrl.text.trim()),
          if (_locationCtrl.text.trim().isNotEmpty) 'location': _locationCtrl.text.trim(),
          if (_timeline != null) 'timeline': _timeline,
          if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
        },
        voiceMemoPath: _voiceMemoPath,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Request submitted! Our team will get back to you soon."),
          backgroundColor: Color(0xFF2E7D32),
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit your request. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request an Estimate'),
        actions: [
          IconButton(
            tooltip: 'My past requests',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyEstimateRequestsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tell us about the building you want to construct',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Fill in what you know — every field is optional. Our team will follow up with a detailed estimate.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            _label('Project Type'),
            DropdownButtonFormField<String>(
              initialValue: _projectType,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true, hintText: 'Select project type'),
              items: [
                ...AppConstants.projectTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                const DropdownMenuItem(value: _otherProjectType, child: Text('Other')),
              ],
              onChanged: (v) => setState(() {
                _projectType = v;
                if (v == _otherProjectType) {
                  // These fields are hidden for "Other" — clear them so a
                  // value picked before switching can't be silently submitted.
                  _plotSizeCtrl.clear();
                  _floorsCtrl.clear();
                  _roomRequirement = null;
                  _budgetMinCtrl.clear();
                  _budgetMaxCtrl.clear();
                }
              }),
            ),
            if (_projectType == _otherProjectType) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _projectTypeOtherCtrl,
                decoration: const InputDecoration(isDense: true, hintText: 'Describe the project type'),
              ),
            ],
            const SizedBox(height: 14),

            // Plot size / floors / BHK / budget are residential-home concepts
            // that don't apply once the project type isn't one of the preset
            // categories — skip them rather than ask for numbers that don't
            // mean anything for e.g. a boundary wall or a warehouse.
            if (_projectType != _otherProjectType) ...[
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Plot Size (sqft)'),
                    TextField(
                      controller: _plotSizeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(isDense: true, hintText: 'e.g. 1200'),
                    ),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Floors'),
                    TextField(
                      controller: _floorsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(isDense: true, hintText: 'e.g. 2'),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 14),

              _label('Room Requirement'),
              Wrap(
                spacing: 8,
                children: ProjectDetailsOptions.roomRequirement.map((r) {
                  final (value, label) = r;
                  final selected = _roomRequirement == value;
                  return ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => setState(() => _roomRequirement = selected ? null : value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              _label('Budget Range (₹)'),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _budgetMinCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true, hintText: 'Min'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _budgetMaxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true, hintText: 'Max'),
                  ),
                ),
              ]),
            ],
            const SizedBox(height: 14),

            _label('Location'),
            TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(isDense: true, hintText: 'e.g. Guwahati, Assam'),
            ),
            const SizedBox(height: 14),

            _label('Target Start Timeline'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timelineOptions.map((t) {
                final selected = _timeline == t;
                return ChoiceChip(
                  label: Text(t),
                  selected: selected,
                  onSelected: (_) => setState(() => _timeline = selected ? null : t),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            _label('Anything else? (optional)'),
            TextField(
              controller: _notesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Write your own thoughts — anything exceptional or specific you have in mind.',
              ),
            ),
            const SizedBox(height: 14),

            _label('Voice Memo (optional)'),
            VoiceMemoRecorder(onChanged: (path) => setState(() => _voiceMemoPath = path)),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
