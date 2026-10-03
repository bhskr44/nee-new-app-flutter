import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/referral_service.dart';
import '../../widgets/auth_page.dart';
import 'package:flutter/services.dart';
import '../../widgets/role_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _step = 0;
  String _selectedRole = 'buyer';
  bool _roleAccepted = false;

  @override
  void initState() {
    super.initState();
    ReferralService.getPendingCode().then((code) {
      if (code != null && code.isNotEmpty && mounted) {
        _referralCtrl.text = code;
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (context.read<AuthProvider>().loading ||
        !_formKey.currentState!.validate())
      return;
    if (RolePicker.isTeamRole(_selectedRole) && !_roleAccepted) return;
    FocusScope.of(context).unfocus();

    // Roles requiring admin approval (Associate Partner, Telecaller, Lead
    // Manager) are never sent as a registration role directly. Register as
    // 'guest' instead — the account sits in guest-tier access (7-day clock,
    // see Profile::guest_expires_at) until admin approves the actual role —
    // then auto-file the role-change request so the user doesn't have to do
    // it separately afterward.
    final requiresApproval = AppConstants.roleRequiresApproval(_selectedRole);

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      passwordConfirmation: _confirmCtrl.text,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      role: requiresApproval ? 'guest' : _selectedRole,
      referralCode:
          _referralCtrl.text.trim().isEmpty ? null : _referralCtrl.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      final ref = _referralCtrl.text.trim();
      if (ref.isNotEmpty) {
        apiService.trackReferral(ref).ignore();
        ReferralService.markUsed().ignore();
      }
      // The register() call above already stamped role_confirmed_at
      // server-side (AuthController::register — role is always sent from
      // this wizard's step 2), so home_screen.dart's mandatory role prompt
      // won't ask again.
      if (requiresApproval) {
        try {
          await apiService.requestRoleChange(_selectedRole);
        } catch (_) {
          // Account creation already succeeded — the user can still file the
          // request later from Settings if this follow-up call failed.
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account created! Your ${AppConstants.roleLabel(_selectedRole)} request is pending admin approval.',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      context.go('/');
    }
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _step = 1);
  }

  void _back() {
    if (_step == 1) {
      setState(() => _step = 0);
    } else {
      context.go('/login');
    }
  }

  Widget _passwordField(
    TextEditingController controller, {
    bool confirm = false,
  }) {
    final hidden = confirm ? _obscureConfirm : _obscurePassword;
    return TextFormField(
      controller: controller,
      obscureText: hidden,
      autofillHints: const [AutofillHints.newPassword],
      textInputAction: confirm ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: confirm ? (_) => _next() : null,
      decoration: InputDecoration(
        labelText: confirm ? 'Confirm password' : 'Password',
        helperText:
            confirm
                ? 'Enter the same password again.'
                : 'Use at least 8 characters.',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: hidden ? 'Show password' : 'Hide password',
          onPressed:
              () => setState(() {
                if (confirm) {
                  _obscureConfirm = !hidden;
                } else {
                  _obscurePassword = !hidden;
                }
              }),
          icon: Icon(
            hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty)
          return confirm ? 'Confirm your password.' : 'Create a password.';
        if (confirm && value != _passwordCtrl.text)
          return 'The passwords do not match.';
        if (!confirm && value.length < 8) return 'Use at least 8 characters.';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final needsAcceptance =
        RolePicker.isTeamRole(_selectedRole) && !_roleAccepted;
    return PopScope(
      canPop: _step == 0 && !auth.loading,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !auth.loading && _step == 1) _back();
      },
      child: AuthPage(
        title: _step == 0 ? 'Create your account' : 'Make NEE work for you',
        subtitle:
            _step == 0
                ? 'Start with your name and sign-in details.'
                : 'Choose how you will use NEE. You can request a different role later in Settings.',
        onBack: auth.loading ? null : _back,
        bottomAction: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_step == 1 && needsAcceptance) ...[
              const Text(
                'Accept the selected role responsibilities to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF526071)),
              ),
              const SizedBox(height: 8),
            ],
            ElevatedButton(
              onPressed:
                  auth.loading || (_step == 1 && needsAcceptance)
                      ? null
                      : _step == 0
                      ? _next
                      : _register,
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
                      : Text(
                        _step == 0 ? 'Continue to your role' : 'Create account',
                      ),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _step == 0 ? '1. Account details' : '2. Your role',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    'Step ${_step + 1} of 2',
                    style: const TextStyle(color: Color(0xFF526071)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (_step + 1) / 2,
                minHeight: 4,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 24),
              if (auth.error != null) AuthError(message: auth.error!),
              if (_step == 0) ...[
                TextFormField(
                  controller: _nameCtrl,
                  autofillHints: const [AutofillHints.name],
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    hintText: 'Enter your name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator:
                      (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Enter your name.'
                              : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _emailCtrl,
                  autofillHints: const [AutofillHints.email],
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                  validator:
                      (value) =>
                          value == null ||
                                  !RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  ).hasMatch(value.trim())
                              ? 'Enter a valid email address.'
                              : null,
                ),
                const SizedBox(height: 18),
                _passwordField(_passwordCtrl),
                const SizedBox(height: 18),
                _passwordField(_confirmCtrl, confirm: true),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ] else ...[
                AbsorbPointer(
                  absorbing: auth.loading,
                  child: RolePicker(
                    selectedRole: _selectedRole,
                    onRoleChanged:
                        (value) => setState(() => _selectedRole = value),
                    accepted: _roleAccepted,
                    onAcceptedChanged:
                        (value) => setState(() => _roleAccepted = value),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Optional details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneCtrl,
                  enabled: !auth.loading,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Mobile number (optional)',
                    prefixText: '+91 ',
                    helperText: 'Enter your 10-digit Indian mobile number.',
                  ),
                  validator:
                      (value) =>
                          value != null &&
                                  value.isNotEmpty &&
                                  !RegExp(r'^[6-9][0-9]{9}$').hasMatch(value)
                              ? 'Enter a valid 10-digit mobile number.'
                              : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _referralCtrl,
                  enabled: !auth.loading,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Referral code (optional)',
                    hintText: 'e.g. NEE123',
                    prefixIcon: Icon(Icons.redeem_rounded),
                  ),
                ),
                const SizedBox(height: 24),
                const AuthLegalLinks(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
