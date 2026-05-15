import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _whatsapp = '+917002013244';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _sectionHeader('Account'),
          _tile(
            icon: Icons.person_outline,
            label: 'My Profile',
            onTap: () => context.push('/profile'),
          ),
          _tile(
            icon: Icons.lock_outline,
            label: 'Change Password',
            onTap: () => context.push('/change-password'),
          ),
          _sectionHeader('Support'),
          _tile(
            icon: Icons.chat_outlined,
            label: 'Help & Support (WhatsApp)',
            subtitle: _whatsapp,
            onTap: () => _openWhatsApp(context),
          ),
          _tile(
            icon: Icons.call_outlined,
            label: 'Call Support',
            subtitle: _whatsapp,
            onTap: () => _call(context),
          ),
          _sectionHeader('Legal'),
          _tile(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () {},
          ),
          _tile(
            icon: Icons.description_outlined,
            label: 'Terms of Service',
            onTap: () {},
          ),
          _sectionHeader('About'),
          _tile(
            icon: Icons.info_outline,
            label: 'App Version',
            subtitle: '1.0.0',
            onTap: null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: Color(0xFF888888),
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String label,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF555555)),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500]))
          : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right, size: 20, color: Color(0xFFCCCCCC)) : null,
      onTap: onTap,
    );
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final uri = Uri.parse('https://wa.me/917002013244');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  Future<void> _call(BuildContext context) async {
    final uri = Uri.parse('tel:+917002013244');
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open dialer')),
        );
      }
    }
  }
}
