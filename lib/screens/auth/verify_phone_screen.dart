import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/referral_service.dart';
import '../../widgets/auth_page.dart';
import '../../widgets/phone_number_button.dart';

/// Shown by the router to a Google sign-in that hasn't verified a phone number
/// (AuthProvider.shouldPromptPhoneVerification). Deliberately skippable — back
/// or "Later" dismisses it for this session; the backend still refuses every
/// feature (PHONE_NOT_VERIFIED), which brings this screen back on the next
/// action, and it reappears on every app start until verified.
class VerifyPhoneScreen extends StatelessWidget {
  const VerifyPhoneScreen({super.key});

  void _onVerified(ScaffoldMessengerState messenger, bool merged) {
    if (!merged) {
      // A new Google signup's install-referral code couldn't be tracked until
      // now — /referrals/track was behind the phone gate too.
      ReferralService.getPendingCode().then((code) {
        if (code == null || code.isEmpty) return;
        apiService.trackReferral(code).ignore();
        ReferralService.markUsed().ignore();
      });
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          merged
              ? 'Number verified — signed in to your existing NEE account.'
              : 'Mobile number verified.',
        ),
      ),
    );
    // needsPhoneVerification is now false, so the router moves on by itself.
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    // App-level messenger: outlives this screen, which the router removes as
    // soon as verification succeeds.
    final messenger = ScaffoldMessenger.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) auth.dismissPhoneVerification();
      },
      child: AuthPage(
        title: 'Verify your number',
        subtitle:
            'Add your mobile number to use NEE. If it is already registered, '
            'we will sign you in to that account.',
        onBack: auth.dismissPhoneVerification,
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
              child: PhoneNumberButton(
                onPhoneVerified: (merged) => _onVerified(messenger, merged),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: auth.dismissPhoneVerification,
              child: const Text('Later'),
            ),
          ],
        ),
      ),
    );
  }
}
