import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';

/// Blocking screen shown for both frozen states the backend can put an
/// account into (see EnsureNotFrozen): an initial role-approval request that
/// ran past its 7-day window with no admin decision, or a guest account whose
/// fixed 7-day access has simply run out. The router redirects here instead
/// of the normal app shell whenever AuthProvider.isFrozen is true.
class AccountFrozenScreen extends StatelessWidget {
  const AccountFrozenScreen({super.key});

  static const _primary = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.user?.profile;
    final isGuest = profile?.role == 'guest';

    final message = auth.frozenMessage ??
        (isGuest
            ? "Your 7-day guest access has ended. Please register for a full account to continue."
            : "Your account is still pending admin approval. You'll get access as soon as it's reviewed.");

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84, height: 84,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGuest ? Icons.hourglass_bottom_rounded : Icons.pending_actions_rounded,
                  size: 40, color: _primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isGuest ? 'Guest access ended' : 'Approval pending',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
              ),
              const SizedBox(height: 28),
              if (!isGuest) ...[
                Text(
                  'Current role: ${AppConstants.roleLabel(profile?.role ?? '')}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 20),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => auth.logout(),
                  child: const Text('Sign out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
