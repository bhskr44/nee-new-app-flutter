import '../../widgets/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

/// Drill-down into one staff member's activity — call logs for an Area Manager
/// ('telecaller'), field-visit history for a Lead Manager ('lead_manager').
class StaffDetailScreen extends StatefulWidget {
  final int userId;
  final String name;
  final String role; // 'telecaller' | 'lead_manager'

  const StaffDetailScreen({
    super.key,
    required this.userId,
    required this.name,
    required this.role,
  });

  @override
  State<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<StaffDetailScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  bool get _isAreaManager => widget.role == 'telecaller';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data =
          _isAreaManager
              ? await apiService.getStaffCallLogs(widget.userId)
              : await apiService.getStaffFieldVisits(widget.userId);
      if (!mounted) return;
      setState(() {
        _items = (data['data'] as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: Text(widget.name)),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? AppEmptyState(
                icon: Icons.history_rounded,
                title: 'Could not load activity',
                message: _error!,
                actionLabel: 'Try again',
                onAction: _fetch,
              )
              : _items.isEmpty
              ? Center(
                child: Text(
                  _isAreaManager ? 'No call logs yet.' : 'No field visits yet.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
              : RefreshIndicator(
                onRefresh: _fetch,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder:
                      (_, i) =>
                          _isAreaManager
                              ? _CallLogTile(item: _items[i])
                              : _FieldVisitTile(item: _items[i]),
                ),
              ),
    );
  }
}

class _CallLogTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _CallLogTile({required this.item});

  static const _statusColors = {
    'hot': Color(0xFFD32F2F),
    'cold': Color(0xFF1565C0),
    'callback': Color(0xFFEF6C00),
    'archive': Color(0xFF757575),
    'closed': Color(0xFF2E7D32),
  };

  @override
  Widget build(BuildContext context) {
    final lead = item['lead'] as Map<String, dynamic>?;
    final status = item['status'] as String? ?? '';
    final color = _statusColors[status] ?? Colors.grey;
    return Card(
      child: ListTile(
        title: Text(
          lead?['title'] ?? 'Lead',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatDate(item['created_at']),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic iso) {
    final dt = iso is String ? DateTime.tryParse(iso) : null;
    return dt == null
        ? ''
        : DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
  }
}

class _FieldVisitTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _FieldVisitTile({required this.item});

  static const _statusColors = {
    'pending': Color(0xFFF9A825),
    'accepted': Color(0xFF6A1B9A),
    'completed': Color(0xFF2E7D32),
    'cancelled': Color(0xFF757575),
  };

  @override
  Widget build(BuildContext context) {
    final lead = item['lead'] as Map<String, dynamic>?;
    final status = item['status'] as String? ?? '';
    final color = _statusColors[status] ?? Colors.grey;
    return Card(
      child: ListTile(
        title: Text(
          lead?['title'] ?? 'Lead',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Scheduled: ${item['scheduled_date'] ?? '—'}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
