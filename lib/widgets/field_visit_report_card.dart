import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/field_visit_model.dart';

/// The full on-site report as filed by a Lead Manager — outcome, the
/// client-met/decision-maker checks, budget/timeline, comments, and every
/// photo. Shared by the telecaller's "Field Visit Status" list, the Lead
/// Manager's own "My Field Visits" list, and the lead's call-history sheet
/// (the "previous report" view), so the whole document reads the same
/// everywhere it's shown. Renders nothing for a visit that isn't completed.
class FieldVisitReportCard extends StatelessWidget {
  final FieldVisitModel visit;
  const FieldVisitReportCard({super.key, required this.visit});

  static const _outcomeLabels = {
    'interested': 'Interested',
    'needs_follow_up': 'Needs Follow-up',
    'not_interested': 'Not Interested',
  };
  static const _outcomeColors = {
    'interested': Color(0xFF2E7D32),
    'needs_follow_up': Color(0xFFEF6C00),
    'not_interested': Color(0xFFC62828),
  };

  Widget _yesNoChip(String label, bool? value) {
    if (value == null) return const SizedBox.shrink();
    final color = value ? const Color(0xFF2E7D32) : Colors.red[400]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(value ? Icons.check_circle : Icons.cancel, size: 13, color: color),
        const SizedBox(width: 4),
        Text('$label: ${value ? 'Yes' : 'No'}',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  void _openPhoto(BuildContext context, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: Colors.transparent,
        child: PageView.builder(
          controller: PageController(initialPage: index),
          itemCount: visit.photoUrls.length,
          itemBuilder: (_, i) => InteractiveViewer(
            child: CachedNetworkImage(imageUrl: visit.photoUrls[i], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!visit.isCompleted) return const SizedBox.shrink();

    final outcomeLabel = _outcomeLabels[visit.outcome] ?? visit.outcome?.replaceAll('_', ' ');
    final outcomeColor = _outcomeColors[visit.outcome] ?? Colors.grey;
    final hasChecks = visit.clientMet != null || visit.decisionMakerPresent != null;
    final hasFigures = visit.budgetConfirmed != null || (visit.timelineConfirmed?.isNotEmpty ?? false);

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
            const Icon(Icons.fact_check_outlined, size: 15, color: Colors.black54),
            const SizedBox(width: 6),
            const Text('Visit Report', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
            const Spacer(),
            if (visit.acceptedByName != null)
              Text(visit.acceptedByName!, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ]),
          const SizedBox(height: 8),
          if (outcomeLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: outcomeColor.withAlpha(25), borderRadius: BorderRadius.circular(6)),
              child: Text(outcomeLabel,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: outcomeColor)),
            ),
          if (hasChecks) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              _yesNoChip('Client met', visit.clientMet),
              _yesNoChip('Decision-maker', visit.decisionMakerPresent),
            ]),
          ],
          if (hasFigures) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 14, runSpacing: 4, children: [
              if (visit.budgetConfirmed != null)
                Text('Budget: ₹${visit.budgetConfirmed!.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              if (visit.timelineConfirmed != null && visit.timelineConfirmed!.isNotEmpty)
                Text('Timeline: ${visit.timelineConfirmed}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ],
          if (visit.comments != null && visit.comments!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(visit.comments!, style: TextStyle(fontSize: 12.5, color: Colors.grey[800])),
          ],
          if (visit.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: visit.photoUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _openPhoto(context, i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: visit.photoUrls[i],
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(width: 72, height: 72, color: Colors.grey[200]),
                      errorWidget: (_, _, _) => Container(
                        width: 72,
                        height: 72,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image_outlined, size: 20, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
