import 'package:flutter/material.dart';
import '../config/constants.dart';

/// Role selector shown at first-time signup: simple chips for the everyday
/// marketplace roles, and full responsibility cards for the field-team roles
/// (Area Manager, Lead Manager, Associate Partner) — picking one of those
/// requires an explicit "I accept my role as …" checkbox before it can be
/// submitted, since they carry real duties beyond just using the app.
class RolePicker extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;
  final bool accepted;
  final ValueChanged<bool> onAcceptedChanged;

  const RolePicker({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.accepted,
    required this.onAcceptedChanged,
  });

  /// Whether the current selection needs the explicit acceptance checkbox.
  static bool isTeamRole(String role) => AppConstants.isTeamRole(role);

  void _selectRole(String value) {
    onRoleChanged(value);
    // A fresh selection always needs a fresh accept — never carry over
    // acceptance from a previously selected role.
    onAcceptedChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a...',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final role in AppConstants.customerRoles)
              ChoiceChip(
                avatar: Icon(
                  role.$3,
                  size: 18,
                  color:
                      selectedRole == role.$1
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.primary,
                ),
                label: Text(role.$2),
                selected: selectedRole == role.$1,
                showCheckmark: false,
                onSelected: (_) => _selectRole(role.$1),
                selectedColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color:
                      selectedRole == role.$1
                          ? theme.colorScheme.onPrimary
                          : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ExpansionTile(
          key: ValueKey(isTeamRole(selectedRole)),
          initiallyExpanded: isTeamRole(selectedRole),
          tilePadding: EdgeInsets.zero,
          title: Text(
            isTeamRole(selectedRole)
                ? 'Field team: ${AppConstants.roleLabel(selectedRole)}'
                : 'Want to join our field team?',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Explore roles and responsibilities.',
            style: TextStyle(fontSize: 13),
          ),
          children: [
            for (final role in AppConstants.teamRoles)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color:
                        selectedRole == role.$1
                            ? theme.colorScheme.primary
                            : const Color(0xFF98A2B3),
                    width: selectedRole == role.$1 ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      selected: selectedRole == role.$1,
                      leading: Icon(
                        selectedRole == role.$1
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                      ),
                      title: Text(
                        role.$2,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          role.$4,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Color(0xFF526071),
                          ),
                        ),
                      ),
                      onTap: () => _selectRole(role.$1),
                    ),
                    if (selectedRole == role.$1)
                      CheckboxListTile(
                        value: accepted,
                        onChanged: (value) => onAcceptedChanged(value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          'I accept my role as ${role.$2}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
