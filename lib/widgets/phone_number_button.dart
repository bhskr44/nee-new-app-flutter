import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:truecaller_sdk/truecaller_sdk.dart'
    show TcSdk, TcSdkOptions, TcSdkCallback, TcSdkCallbackResult;
import '../config/constants.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/referral_service.dart';
import 'role_picker.dart';

const _phoneNativeChannel = MethodChannel('com.nee.construction/phone');
const _otpEventChannel = EventChannel('com.nee.construction/otp');

bool _isProfileIncomplete(UserModel? user) =>
    user == null ||
    user.name.trim().isEmpty ||
    user.name.startsWith('User ') ||
    user.email.endsWith('@nee.local');

// Normalizes raw phone strings to +91XXXXXXXXXX format by taking the last 10
// digits, whatever comes before them (junk country codes, a stray extra "+91",
// spaces/dashes from SIM/hint lookups) — an Indian mobile number is always the
// last 10 digits, so this is more robust than trying to pattern-match every
// possible input shape (and trusting a leading "+" blindly let malformed
// values like "+1917002013244" through untouched, doubling up with the UI's
// own fixed "+91" prefix).
String? _normalizeIndianPhone(String? value) {
  final digitsOnly = value?.replaceAll(RegExp(r'\D'), '') ?? '';
  if (digitsOnly.length < 10) return null;
  return '+91${digitsOnly.substring(digitsOnly.length - 10)}';
}

class PhoneNumberButton extends StatefulWidget {
  final VoidCallback? onSuccess;
  final String? prefillReferral;

  /// Verify-only mode for an already signed-in Google account: the OTP goes
  /// to AuthProvider.verifyPhone instead of logging in, with no Truecaller and
  /// no profile sheet. Reports whether the number merged into an existing
  /// account.
  final void Function(bool merged)? onPhoneVerified;

  const PhoneNumberButton({
    super.key,
    this.onSuccess,
    this.prefillReferral,
    this.onPhoneVerified,
  });

  bool get verifyOnly => onPhoneVerified != null;

  @override
  State<PhoneNumberButton> createState() => _PhoneNumberButtonState();
}

