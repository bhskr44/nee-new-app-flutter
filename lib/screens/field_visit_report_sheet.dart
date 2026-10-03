import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/field_visit_model.dart';
import '../services/api_service.dart';
import '../widgets/project_details_form.dart';
import 'community/compose_post_screen.dart';

const _outcomeOptions = [
  (value: 'interested', label: 'Interested', color: Color(0xFF2E7D32)),
  (value: 'needs_follow_up', label: 'Needs Follow-up', color: Color(0xFFEF6C00)),
  (value: 'not_interested', label: 'Not Interested', color: Color(0xFFC62828)),
];

/// Bottom sheet for submitting the on-site visit report. Returns true if saved.
Future<bool?> showFieldVisitReportSheet(BuildContext context, FieldVisitModel visit) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _FieldVisitReportSheet(visit: visit),
  );
}

class _FieldVisitReportSheet extends StatefulWidget {
  final FieldVisitModel visit;
  const _FieldVisitReportSheet({required this.visit});

  @override
  State<_FieldVisitReportSheet> createState() => _FieldVisitReportSheetState();
}

class _FieldVisitReportSheetState extends State<_FieldVisitReportSheet> {
  String? _outcome;
  bool? _clientMet;
  bool? _decisionMakerPresent;
  final _budgetCtrl = TextEditingController();
  final _timelineCtrl = TextEditingController();
  final _commentsCtrl = TextEditingController();
  final _picker = ImagePicker();
  List<XFile> _photos = [];
  bool _submitting = false;
  bool _shareToCommunity = false;
  Map<String, dynamic> _projectDetailsData = {};

  @override
  void dispose() {
    _budgetCtrl.dispose();
    _timelineCtrl.dispose();
    _commentsCtrl.dispose();
    super.dispose();
  }

  Widget _yesNoToggle(String label, bool? value, ValueChanged<bool> onChanged) {
    return Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
      ChoiceChip(
        label: const Text('Yes'),
        selected: value == true,
        onSelected: (_) => onChanged(true),
        selectedColor: const Color(0xFF2E7D32),
        labelStyle: TextStyle(color: value == true ? Colors.white : null, fontSize: 12),
      ),
      const SizedBox(width: 6),
      ChoiceChip(
        label: const Text('No'),
        selected: value == false,
        onSelected: (_) => onChanged(false),
        selectedColor: Colors.red[400],
        labelStyle: TextStyle(color: value == false ? Colors.white : null, fontSize: 12),
      ),
    ]);
  }

  Future<void> _pickPhotos() async {
    final imgs = await _picker.pickMultiImage(imageQuality: 75);
    if (imgs.isNotEmpty) {
      setState(() => _photos = [..._photos, ...imgs].take(6).toList());
    }
  }

  Future<void> _submit() async {
    if (_outcome == null) return;
    setState(() => _submitting = true);

    try {
      await apiService.submitFieldVisitReport(
        widget.visit.id,
        {
          'outcome': _outcome,
          'comments': _commentsCtrl.text.trim(),
          if (_clientMet != null) 'client_met': _clientMet,
          if (_decisionMakerPresent != null) 'decision_maker_present': _decisionMakerPresent,
          if (_budgetCtrl.text.trim().isNotEmpty) 'budget_confirmed': double.tryParse(_budgetCtrl.text.trim()),
          if (_timelineCtrl.text.trim().isNotEmpty) 'timeline_confirmed': _timelineCtrl.text.trim(),
          ..._projectDetailsData,
        },
        photos: _photos.isEmpty ? null : _photos,
      );
      if (!mounted) return;

      final rootNavigator = Navigator.of(context, rootNavigator: true);
      Navigator.pop(context, true);
      if (_shareToCommunity && _photos.isNotEmpty) {
        rootNavigator.push(MaterialPageRoute(
          builder: (_) => ComposePostScreen(leadFieldVisitId: widget.visit.id, initialPhotos: _photos),
        ));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not submit the report. Try again.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Visit Report — ${widget.visit.leadTitle}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 18),
            const Text('Outcome', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: _outcomeOptions.map((o) {
              final selected = _outcome == o.value;
              return ChoiceChip(
                label: Text(o.label, style: const TextStyle(fontSize: 12.5)),
                selected: selected,
                onSelected: (_) => setState(() => _outcome = o.value),
                selectedColor: o.color,
                labelStyle: TextStyle(color: selected ? Colors.white : null),
              );
            }).toList()),
            const SizedBox(height: 14),
            _yesNoToggle('Client met in person?', _clientMet, (v) => setState(() => _clientMet = v)),
            const SizedBox(height: 8),
            _yesNoToggle('Decision-maker present?', _decisionMakerPresent, (v) => setState(() => _decisionMakerPresent = v)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _budgetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Budget Confirmed (₹)', isDense: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _timelineCtrl,
                  decoration: const InputDecoration(labelText: 'Timeline', hintText: 'e.g. 2 months', isDense: true),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            const Text('Comments', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _commentsCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'What did you find on site?',
                hintStyle: const TextStyle(fontSize: 12.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
            const SizedBox(height: 14),
            Text('Site Photos (optional)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 8),
            SizedBox(
              height: 76,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._photos.asMap().entries.map((e) => Stack(clipBehavior: Clip.none, children: [
                    Container(
                      width: 72, height: 72,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FutureBuilder(
                          future: e.value.readAsBytes(),
                          builder: (_, snap) => snap.hasData
                              ? Image.memory(snap.requireData, fit: BoxFit.cover)
                              : Container(color: Colors.grey[200]),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -4, right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _photos.removeAt(e.key)),
                        child: Container(
                          width: 18, height: 18,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ])),
                  if (_photos.length < 6)
                    GestureDetector(
                      onTap: _pickPhotos,
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_a_photo_outlined, color: Colors.grey[500], size: 22),
                          Text('Add', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
            if (_photos.isNotEmpty) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                value: _shareToCommunity,
                onChanged: (v) => setState(() => _shareToCommunity = v),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: const Color(0xFF6A1B9A),
                title: const Text('Share these photos to Community', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: const Text("Post them for others to see, like and comment on", style: TextStyle(fontSize: 11.5)),
              ),
            ],
            ProjectDetailsForm(
              initial: widget.visit.projectDetails,
              onChanged: (data) => _projectDetailsData = data,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_outcome == null || _submitting) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: _submitting
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
