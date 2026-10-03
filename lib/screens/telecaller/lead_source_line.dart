import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/telecaller_lead_model.dart';

/// Where the lead is, which ad-sheet list it came from, and when the customer enquired.
class LeadSourceLine extends StatelessWidget {
  final TelecallerLeadModel lead;

  /// Off for cards that already show the location themselves
  final bool showLocation;
  const LeadSourceLine({
    super.key,
    required this.lead,
    this.showLocation = true,
  });

  @override
  Widget build(BuildContext context) {
    final received = DateTime.tryParse(
      lead.submittedAt ?? lead.createdAt ?? '',
    );
    final location =
        showLocation && lead.location.isNotEmpty ? lead.location : null;
    if (location == null && lead.source == null && received == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (location != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 14,
                    color: Color(0xFFD84315),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      location,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (lead.source != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 12,
                        color: Color(0xFF1565C0),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          lead.source!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1565C0),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (received != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 3),
                    Text(
                      'Received ${DateFormat('dd MMM yyyy, h:mm a').format(received.toLocal())}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
