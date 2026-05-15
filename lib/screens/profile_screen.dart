import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _companyCtrl;
  bool _editing = false;
  int? _syncedUserId;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl    = TextEditingController(text: user?.name);
    _phoneCtrl   = TextEditingController(text: user?.profile?.phone ?? user?.phone);
    _cityCtrl    = TextEditingController(text: user?.profile?.city);
    _districtCtrl= TextEditingController(text: user?.profile?.district);
    _bioCtrl     = TextEditingController(text: user?.profile?.bio);
    _companyCtrl = TextEditingController(text: user?.profile?.companyName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _cityCtrl.dispose();
    _districtCtrl.dispose(); _bioCtrl.dispose(); _companyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile({
      'name':         _nameCtrl.text.trim(),
      'phone':        _phoneCtrl.text.trim(),
      'city':         _cityCtrl.text.trim(),
      'district':     _districtCtrl.text.trim(),
      'bio':          _bioCtrl.text.trim(),
      'company_name': _companyCtrl.text.trim(),
    });
    if (ok && mounted) setState(() => _editing = false);
  }

  void _syncControllers(UserModel? user) {
    if (user == null || _editing) return;

    final shouldSync = _syncedUserId != user.id ||
        _nameCtrl.text != user.name ||
        _phoneCtrl.text != (user.profile?.phone ?? user.phone ?? '') ||
        _cityCtrl.text != (user.profile?.city ?? '') ||
        _districtCtrl.text != (user.profile?.district ?? '') ||
        _bioCtrl.text != (user.profile?.bio ?? '') ||
        _companyCtrl.text != (user.profile?.companyName ?? '');

    if (!shouldSync) return;

    _syncedUserId = user.id;
    _nameCtrl.text = user.name;
    _phoneCtrl.text = user.profile?.phone ?? user.phone ?? '';
    _cityCtrl.text = user.profile?.city ?? '';
    _districtCtrl.text = user.profile?.district ?? '';
    _bioCtrl.text = user.profile?.bio ?? '';
    _companyCtrl.text = user.profile?.companyName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final user  = auth.user;
    final theme = Theme.of(context);
    _syncControllers(user);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (_editing)
            TextButton(
              onPressed: auth.loading ? null : _save,
              child: auth.loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    (user?.name ?? 'U')[0].toUpperCase(),
                    style: TextStyle(fontSize: 36, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_editing)
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(user?.email ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            if (user?.profile?.isVerified == true) ...[
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.verified, size: 14, color: Colors.blue.shade600),
                const SizedBox(width: 4),
                Text('Verified', style: TextStyle(color: Colors.blue.shade600, fontSize: 12)),
              ]),
            ],
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _field(_nameCtrl, 'Full Name', Icons.person_outline,
                    validator: (v) => (v?.isEmpty ?? true) ? 'Name is required' : null),
                  _field(_phoneCtrl, 'Phone', Icons.phone_outlined,
                    keyboardType: TextInputType.phone),
                  _field(_cityCtrl, 'City', Icons.location_city_outlined),
                  _field(_districtCtrl, 'District', Icons.map_outlined),
                  _field(_companyCtrl, 'Company / Firm Name', Icons.business_outlined),
                  _field(_bioCtrl, 'About Me', Icons.info_outline, maxLines: 3),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/change-password'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              tileColor: Colors.grey[50],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () => _confirmLogout(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              tileColor: Colors.red.shade50,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl, String label, IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        enabled: _editing,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await auth.logout();
    if (context.mounted) context.go('/login');
  }
}
