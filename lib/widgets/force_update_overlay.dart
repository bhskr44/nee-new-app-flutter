import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_version_service.dart';

/// Full-screen, non-dismissible overlay shown when a force update is required.
/// Wrap your MaterialApp (or any top-level widget) with this.
class ForceUpdateOverlay extends StatefulWidget {
  const ForceUpdateOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<ForceUpdateOverlay> createState() => _ForceUpdateOverlayState();
}

class _ForceUpdateOverlayState extends State<ForceUpdateOverlay> {
  AppVersionInfo? _info;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    final info = await AppVersionService.instance.check();
    if (mounted) {
      setState(() {
        _info = info;
        _checked = true;
      });
    }
  }

  Future<void> _openStore() async {
    final url = Uri.parse(_info!.storeUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // While version check is in flight, show the app normally (no flash)
    if (!_checked) return widget.child;

    // If no force update required, show the app as-is
    if (_info == null || !_info!.forceUpdate) return widget.child;

    // Force update required — block the entire UI
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFBF360C), Color(0xFFE65100), Color(0xFFF57C00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withAlpha(60),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.system_update_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Update Required',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _info!.releaseNotes?.isNotEmpty == true
                          ? _info!.releaseNotes!
                          : 'A newer version of the app is available. '
                              'Please update to continue using NEE Platform.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    if (_info!.latestVersion != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'v${_info!.currentVersion}  →  v${_info!.latestVersion}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openStore,
                        icon: const Icon(Icons.download_rounded),
                        label: const Text(
                          'Update Now',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFE65100),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
