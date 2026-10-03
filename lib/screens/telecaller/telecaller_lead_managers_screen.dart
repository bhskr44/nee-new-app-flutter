import '../../widgets/app_empty_state.dart';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'telecaller_pool_screen.dart' show launchDialer;

/// Every lead manager, with how many of this Area Manager's visits are
/// currently on each one's plate — helps decide who to assign or reassign
/// a visit to.
class TelecallerLeadManagersScreen extends StatefulWidget {
  const TelecallerLeadManagersScreen({super.key});

  @override
  State<TelecallerLeadManagersScreen> createState() =>
      _TelecallerLeadManagersScreenState();
}

class _TelecallerLeadManagersScreenState
    extends State<TelecallerLeadManagersScreen> {
  List<dynamic> _leadManagers = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  String _query = '';

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await apiService.getLeadManagers();
      setState(() {
        _leadManagers = data;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Could not load lead managers. Pull down to retry.';
      });
    }
  }

  List<dynamic> get _filtered {
    if (_query.isEmpty) return _leadManagers;
    return _leadManagers.where((lm) {
      final name = (lm['name'] as String? ?? '').toLowerCase();
      return name.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lead Managers',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by name...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
                ],
              ),
            ),
            Expanded(
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? AppEmptyState(
                        icon: Icons.cloud_off_outlined,
                        title: 'Could not load this list',
                        message: 'Check your connection and try again.',
                        actionLabel: 'Try again',
                        onAction: _fetch,
                      )
                      : _leadManagers.isEmpty
                      ? Center(
                        child: Text(
                          'No lead managers yet.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                      : _filtered.isEmpty
                      ? Center(
                        child: Text(
                          'No lead managers match "${_searchCtrl.text}".',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: _fetch,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _filtered.length,
                          itemBuilder:
                              (_, i) => _LeadManagerCard(
                                leadManager:
                                    _filtered[i] as Map<String, dynamic>,
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

class _LeadManagerCard extends StatelessWidget {
  final Map<String, dynamic> leadManager;
  const _LeadManagerCard({required this.leadManager});

  @override
  Widget build(BuildContext context) {
    final name = leadManager['name'] as String? ?? '';
    final phone = leadManager['phone'] as String?;
    final districts =
        (leadManager['districts'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    final active = leadManager['active_visits'] ?? 0;
    final completed = leadManager['completed_visits'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (phone != null && phone.isNotEmpty) {
            launchDialer(phone);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No phone number on file for this lead manager.'),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.person_outline)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (districts.isNotEmpty)
                          Text(
                            districts.join(', '),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          Text(
                            'No coverage districts set',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _StatChip(
                    icon: Icons.pending_actions,
                    label: '$active active',
                    color: active > 0 ? const Color(0xFFF9A825) : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.check_circle_outline,
                    label: '$completed completed',
                    color: const Color(0xFF2E7D32),
                  ),
                ],
              ),
              if (phone != null && phone.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => launchDialer(phone),
                    icon: const Icon(Icons.call_outlined, size: 15),
                    label: Text(phone, style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
