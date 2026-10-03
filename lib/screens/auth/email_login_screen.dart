import '../../widgets/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (context.read<AuthProvider>().loading ||
        !_formKey.currentState!.validate())
      return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (success && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AuthPage(
      title: 'Welcome back',
      subtitle:
          'Sign in with the email and password you used to create your account.',
      onBack: auth.loading ? null : () => context.go('/login'),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (auth.error != null) AuthError(message: auth.error!),
            TextFormField(
              controller: _emailCtrl,
              enabled: !auth.loading,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email address',
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty)
                  return 'Enter your email address.';
                if (!RegExp(
                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                ).hasMatch(value.trim()))
                  return 'Enter a valid email address.';
                return null;
              },
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _passwordCtrl,
              enabled: !auth.loading,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _login(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed:
                      () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? 'Enter your password.'
                          : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: auth.loading ? null : _login,
              child:
                  auth.loading
                      ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text('Sign in'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Forgot your password?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF526071)),
            ),
            TextButton(
              onPressed: auth.loading ? null : () => context.go('/login'),
              child: const Text('Sign in with your linked phone number'),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('New to NEE?'),
                TextButton(
                  onPressed:
                      auth.loading ? null : () => context.go('/register'),
                  child: const Text('Create account'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const AuthLegalLinks(),
          ],
        ),
      ),
    );
  }
}
