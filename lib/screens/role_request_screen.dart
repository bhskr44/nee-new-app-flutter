import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../config/constants.dart';
import '../models/role_request_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class RoleRequestScreen extends StatefulWidget {
  const RoleRequestScreen({super.key});

  @override
  State<RoleRequestScreen> createState() => _RoleRequestScreenState();
}

class _RoleRequestScreenState extends State<RoleRequestScreen> {
  String? _selectedRole;
  bool _submitting = false;

  List<RoleChangeRequestModel> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _loading = true);
    try {
      final data = await apiService.getMyRoleRequests();
      setState(() {
        _requests = (data['data'] as List).map((e) => RoleChangeRequestModel.fromJson(e)).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // A pending request only ever blocks re-requesting that *same* role, not
  // switching to a different (instant) one.
  bool _hasPendingRequestFor(String role) =>
      _requests.any((r) => r.status == 'pending' && r.requestedRole == role);

  Future<void> _submit() async {
    if (_selectedRole == null) return;
    setState(() => _submitting = true);

    if (AppConstants.roleRequiresApproval(_selectedRole!)) {
      try {
        final result = await apiService.requestRoleChange(_selectedRole!);
        // Filing this request may have just changed the account's own role
        // (guest-tier while pending, see RoleRequestController::store) —
        // refresh so the rest of the app (Current Role card, home screen
        // access) reflects that immediately instead of looking stale.
        if (!mounted) return;
        await context.read<AuthProvider>().refreshUser();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] as String? ?? 'Request submitted! Pending admin approval.'),
          duration: const Duration(seconds: 5),
        ));
        setState(() => _selectedRole = null);
        _fetchRequests();
      } catch (e) {
        if (!mounted) return;
        final message = e is DioException
            ? (e.response?.data?['message'] as String? ?? 'Could not submit request.')
            : 'Could not submit request.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
      return;
    }

    // Every other role switches instantly — same as any other profile edit.
    final label = AppConstants.roleLabel(_selectedRole!);
    final success = await context.read<AuthProvider>().updateProfile({'role': _selectedRole});
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) {
      setState(() => _selectedRole = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You're now a $label!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not change your role. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentRole = context.watch<AuthProvider>().user?.profile?.role ?? 'buyer';
    final currentLabel = AppConstants.roleLabel(currentRole);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Change My Role')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.badge_outlined, color: theme.colorScheme.primary),
              title: const Text('Current Role'),
              subtitle: Text(currentLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Switch to a different role', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Most roles switch instantly. Area Manager and Associate Partner are the '
            'exceptions — an admin reviews those before they take effect.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.registrableRoles
                .where((r) => r.$1 != currentRole)
                .map((r) {
              final (value, label, icon, _) = r;
              final selected = _selectedRole == value;
              return ChoiceChip(
                avatar: Icon(icon, size: 16,
                    color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.primary),
                label: Text(label),
                selected: selected,
                onSelected: (_) => setState(() => _selectedRole = selected ? null : value),
                selectedColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color: selected ? theme.colorScheme.onPrimary : null,
                  fontWeight: selected ? FontWeight.w600 : null,
                ),
              );
            }).toList(),
          ),
          if (_selectedRole != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppConstants.registrableRoles.firstWhere((r) => r.$1 == _selectedRole).$4,
                style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.3),
              ),
            ),
            if (_selectedRole == 'associate_partner') ...[
              const SizedBox(height: 6),
              Text(
                "Admin will assign your district when they approve this request.",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
          const SizedBox(height: 16),
          if (_selectedRole != null &&
              AppConstants.roleRequiresApproval(_selectedRole!) &&
              _hasPendingRequestFor(_selectedRole!))
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(
                'You already have a pending ${AppConstants.roleLabel(_selectedRole!)} request. '
                'Wait for it to be reviewed before submitting another.',
                style: const TextStyle(fontSize: 12.5),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: (_selectedRole == null || _submitting) ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_selectedRole == null
                        ? 'Select a role'
                        : 'I confirm my role as ${AppConstants.roleLabel(_selectedRole!)}'),
              ),
            ),
          const SizedBox(height: 28),
          Text('My Requests', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_requests.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No role change requests yet.', style: TextStyle(color: Colors.grey[600])),
            )
          else
            ..._requests.map((r) => _RequestTile(request: r)),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final RoleChangeRequestModel request;
  const _RequestTile({required this.request});

  static const _statusColors = {
    'pending': Color(0xFFF9A825),
    'approved': Color(0xFF2E7D32),
    'rejected': Color(0xFFD32F2F),
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[request.status] ?? Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${AppConstants.roleLabel(request.currentRole)} → ${AppConstants.roleLabel(request.requestedRole)}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(4)),
                  child: Text(request.status.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(_formatDate(request.createdAt), style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
            if (request.status == 'rejected' && request.adminNotes != null && request.adminNotes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Reason: ${request.adminNotes}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return DateFormat('dd MMM yyyy').format(dt.toLocal());
  }
}
