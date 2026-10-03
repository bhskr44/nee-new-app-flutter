import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'telecaller_lead_managers_screen.dart';
import 'telecaller_my_leads_screen.dart';
import 'telecaller_pool_screen.dart';
import 'telecaller_processed_leads_screen.dart';
import 'telecaller_visit_status_screen.dart';

class TelecallerShell extends StatefulWidget {
  const TelecallerShell({super.key});

  @override
  State<TelecallerShell> createState() => _TelecallerShellState();
}

class _TelecallerShellState extends State<TelecallerShell> {
  int _index = 0;

  static const _screens = [
    TelecallerPoolScreen(),
    TelecallerMyLeadsScreen(),
    TelecallerProcessedLeadsScreen(),
    TelecallerVisitStatusScreen(),
    TelecallerLeadManagersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          auth.user != null ? 'Telecaller — ${auth.user!.name}' : 'Telecaller',
        ),
        // Telecalling Mode is a toggle now, not a locked-in destination — the
        // default back button (this route is always reached via a push, from
        // Settings) takes them back to the regular app.
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: const Text('Log out?'),
                      content: const Text(
                        'You will need to sign in again to access your leads.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Stay signed in'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Log out'),
                        ),
                      ],
                    ),
              );
              if (confirmed == true) await auth.logout();
            },
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.call_outlined),
            selectedIcon: Icon(Icons.call_rounded),
            label: 'Leads to Call',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'My Leads',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Processed',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded),
            label: 'Visit Status',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Lead Managers',
          ),
        ],
      ),
    );
  }
}
