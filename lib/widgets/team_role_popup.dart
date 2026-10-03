import 'package:flutter/material.dart';
import '../config/constants.dart';
import 'role_picker.dart';

/// Mandatory role-confirmation popup for accounts that have never explicitly
/// gone through a RolePicker screen — i.e. every account that predates that
/// flow, still sitting on the 'buyer' default nobody actually chose (see
/// ProfileModel.needsRoleConfirmation). Shows the *entire* role list, the
/// same RolePicker used at signup — they can explicitly confirm they're
/// staying a Buyer/Client, or pick something else. No dismiss: closing it
/// requires picking a role and hitting confirm. Purely a selection UI: it
/// pops with the chosen role value and does no network calls itself. The
/// caller (HomeScreen) performs the actual role change *after* this dialog
/// has fully closed — doing it here would race GoRouter's own redirect (e.g.
/// becoming an Area Manager force-navigates to /telecaller) against this
/// dialog's own Navigator.pop(), which crashes with "popped the last page off
/// of the stack" when both try to touch the same Navigator at once.
class TeamRolePopup extends StatefulWidget {
  const TeamRolePopup({super.key});

  @override
  State<TeamRolePopup> createState() => _TeamRolePopupState();
}

class _TeamRolePopupState extends State<TeamRolePopup> {
  String _selectedRole = 'buyer';
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canConfirm = !RolePicker.isTeamRole(_selectedRole) || _accepted;

    return PopScope(
      // Mandatory — no back-button dismiss. showDialog is also called with
      // barrierDismissible: false, so tapping outside won't close it either.
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 620),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.badge_outlined, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Confirm Your Role',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Let us know how you'll use NEE, then confirm to continue.",
                  style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    child: RolePicker(
                      selectedRole: _selectedRole,
                      onRoleChanged: (value) => setState(() {
                        _selectedRole = value;
                        _accepted = false;
                      }),
                      accepted: _accepted,
                      onAcceptedChanged: (value) => setState(() => _accepted = value),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: canConfirm ? () => Navigator.of(context).pop(_selectedRole) : null,
                    child: Text(
                      'Confirm my role as ${AppConstants.roleLabel(_selectedRole)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
