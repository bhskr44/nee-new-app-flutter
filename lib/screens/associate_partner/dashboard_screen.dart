import '../../widgets/app_empty_state.dart';
import 'package:flutter/material.dart';
import '../../models/associate_partner_model.dart';
import '../../services/api_service.dart';
import 'staff_detail_screen.dart';

/// Read-only oversight of the Area Managers and Lead Managers working in this
/// Associate Partner's district — additive to the regular app, not a walled shell
/// (unlike the Area Manager/telecaller mode).
class AssociatePartnerDashboardScreen extends StatefulWidget {
  const AssociatePartnerDashboardScreen({super.key});

  @override
  State<AssociatePartnerDashboardScreen> createState() =>
      _AssociatePartnerDashboardScreenState();
}

class _AssociatePartnerDashboardScreenState
    extends State<AssociatePartnerDashboardScreen> {
  bool _loading = true;
  String? _error;
  String? _district;
  String? _message;
  List<StaffAreaManager> _areaManagers = [];
  List<StaffLeadManager> _leadManagers = [];

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
      final data = await apiService.getAssociatePartnerOverview();
      if (!mounted) return;
      setState(() {
        _district = data['district'];
        _message = data['message'];
        _areaManagers =
            (data['area_managers'] as List)
                .map((e) => StaffAreaManager.fromJson(e))
                .toList();
        _leadManagers =
            (data['lead_managers'] as List)
                .map((e) => StaffLeadManager.fromJson(e))
                .toList();
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
      appBar: AppBar(title: const Text('Team Dashboard')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? AppEmptyState(
                icon: Icons.groups_outlined,
                title: 'Could not load your team',
                message: _error!,
                actionLabel: 'Try again',
                onAction: _fetch,
              )
              : RefreshIndicator(
                onRefresh: _fetch,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_district != null)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.map_outlined),
                          title: const Text('District'),
                          subtitle: Text(
                            _district!,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      )
                    else
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _message ?? 'No district assigned yet.',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      'Area Managers (${_areaManagers.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_areaManagers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No area managers in this district yet.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    else
                      ..._areaManagers.map(
                        (am) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.support_agent),
                            ),
                            title: Text(am.name),
                            subtitle: Text(
                              '${am.totalCalls} calls · ${am.hotLeads} hot leads',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => StaffDetailScreen(
                                          userId: am.id,
                                          name: am.name,
                                          role: 'telecaller',
                                        ),
                                  ),
                                ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      'Lead Managers (${_leadManagers.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_leadManagers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No lead managers in this district yet.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    else
                      ..._leadManagers.map(
                        (lm) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.assignment_ind),
                            ),
                            title: Text(lm.name),
                            subtitle: Text(
                              '${lm.totalVisits} visits · ${lm.completedVisits} completed',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => StaffDetailScreen(
                                          userId: lm.id,
                                          name: lm.name,
                                          role: 'lead_manager',
                                        ),
                                  ),
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}
