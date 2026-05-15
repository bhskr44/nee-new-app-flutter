import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../providers/auth_provider.dart';

class PhoneNumberButton extends StatefulWidget {
  final VoidCallback? onSuccess;

  const PhoneNumberButton({super.key, this.onSuccess});

  @override
  State<PhoneNumberButton> createState() => _PhoneNumberButtonState();
}

class _PhoneNumberButtonState extends State<PhoneNumberButton> {
  bool _loading = false;

  Future<void> _continueWithPhone() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _showMessage('Phone number picker is available in the Android app.');
      return;
    }

    setState(() => _loading = true);
    try {
      final phone = await SmsAutoFill().hint;
      final normalized = _normalizePhone(phone);

      if (normalized == null) {
        _showMessage('No phone number was selected.');
        return;
      }

      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final success = await auth.loginWithPhoneNumber(phone: normalized);

      if (!mounted) return;
      if (success) {
        widget.onSuccess?.call();
      } else {
        _showMessage(auth.error ?? 'Phone login failed. Please try email.');
      }
    } catch (_) {
      if (mounted) _showMessage('Could not read a phone number from this device.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _normalizePhone(String? value) {
    final digits = value?.replaceAll(RegExp(r'[^\d+]'), '') ?? '';
    if (digits.isEmpty) return null;
    if (digits.startsWith('+')) return digits;

    final withoutLeadingZero = digits.replaceFirst(RegExp(r'^0+'), '');
    if (withoutLeadingZero.length == 10) return '+91$withoutLeadingZero';
    if (withoutLeadingZero.startsWith('91') && withoutLeadingZero.length == 12) {
      return '+$withoutLeadingZero';
    }
    return withoutLeadingZero;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _continueWithPhone,
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.phone_android),
        label: Text(_loading ? 'Checking phone...' : 'Use Phone Number'),
      ),
    );
  }
}
