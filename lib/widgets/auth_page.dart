import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/constants.dart';

/// A scrollable, keyboard-safe frame shared by phone, email and signup flows.
class AuthPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? bottomAction;
  final VoidCallback? onBack;

  const AuthPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.bottomAction,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 24, 0),
                child: Row(
                  children: [
                    if (onBack != null)
                      IconButton(
                        tooltip: 'Go back',
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                      )
                    else
                      const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.construction_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'NEE',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF526071),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        child,
                      ],
                    ),
                  ),
                ),
              ),
              if (bottomAction != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE5E9EE))),
                  ),
                  child: bottomAction,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class AuthError extends StatelessWidget {
  final String message;
  const AuthError({super.key, required this.message});

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onErrorContainer,
          height: 1.5,
        ),
      ),
    ),
  );
}

class AuthLegalLinks extends StatelessWidget {
  const AuthLegalLinks({super.key});

  Future<void> _open(BuildContext context, String path) async {
    try {
      if (await launchUrl(
        Uri.parse(AppConstants.apiBaseUrl).resolve(path),
        mode: LaunchMode.externalApplication,
      ))
        return;
    } catch (_) {
      // Report failure without losing entered account details.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open this page. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Text(
        'By continuing, you agree to our',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Color(0xFF526071)),
      ),
      Wrap(
        alignment: WrapAlignment.center,
        children: [
          TextButton(
            onPressed: () => _open(context, '/terms-and-conditions'),
            child: const Text('Terms of Service'),
          ),
          TextButton(
            onPressed: () => _open(context, '/privacy-policy'),
            child: const Text('Privacy Policy'),
          ),
        ],
      ),
    ],
  );
}
