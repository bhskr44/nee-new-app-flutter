import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/field_visit_model.dart';
import '../services/api_service.dart';
import '../widgets/field_visit_report_card.dart';
import 'field_visit_report_sheet.dart';
import 'telecaller/lead_call_history_sheet.dart';

/// How soon a visit is — buckets the schedule into tabs so the most urgent
/// ones (today, tomorrow) don't get lost in a long flat list.
enum _DateBucket { today, tomorrow, next10Days, later }

/// Narrows the list by where the visit stands, independent of the date tabs.
enum _StatusFilter { all, assignedToYou, accepted, completed }

const _statusFilterLabels = {
  _StatusFilter.all: 'All',
  _StatusFilter.assignedToYou: 'Assigned to You',
  _StatusFilter.accepted: 'Accepted',
  _StatusFilter.completed: 'Completed',
};

const _bucketLabels = {
  _DateBucket.today: 'Today',
  _DateBucket.tomorrow: 'Tomorrow',
  _DateBucket.next10Days: 'Next 10 Days',
  _DateBucket.later: 'Later',
};

const _bucketColors = {
  _DateBucket.today: Color(0xFFD32F2F),
  _DateBucket.tomorrow: Color(0xFFEF6C00),
  _DateBucket.next10Days: Color(0xFF1565C0),
  _DateBucket.later: Color(0xFF757575),
};

/// Anything unparsable or more than 10 days out — including overdue/past
/// dates — falls into "Later" rather than a 5th tab nobody asked for.
_DateBucket _bucketFor(String scheduledDate) {
  final d = DateTime.tryParse(scheduledDate);
  if (d == null) return _DateBucket.later;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final visitDay = DateTime(d.year, d.month, d.day);
  final diff = visitDay.difference(today).inDays;
  if (diff == 0) return _DateBucket.today;
  if (diff == 1) return _DateBucket.tomorrow;
  if (diff >= 2 && diff <= 10) return _DateBucket.next10Days;
  return _DateBucket.later;
}

class MyFieldVisitsScreen extends StatefulWidget {
  const MyFieldVisitsScreen({super.key});

  @override
  State<MyFieldVisitsScreen> createState() => _MyFieldVisitsScreenState();
}

