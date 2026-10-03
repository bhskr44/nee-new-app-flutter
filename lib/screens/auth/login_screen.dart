import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_page.dart';
import '../../widgets/phone_number_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => AuthPage(
    title: 'Welcome to NEE',
    subtitle:
        'Find construction products, skilled people and opportunities near you.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E7ED)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: PhoneNumberButton(onSuccess: () => context.go('/')),
        ),
        const SizedBox(height: 12),
        const Text(
          'New here? Phone verification also creates your account.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFF526071), height: 1.5),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 22),
          child: Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text('or'),
              ),
              Expanded(child: Divider()),
            ],
          ),
        ),
        if (AuthProvider.googleSignInAvailable) ...[
          const _GoogleSignInButton(),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: () => context.push('/login/email'),
          icon: const Icon(Icons.mail_outline_rounded),
          label: const Text('Sign in with email'),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Prefer to register with email?'),
            TextButton(
              onPressed: () => context.push('/register'),
              child: const Text('Create account'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const AuthLegalLinks(),
      ],
    ),
  );
}

/// The phone number is verified afterwards, on the router-driven
/// /verify-phone screen (see AuthProvider.shouldPromptPhoneVerification).
class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton();

  Future<void> _signIn(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithGoogle();
    if (!context.mounted) return;
    if (ok) {
      context.go('/');
    } else if (auth.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select<AuthProvider, bool>((a) => a.loading);
    return OutlinedButton.icon(
      onPressed: loading ? null : () => _signIn(context),
      icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
      label: const Text('Continue with Google'),
    );
  }
}
