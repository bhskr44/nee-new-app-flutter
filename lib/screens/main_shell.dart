import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import 'calculator_screen.dart';
import 'community/community_screen.dart';
import 'home_screen.dart';
import 'products_screen.dart';

class _NavTab {
  final String? featureKey; // null = always shown (Home)
  final Widget screen;
  final NavigationDestination destination;
  const _NavTab(this.featureKey, this.screen, this.destination);
}

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  late int _index;
  final _visited = <int>{0};

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, _allTabs.length - 1);
    _visited.add(_index);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().refreshUser();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AuthProvider>().refreshUser();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  static const _allTabs = [
    _NavTab(
      null,
      HomeScreen(),
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
    ),
    _NavTab(
      'community',
      CommunityScreen(),
      NavigationDestination(
        icon: Icon(Icons.groups_outlined),
        selectedIcon: Icon(Icons.groups_rounded),
        label: 'Community',
      ),
    ),
    _NavTab(
      'products',
      ProductsScreen(),
      NavigationDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2_rounded),
        label: 'Products',
      ),
    ),
    _NavTab(
      'calculator',
      CalculatorScreen(),
      NavigationDestination(
        icon: Icon(Icons.calculate_outlined),
        selectedIcon: Icon(Icons.calculate_rounded),
        label: 'Calculator',
      ),
    ),
  ];

  Future<bool> _confirmExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Exit App?'),
            content: const Text('Are you sure you want to close the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final flags = user?.featureFlags ?? const {};
    final role = user?.profile?.role ?? 'buyer';
    // Calculator is an internal tool for the field team and admin —
    // customer-facing roles never see this tab. (Leads aren't a tab: the
    // customers-only Market Place opens from the home screen.)
    final teamOrAdmin = AppConstants.isTeamOrAdmin(role);
    final visible = [
      for (var i = 0; i < _allTabs.length; i++)
        if ((_allTabs[i].featureKey == null ||
                (flags[_allTabs[i].featureKey] ?? true)) &&
            !(_allTabs[i].featureKey == 'calculator' && !teamOrAdmin))
          i,
    ];
    final active = visible.contains(_index) ? _index : 0;
    final index = visible.indexOf(active);
    final tabs = [for (final i in visible) _allTabs[i]];
    final wide = MediaQuery.sizeOf(context).width >= 800;
    void select(int value) {
      FocusScope.of(context).unfocus();
      setState(() {
        _index = visible[value];
        _visited.add(_index);
      });
    }

    final content = IndexedStack(
      index: active,
      children: [
        for (var i = 0; i < _allTabs.length; i++)
          TickerMode(
            enabled: i == active,
            child:
                _visited.contains(i) && visible.contains(i)
                    ? _allTabs[i].screen
                    : const SizedBox.shrink(),
          ),
      ],
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (active != 0) {
          setState(() => _index = 0);
          return;
        }
        if (await _confirmExit()) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body:
            wide && tabs.length > 1
                ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: index,
                      labelType: NavigationRailLabelType.all,
                      onDestinationSelected: select,
                      destinations: [
                        for (final tab in tabs)
                          NavigationRailDestination(
                            icon: tab.destination.icon,
                            selectedIcon: tab.destination.selectedIcon,
                            label: Text(tab.destination.label),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                )
                : content,
        bottomNavigationBar:
            wide || tabs.length < 2
                ? null
                : NavigationBar(
                  selectedIndex: index,
                  onDestinationSelected: select,
                  destinations: [for (final tab in tabs) tab.destination],
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                ),
      ),
    );
  }
}
