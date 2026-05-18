import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Shows a "Continue with TrueCaller" button. The native TrueCaller SDK works
/// on Android; unsupported platforms show the same entry with a helpful message.
class TrueCallerButton extends StatefulWidget {
  final VoidCallback? onSuccess;

  const TrueCallerButton({super.key, this.onSuccess});

  @override
  State<TrueCallerButton> createState() => _TrueCallerButtonState();
}

class _TrueCallerButtonState extends State<TrueCallerButton> {
  static const _channel = MethodChannel('com.nee.construction/truecaller');

  bool _available = false;
  bool _checkedAvailability = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    try {
      final available = await _channel.invokeMethod<bool>('isAvailable') ?? false;
      if (mounted) {
        setState(() {
          _available = available;
          _checkedAvailability = true;
        });
      }
    } on PlatformException {
      if (mounted) setState(() => _checkedAvailability = true);
      // TrueCaller not available — show nothing
    }
  }

  Future<void> _initiateTrueCaller() async {
    setState(() => _loading = true);
    try {
      // OAuth SDK 3.x: returns authorization_code + state; backend exchanges for profile
      final result = await _channel.invokeMapMethod<String, dynamic>('getProfile');
      if (result == null) throw PlatformException(code: 'NULL_RESULT');

      final authorizationCode = result['authorization_code'] as String? ?? '';
      final state            = result['state'] as String? ?? '';

      if (authorizationCode.isEmpty) throw PlatformException(code: 'NO_AUTH_CODE');

      final auth = context.read<AuthProvider>();
      final success = await auth.loginWithTrueCaller(
        authorizationCode: authorizationCode,
        state: state,
      );

      if (!mounted) return;
      if (success) {
        widget.onSuccess?.call();
      } else {
        final message = auth.error ?? 'TrueCaller login failed. Please use email.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'USER_CANCELLED'
          ? 'Cancelled'
          : 'TrueCaller login failed. Please use email.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildButton(
        enabled: true,
        onPressed: _showUnavailableMessage,
      );
    }

    if (!_checkedAvailability) return const SizedBox.shrink();

    if (!_available) {
      return _buildButton(
        enabled: true,
        onPressed: _showUnavailableMessage,
      );
    }

    return _buildButton(
      enabled: !_loading,
      onPressed: _initiateTrueCaller,
    );
  }

  Widget _buildButton({
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF1980F5), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.white,
        ),
        child: _loading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1980F5)),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TcLogo(),
                  const SizedBox(width: 10),
                  const Text(
                    'Continue with TrueCaller',
                    style: TextStyle(
                      color: Color(0xFF1980F5),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showUnavailableMessage() {
    final message = kIsWeb
        ? 'TrueCaller login is available in the Android app.'
        : defaultTargetPlatform == TargetPlatform.android
            ? 'Install or sign in to TrueCaller, then try again.'
            : 'TrueCaller login is available on Android.';

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TcLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22, height: 22,
      decoration: BoxDecoration(
        color: const Color(0xFF1980F5),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: const Text(
        'T',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}
