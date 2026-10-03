import 'package:package_info_plus/package_info_plus.dart';
import '../config/constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/referral_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _whatsapp = '+917002013244';

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

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
          _tile(
            icon: Icons.swap_horiz_outlined,
            label: 'Change My Role',
            subtitle: 'Request a role change from admin',
            onTap: () => context.push('/role-request'),
          ),
          _tile(
            icon: Icons.receipt_long_outlined,
            label: 'My Estimates',
            subtitle: 'Product estimates you\'ve submitted',
            onTap: () => context.push('/my-estimates'),
          ),
          if (user?.isTelecaller == true)
            _tile(
              icon: Icons.call_outlined,
              label: 'Telecalling Mode',
              subtitle: 'Switch to your lead-calling dashboard',
              onTap: () => context.push('/telecaller'),
            ),
          if (user?.isLeadManager == true)
            _tile(
              icon: Icons.map_outlined,
              label: 'My Coverage Districts',
              subtitle: 'Districts you can reach for field visits',
              onTap: () => context.push('/coverage-districts'),
            ),
          if (user?.isAssociatePartner == true)
            _tile(
              icon: Icons.dashboard_outlined,
              label: 'Team Dashboard',
              subtitle: 'Oversee your district\'s Area & Lead Managers',
              onTap: () => context.push('/associate-partner-dashboard'),
            ),
          _sectionHeader('Refer & Earn'),
          _tile(
            icon: Icons.card_giftcard_outlined,
            label: 'Invite a Friend',
            subtitle: 'Share the app & earn rewards',
            onTap: () => ReferralService.share(user?.id),
          ),
          _tile(
            icon: Icons.stars_outlined,
            label: 'My Points',
            subtitle: 'View passbook & redeem rewards',
            onTap: () => context.push('/wallet'),
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
            onTap: () => _openLegal(context, '/privacy-policy'),
          ),
          _tile(
            icon: Icons.description_outlined,
            label: 'Terms of Service',
            onTap: () => _openLegal(context, '/terms-and-conditions'),
          ),
          _sectionHeader('About'),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder:
                (context, snapshot) => _tile(
                  icon: Icons.info_outline,
                  label: 'App Version',
                  subtitle:
                      snapshot.hasData
                          ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                          : 'NEE Platform',
                ),
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
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: Color(0xFF526071),
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
      subtitle:
          subtitle != null
              ? Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              )
              : null,
      trailing:
          onTap != null
              ? const Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFFCCCCCC),
              )
              : null,
      onTap: onTap,
    );
  }

  Future<void> _openLegal(BuildContext context, String path) async {
    try {
      final uri = Uri.parse(AppConstants.apiBaseUrl).resolve(path);
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Keep the user on Settings with an actionable message.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open this page. Try again or contact Support.',
          ),
        ),
      );
    }
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open dialer')));
      }
    }
  }
}