class _PhoneNumberButtonState extends State<PhoneNumberButton> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _phoneFocusNode = FocusNode();

  bool _otpSent = false;
  Timer? _resendTimer;
  int _resendSeconds = 0;
  bool _loading = false;
  bool _phonePickerDone = false;
  bool _hintLoading = false;
  // True only when the number came straight from the device's own SIM.
  // The server still requires a verified OTP for every login — this only
  // skips manual number entry, not verification. Any manual edit clears it.
  bool _phoneFromSim = false;
  bool _settingPhoneProgrammatically = false;
  String? _normalizedPhone;
  String? _error;
  StreamSubscription<dynamic>? _otpSub;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(() {
      if (_settingPhoneProgrammatically) return;
      if (_phoneFromSim) setState(() => _phoneFromSim = false);
    });
  }

  void _setPhoneText(String value, {bool fromSim = false}) {
    _settingPhoneProgrammatically = true;
    _phoneCtrl.text = value;
    _settingPhoneProgrammatically = false;
    _phoneFromSim = fromSim;
  }

  /// Starts the SMS User Consent listener (no READ_SMS/RECEIVE_SMS permission
  /// needed — shows a one-time system "Allow [app] to read this message?"
  /// prompt for the next incoming SMS). If it's unavailable, dismissed, or
  /// denied, the OTP field is still there for manual entry.
  Future<void> _startOtpListener() async {
    try {
      await _phoneNativeChannel.invokeMethod('startSmsListener');
    } catch (_) {
      return;
    }
    _otpSub = _otpEventChannel.receiveBroadcastStream().listen((dynamic value) {
      if (value is String && value.length == 6 && mounted && !_loading) {
        _otpCtrl.text = value;
        _stopOtpListener();
        _verifyAndLogin();
      }
    });
  }

  void _stopOtpListener() {
    _otpSub?.cancel();
    _otpSub = null;
    _phoneNativeChannel.invokeMethod<void>('stopSmsListener').ignore();
  }

  @override
  void dispose() {
    _stopOtpListener();
    _resendTimer?.cancel();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  /// Tapping the (still read-only) phone field tries to fill in the number
  /// from the device's SIM(s). If the user picks/confirms one, it's filled
  /// in; if it fails, is cancelled, or isn't available, the field switches
  /// to normal manual entry.
  Future<void> _onPhoneFieldTap() async {
    if (_phonePickerDone) return;
    setState(() => _hintLoading = true);

    // Step 1: native SubscriptionManager lookup — the reliable path on Indian
    // carriers (Airtel/Jio), where Play services' phone-number hint API
    // usually returns nothing.
    List<Map<String, dynamic>> simNumbers = [];
    try {
      final raw = await _phoneNativeChannel.invokeListMethod<Map>(
        'getSimNumbers',
      );
      simNumbers = raw?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    } catch (_) {
      // Channel/permission unavailable — fall through to the hint API.
    }
    if (!mounted) return;

    if (simNumbers.length > 1) {
      setState(() => _hintLoading = false);
      await _showSimPicker(simNumbers);
      return;
    }

    if (simNumbers.length == 1) {
      final phone = _normalizeIndianPhone(
        simNumbers.first['number'] as String?,
      );
      if (phone != null) {
        setState(() {
          _hintLoading = false;
          _phonePickerDone = true;
          _setPhoneText(phone.replaceFirst('+91', ''), fromSim: true);
        });
        return;
      }
    }

    // Step 2: fall back to the Play services phone-number hint. Not from the
    // SIM directly, so this still requires OTP verification.
    String? phone;
    try {
      final raw = await SmsAutoFill().hint;
      phone = _normalizeIndianPhone(raw);
    } catch (_) {
      phone = null;
    }
    if (!mounted) return;
    setState(() {
      _hintLoading = false;
      _phonePickerDone = true;
      if (phone != null) _setPhoneText(phone.replaceFirst('+91', ''));
    });
    if (phone == null) {
      FocusScope.of(context).requestFocus(_phoneFocusNode);
    }
  }

  Future<void> _showSimPicker(List<Map<String, dynamic>> simNumbers) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SimPickerSheet(simNumbers: simNumbers),
    );
    if (!mounted) return;
    setState(() {
      _phonePickerDone = true;
      if (result != null && result != '__manual__') {
        final phone = _normalizeIndianPhone(result) ?? result;
        _setPhoneText(phone.replaceFirst('+91', ''), fromSim: true);
      }
    });
    if (result == null || result == '__manual__') {
      FocusScope.of(context).requestFocus(_phoneFocusNode);
    }
  }

  Future<void> _sendOtp() async {
    if (_loading) return;
    final phone = _normalizeIndianPhone(_phoneCtrl.text.trim());
    if (phone == null || !phone.startsWith('+91') || phone.length != 13) {
      setState(() => _error = 'Enter a valid 10-digit mobile number');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await apiService.sendOtp(phone);
      if (!mounted) return;
      _stopOtpListener();
      _startOtpListener();
      _resendTimer?.cancel();
      _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || _resendSeconds <= 1) {
          timer.cancel();
          if (mounted) setState(() => _resendSeconds = 0);
        } else {
          setState(() => _resendSeconds--);
        }
      });
      setState(() {
        _normalizedPhone = phone;
        _otpSent = true;
        _otpCtrl.clear();
        _resendSeconds = 30;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _extractError(e, 'Failed to send OTP. Please try again.');
      });
    }
  }

  Future<void> _verifyAndLogin() async {
    if (_loading) return;
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit OTP sent to your phone');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    if (widget.verifyOnly) {
      final result = await auth.verifyPhone(phone: _normalizedPhone!, otp: otp);
      // Before the mounted check: success flips needsPhoneVerification, so the
      // router may already be taking this screen down.
      if (result != null) widget.onPhoneVerified!(result == 'merged');
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (result == null) {
          _error = auth.error ?? 'Incorrect OTP. Please try again.';
        }
      });
      return;
    }
    final success = await auth.loginWithPhoneNumber(
      phone: _normalizedPhone!,
      otp: otp,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      _afterLogin(_normalizedPhone!);
    } else {
      setState(() => _error = auth.error ?? 'Incorrect OTP. Please try again.');
    }
  }

  /// Handles both OTP and Truecaller success. Already-registered users go
  /// straight in; only newly created / incomplete accounts are asked to
  /// complete their profile.
  void _afterLogin(String phone) {
    final auth = context.read<AuthProvider>();
    if (auth.isNewUser || _isProfileIncomplete(auth.user)) {
      _showProfileSheet(phone);
    } else {
      widget.onSuccess?.call();
    }
  }

  void _showProfileSheet(String phone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder:
          (_) => _ProfileSheet(
            phone: phone,
            prefillReferral: widget.prefillReferral,
            onSuccess: widget.onSuccess,
          ),
    );
  }

  String _extractError(Object e, String fallback) {
    // Try to pull the message out of a DioException response body.
    try {
      final dynamic ex = e;
      final data = ex.response?.data;
      if (data is Map) {
        final msg = data['message']?.toString() ?? data['error']?.toString();
        if (msg != null && msg.isNotEmpty) return msg;
      }
    } catch (_) {}
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Truecaller: invoked silently on load, no button of its own. If the
        // user isn't a Truecaller user, dismisses, or the SDK isn't usable,
        // this stays invisible and the phone/OTP form below just works.
        if (!widget.verifyOnly)
          _TruecallerSection(
            onSuccess: widget.onSuccess,
            onNeedsProfile: _showProfileSheet,
          ),

        if (!_otpSent) ...[
          Text(
            widget.verifyOnly
                ? 'Your mobile number'
                : 'Continue with your phone',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            focusNode: _phoneFocusNode,
            enabled: !_loading,
            autofillHints: const [AutofillHints.telephoneNumberNational],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _sendOtp(),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            readOnly: !_phonePickerDone,
            onTap: _onPhoneFieldTap,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Mobile number',
              helperText: 'We will send a 6-digit verification code.',
              prefixIcon:
                  _hintLoading
                      ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                      : const Icon(Icons.phone_outlined),
              prefixText: '+91  ',
              hintText: '9876543210',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            _ErrorBanner(message: _error!),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _sendOtp,
              child:
                  _loading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        'Send verification code',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
        ] else ...[
          Text(
            'Check your messages',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 14,
                color: Colors.green[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Code sent to $_normalizedPhone',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _otpCtrl,
            enabled: !_loading,
            autofillHints: const [AutofillHints.oneTimeCode],
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.number,
            autofocus: true,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              letterSpacing: 6,
              fontWeight: FontWeight.bold,
            ),
            onChanged: (val) {
              if (val.length == 6 && !_loading) _verifyAndLogin();
            },
            decoration: const InputDecoration(
              labelText: 'Verification code',
              hintText: '000000',
              helperText: 'Enter or paste the code from your SMS.',
              counterText: '',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            _ErrorBanner(message: _error!),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _verifyAndLogin,
              child:
                  _loading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text(
                        'Verify and continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed:
                  _loading
                      ? null
                      : () {
                        _stopOtpListener();
                        setState(() {
                          _otpSent = false;
                          _otpCtrl.clear();
                          _error = null;
                        });
                      },
              child: Text(
                'Change phone number',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
          ),
          TextButton(
            onPressed: _loading || _resendSeconds > 0 ? null : _sendOtp,
            child: Text(
              _resendSeconds > 0
                  ? 'Resend code in ${_resendSeconds}s'
                  : 'Resend code',
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Profile completion sheet shown after phone/Truecaller login ─────────────

class _ProfileSheet extends StatefulWidget {
  final String phone;
  final String? prefillReferral;
  final VoidCallback? onSuccess;

  const _ProfileSheet({
    required this.phone,
    this.prefillReferral,
    this.onSuccess,
  });

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  String _selectedRole = 'buyer';
  bool _roleAccepted = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefillReferral != null && widget.prefillReferral!.isNotEmpty) {
      _referralCtrl.text = widget.prefillReferral!;
    } else {
      ReferralService.getPendingCode().then((code) {
        if (code != null && code.isNotEmpty && mounted) {
          _referralCtrl.text = code;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }

    final auth = context.read<AuthProvider>();
    final email = _emailCtrl.text.trim();

    // Roles requiring admin approval (Associate Partner, Telecaller, Lead
    // Manager) are never sent as a registration/profile role directly. Use
    // "guest" for the actual account — guest-tier access, 7-day clock, see
    // Profile::guest_expires_at — until admin approves, then auto-file the
    // role-change request below so the user doesn't have to do it separately
    // afterward.
    final requiresApproval = AppConstants.roleRequiresApproval(_selectedRole);
    final roleToSend = requiresApproval ? 'guest' : _selectedRole;

    bool success;
    if (auth.isAuthenticated) {
      // Already registered and logged in via phone — only the profile needs
      // completing, no further login step.
      success = await auth.updateProfile({
        'name': name,
        if (email.isNotEmpty) 'email': email,
        'role': roleToSend,
      });
    } else {
      success = await auth.loginWithPhoneNumber(
        phone: widget.phone,
        name: name,
        role: roleToSend,
        email: email.isEmpty ? null : email,
      );

      if (success) {
        final user = auth.user;
        final needsUpdate =
            user != null &&
            (user.name != name ||
                (email.isNotEmpty && user.email != email) ||
                (user.profile?.role != roleToSend));

        if (needsUpdate) {
          await auth.updateProfile({
            'name': name,
            if (email.isNotEmpty) 'email': email,
            'role': roleToSend,
          });
        }
      }
    }

    if (!mounted) return;

    if (success) {
      final ref = _referralCtrl.text.trim();
      if (ref.isNotEmpty) {
        apiService.trackReferral(ref).ignore();
        ReferralService.markUsed().ignore();
      }
      // The call above already stamped role_confirmed_at server-side
      // (AuthController::updateProfile or ::phoneLogin — role is always
      // sent from this same RolePicker used on the email signup page), so
      // home_screen.dart's mandatory role prompt won't ask again.
      if (requiresApproval) {
        try {
          await apiService.requestRoleChange(_selectedRole);
        } catch (_) {
          // Account is already set up — the user can still file the request
          // later from Settings if this follow-up call failed.
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
      Navigator.of(context).pop();
      widget.onSuccess?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Login failed. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Complete Your Profile',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Phone: ${widget.phone}',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            RolePicker(
              selectedRole: _selectedRole,
              onRoleChanged: (value) => setState(() => _selectedRole = value),
              accepted: _roleAccepted,
              onAcceptedChanged:
                  (value) => setState(() => _roleAccepted = value),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _referralCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Referral Code (optional)',
                prefixIcon: Icon(Icons.redeem),
                hintText: 'e.g. NEE123',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    (auth.loading ||
                            (RolePicker.isTeamRole(_selectedRole) &&
                                !_roleAccepted))
                        ? null
                        : _submit,
                child:
                    auth.loading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SIM picker shown when multiple SIMs are detected ────────────────────────

class _SimPickerSheet extends StatelessWidget {
  final List<Map<String, dynamic>> simNumbers;

  const _SimPickerSheet({required this.simNumbers});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select Your Number',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Multiple SIM cards detected on this device',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 16),
          ...simNumbers.map((sim) {
            final number = sim['number'] as String? ?? '';
            final slot = (sim['slot'] as int? ?? 0) + 1;
            final carrier = sim['carrier'] as String? ?? 'SIM $slot';
            final normalized = _normalizeIndianPhone(number);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '$slot',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              title: Text(
                normalized ?? number,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                carrier,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, normalized ?? number),
            );
          }),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.keyboard_outlined),
            title: const Text('Enter number manually'),
            onTap: () => Navigator.pop(context, '__manual__'),
          ),
        ],
      ),
    );
  }
}

// ─── Truecaller 1-tap login ───────────────────────────────────────────────────
//
// Renders no UI of its own. On load it silently checks whether Truecaller is
// installed and usable, and if so, immediately invokes the native Truecaller
// consent overlay (no button tap required). On success the user is logged in
// instantly with no OTP. On failure, dismiss, or if Truecaller isn't usable,
// it silently does nothing — the phone/OTP form is already on screen underneath.

class _TruecallerSection extends StatefulWidget {
  final VoidCallback? onSuccess;
  final void Function(String phone)? onNeedsProfile;

  const _TruecallerSection({this.onSuccess, this.onNeedsProfile});

  @override
  State<_TruecallerSection> createState() => _TruecallerSectionState();
}

class _TruecallerSectionState extends State<_TruecallerSection> {
  StreamSubscription<TcSdkCallback>? _sub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      // truecaller_sdk 1.2.0's native INITIALIZE_SDK handler never calls
      // result.success() on its happy path, so awaiting this hangs forever.
      // Fire it without awaiting — the platform channel still processes it
      // (and TcSdk.init()) before the isOAuthFlowUsable call below runs.
      unawaited(
        TcSdk.initializeSDK(
          sdkOption: TcSdkOptions.OPTION_VERIFY_ONLY_TC_USERS,
          consentHeadingOption:
              TcSdkOptions.SDK_CONSENT_HEADING_LOGIN_TO_WITH_ONE_TAP,
          footerType: TcSdkOptions.FOOTER_TYPE_SKIP,
          ctaText: TcSdkOptions.CTA_TEXT_CONTINUE_WITH,
          buttonShapeOption: TcSdkOptions.BUTTON_SHAPE_ROUNDED,
          buttonColor: 0xFF1565C0,
          buttonTextColor: 0xFFFFFFFF,
        ),
      );
      final usable = await TcSdk.isOAuthFlowUsable;
      _sub = TcSdk.streamCallbackData.listen(_onResult);
      if (mounted && usable == true) _trigger();
    } catch (_) {
      // Partner key invalid or Truecaller not installed — silently skip.
    }
  }

  Future<void> _trigger() async {
    // PKCE setup required by Truecaller OAuth 2.0
    final verifier = await TcSdk.generateRandomCodeVerifier;
    final challenge = await TcSdk.generateCodeChallenge(verifier.toString());
    if (challenge == null) return;
    // setCodeChallenge/setOAuthScopes/setOAuthState/getAuthorizationCode never
    // resolve their method-channel result on the native side (same plugin bug
    // as initializeSDK) — fire them without awaiting. The platform channel
    // processes calls in order, and the actual result arrives via
    // streamCallbackData (_onResult), not these futures.
    unawaited(TcSdk.setCodeChallenge(challenge.toString()));
    unawaited(TcSdk.setOAuthScopes(['phone', 'openid']));
    unawaited(
      TcSdk.setOAuthState(DateTime.now().millisecondsSinceEpoch.toString()),
    );
    unawaited(TcSdk.getAuthorizationCode);
  }

  Future<void> _onResult(TcSdkCallback callback) async {
    if (!mounted) return;
    // Failure/dismiss/cancel: silently fall through to the phone/OTP form.
    if (callback.result != TcSdkCallbackResult.success) return;

    final auth = context.read<AuthProvider>();
    final code = callback.tcOAuthData?.authorizationCode ?? '';
    final state = callback.tcOAuthData?.state ?? '';
    final ok = await auth.loginWithTrueCaller(
      authorizationCode: code,
      state: state,
    );
    if (!mounted || !ok) return;

    final phone = auth.user?.phone ?? '';
    if (auth.isNewUser || _isProfileIncomplete(auth.user)) {
      widget.onNeedsProfile?.call(phone);
    } else {
      widget.onSuccess?.call();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
