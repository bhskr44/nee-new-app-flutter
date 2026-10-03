import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_segments.dart';
import '../providers/auth_provider.dart';
import '../services/referral_service.dart';

/// The side menu — reused by every screen that shows a hamburger icon
/// (Home, and the bottom-nav tab screens: Products, Calculator, Leads),
/// not just Home, so give every one of them `drawer: const AppDrawer()`
/// alongside the menu IconButton that opens it.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final userName = user?.name ?? 'NEE User';
    final userSub = [
      if (user?.profile?.city != null) user!.profile!.city!,
    ].join(' · ');

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 20,
              20,
              20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B1A00), Color(0xFFE65100)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    userName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userSub.isNotEmpty ? userSub : (user?.email ?? ''),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final i in visibleSegmentIndices(context))
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: appSegments[i].color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        appSegments[i].icon,
                        color: appSegments[i].color,
                        size: 19,
                      ),
                    ),
                    title: Text(
                      appSegments[i].label,
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      navigateToSegment(context, i);
                    },
                  ),
                const Divider(height: 24, indent: 16, endIndent: 16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const Icon(
                    Icons.person_outline,
                    size: 21,
                    color: Color(0xFF555555),
                  ),
                  title: const Text(
                    'My Profile',
                    style: TextStyle(fontSize: 14),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/profile');
                  },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const Icon(
                    Icons.settings_outlined,
                    size: 21,
                    color: Color(0xFF555555),
                  ),
                  title: const Text('Settings', style: TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/settings');
                  },
                ),
                if (roleModeConfig(user) case final config?)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: Icon(
                      config.icon,
                      size: 21,
                      color: const Color(0xFF555555),
                    ),
                    title: Text(
                      config.label,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      config.subtitle,
                      style: const TextStyle(fontSize: 11),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(config.route);
                    },
                  ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const Icon(
                    Icons.card_giftcard_outlined,
                    size: 21,
                    color: Color(0xFF555555),
                  ),
                  title: const Text(
                    'Invite a Friend',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Share the app & earn rewards',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ReferralService.share(user?.id);
                  },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const Icon(
                    Icons.help_outline,
                    size: 21,
                    color: Color(0xFF555555),
                  ),
                  title: const Text(
                    'Help & Support',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text(
                    '+91 70020 13244',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    launchUrl(
                      Uri.parse('https://wa.me/917002013244'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
