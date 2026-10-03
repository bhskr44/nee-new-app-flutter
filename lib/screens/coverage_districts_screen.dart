import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Lets a Lead Manager list the districts they can reach for field visits — used to
/// auto-match and surface them when an Area Manager assigns a visit (see
/// TelecallerLeadController::eligibleLeadManagers on the backend).
class CoverageDistrictsScreen extends StatefulWidget {
  const CoverageDistrictsScreen({super.key});

  @override
  State<CoverageDistrictsScreen> createState() => _CoverageDistrictsScreenState();
}

class _CoverageDistrictsScreenState extends State<CoverageDistrictsScreen> {
  final _inputCtrl = TextEditingController();
  late List<String> _districts;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _districts = List.from(
      context.read<AuthProvider>().user?.profile?.serviceDistricts ?? const [],
    );
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  void _addDistrict() {
    final value = _inputCtrl.text.trim();
    if (value.isEmpty || _districts.any((d) => d.toLowerCase() == value.toLowerCase())) {
      _inputCtrl.clear();
      return;
    }
    setState(() {
      _districts.add(value);
      _inputCtrl.clear();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final success = await context.read<AuthProvider>().updateProfile({'service_districts': _districts});
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Coverage districts saved.' : 'Could not save. Try again.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('My Coverage Districts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'List the districts you can reach for site visits. Area Managers see these '
            'when assigning a field visit to a lead manager.',
            style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'District name',
                    hintText: 'e.g. Kamrup',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addDistrict(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addDistrict,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(backgroundColor: theme.colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_districts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No districts added yet.', style: TextStyle(color: Colors.grey[600])),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _districts.map((d) {
                return Chip(
                  label: Text(d),
                  onDeleted: () => setState(() => _districts.remove(d)),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