class _MyFieldVisitsScreenState extends State<MyFieldVisitsScreen> {
  List<FieldVisitModel> _visits = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _query = '';
  _StatusFilter _statusFilter = _StatusFilter.all;

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
    setState(() => _loading = true);
    try {
      final data = await apiService.getMyFieldVisits();
      setState(() {
        _visits =
            (data['data'] as List)
                .map((e) => FieldVisitModel.fromJson(e))
                .toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  /// Matches against the scheduled date (raw or friendly-formatted), the
  /// visit report comment, and the outcome.
  bool _matchesSearch(FieldVisitModel v) {
    if (_query.isEmpty) return true;
    if (v.scheduledDate.toLowerCase().contains(_query)) return true;
    final parsed = DateTime.tryParse(v.scheduledDate);
    if (parsed != null &&
        DateFormat(
          'dd MMM yyyy',
        ).format(parsed).toLowerCase().contains(_query)) {
      return true;
    }
    if ((v.comments ?? '').toLowerCase().contains(_query)) return true;
    if ((v.outcome ?? '').replaceAll('_', ' ').toLowerCase().contains(_query)) {
      return true;
    }
    return false;
  }

  bool _matchesStatusFilter(FieldVisitModel v) {
    switch (_statusFilter) {
      case _StatusFilter.all:
        return true;
      case _StatusFilter.assignedToYou:
        return v.isPendingAcceptance;
      case _StatusFilter.accepted:
        return v.status == 'accepted';
      case _StatusFilter.completed:
        return v.isCompleted;
    }
  }

  List<FieldVisitModel> get _filtered =>
      _visits.where(_matchesSearch).where(_matchesStatusFilter).toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return DefaultTabController(
      length: _DateBucket.values.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('My Field Visits'),
          bottom:
              _loading || _visits.isEmpty
                  ? null
                  : TabBar(
                    isScrollable: true,
                    indicatorColor: Colors.white,
                    tabs:
                        _DateBucket.values.map((b) {
                          final count =
                              filtered
                                  .where(
                                    (v) => _bucketFor(v.scheduledDate) == b,
                                  )
                                  .length;
                          return Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _bucketColors[b],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text('${_bucketLabels[b]} ($count)'),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
        ),
        body:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _visits.isEmpty
                ? Center(
                  child: Text(
                    'No field visits yet.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
                : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search by date, comment, or outcome...',
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
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                      child: Wrap(
                        spacing: 8,
                        children:
                            _StatusFilter.values.map((f) {
                              return ChoiceChip(
                                label: Text(_statusFilterLabels[f]!),
                                selected: _statusFilter == f,
                                onSelected:
                                    (_) => setState(() => _statusFilter = f),
                              );
                            }).toList(),
                      ),
                    ),
                    Expanded(
                      child:
                          filtered.isEmpty
                              ? Center(
                                child: Text(
                                  'No visits match your search or filter.',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              )
                              : TabBarView(
                                children:
                                    _DateBucket.values.map((b) {
                                      final items =
                                          filtered
                                              .where(
                                                (v) =>
                                                    _bucketFor(
                                                      v.scheduledDate,
                                                    ) ==
                                                    b,
                                              )
                                              .toList();
                                      return items.isEmpty
                                          ? Center(
                                            child: Text(
                                              'No visits ${_bucketLabels[b]!.toLowerCase()}.',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          )
                                          : RefreshIndicator(
                                            onRefresh: _fetch,
                                            child: ListView.builder(
                                              padding: const EdgeInsets.all(16),
                                              itemCount: items.length,
                                              itemBuilder:
                                                  (_, i) => _VisitCard(
                                                    visit: items[i],
                                                    bucketColor:
                                                        _bucketColors[b]!,
                                                    onChanged: _fetch,
                                                  ),
                                            ),
                                          );
                                    }).toList(),
                              ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class _VisitCard extends StatefulWidget {
  final FieldVisitModel visit;
  final Color bucketColor;
  final VoidCallback onChanged;
  const _VisitCard({
    required this.visit,
    required this.bucketColor,
    required this.onChanged,
  });

  @override
  State<_VisitCard> createState() => _VisitCardState();
}

class _VisitCardState extends State<_VisitCard> {
  static const _statusColors = {
    'pending': Color(0xFFF9A825),
    'accepted': Color(0xFF6A1B9A),
    'completed': Color(0xFF2E7D32),
    'cancelled': Color(0xFF757575),
  };

  bool _accepting = false;
  bool _declining = false;

  Future<void> _declineFlow() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Can't make this visit?"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "This will let the Area Manager reassign the visit to someone "
                  'else for the same date. Add a reason (optional):',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Family emergency, can\'t travel that day',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red[700]),
                child: const Text("Can't Make It"),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _declining = true);
    try {
      await apiService.declineFieldVisit(
        widget.visit.id,
        reason: controller.text.trim(),
      );
      widget.onChanged();
    } catch (_) {
      if (!mounted) return;
      setState(() => _declining = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not mark this visit as declined.')),
      );
    }
  }

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      await apiService.acceptFieldVisit(widget.visit.id);
      widget.onChanged();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _accepting = false);
      if (e.response?.statusCode == 402) {
        // Same package/paywall gate as "Proceed with this Lead" — the full
        // purchase flow (with Razorpay checkout) lives on the Leads screen;
        // point them there rather than duplicating that flow here.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You need an active lead package to accept this visit. '
              'Choose one from the Leads screen, then try again.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }
      final message =
          e.response?.data is Map
              ? (e.response?.data['message'] as String? ??
                  'Could not accept this visit.')
              : 'Could not accept this visit.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _accepting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not accept this visit.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visit = widget.visit;
    final color = _statusColors[visit.status] ?? Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: widget.bucketColor.withAlpha(60), width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, color: widget.bucketColor),
            Expanded(
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
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap:
                              () => showLeadCallHistorySheet(
                                context,
                                leadId: visit.leadId,
                                leadTitle: visit.leadTitle,
                              ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.history,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
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
                            visit.isPendingAcceptance
                                ? 'ASSIGNED TO YOU'
                                : visit.status.toUpperCase(),
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
                        const Icon(
                          Icons.location_on,
                          size: 13,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            visit.leadLocation,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Icon(Icons.event, size: 13, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(
                          visit.scheduledDate,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (visit.isCompleted) ...[
                      const Divider(height: 20),
                      FieldVisitReportCard(visit: visit),
                    ] else if (visit.isPendingAcceptance) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _accepting ? null : _accept,
                          icon:
                              _accepting
                                  ? const SizedBox(
                                    width: 15,
                                    height: 15,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.check_circle_outline,
                                    size: 17,
                                  ),
                          label: Text(
                            _accepting ? 'Accepting...' : 'Accept Visit',
                            style: const TextStyle(fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF9A825),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: _declining ? null : _declineFlow,
                          icon:
                              _declining
                                  ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.block, size: 15),
                          label: Text(
                            _declining ? 'Submitting...' : "Can't Make It",
                            style: const TextStyle(fontSize: 12.5),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red[700],
                          ),
                        ),
                      ),
                    ] else if (visit.status == 'accepted') ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final saved = await showFieldVisitReportSheet(
                              context,
                              visit,
                            );
                            if (saved == true) widget.onChanged();
                          },
                          icon: const Icon(Icons.edit_note, size: 17),
                          label: const Text(
                            'Log Visit Report',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A1B9A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: _declining ? null : _declineFlow,
                          icon:
                              _declining
                                  ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.block, size: 15),
                          label: Text(
                            _declining ? 'Submitting...' : "Can't Make It",
                            style: const TextStyle(fontSize: 12.5),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
