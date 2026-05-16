import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/area_contacts_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/business_screen.dart';
import '../screens/calculator_screen.dart';
import '../screens/funding_screen.dart';
import '../screens/home_screen.dart';
import '../screens/jobs_screen.dart';
import '../screens/leads_screen.dart';
import '../screens/manpower_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/products_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/house_calculator_screen.dart';
import '../screens/auth/change_password_screen.dart';

class AppRouter {
  static GoRouter? _instance;

  static GoRouter get instance {
    assert(_instance != null, 'Call AppRouter.build() first');
    return _instance!;
  }

  static GoRouter build(AuthProvider auth) {
    _instance = GoRouter(
      initialLocation: '/',
      refreshListenable: auth,
      redirect: (context, state) {
        final status = auth.status;
        if (status == AuthStatus.unknown) return null; // still checking token

        final isAuth = status == AuthStatus.authenticated;
        final onAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        if (!isAuth && !onAuthRoute) return '/login'; // gate every route
        if (isAuth && onAuthRoute) return '/';        // already logged in
        return null;
      },
      routes: [
        GoRoute(path: '/',             builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/login',        builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/register',     builder: (_, _) => const RegisterScreen()),
        GoRoute(path: '/profile',      builder: (_, _) => const ProfileScreen()),
        GoRoute(path: '/notifications',builder: (_, _) => const NotificationsScreen()),
        GoRoute(path: '/products',     builder: (_, _) => const ProductsScreen()),
        GoRoute(path: '/workers',      builder: (_, _) => const ManpowerScreen()),
        GoRoute(path: '/leads',        builder: (_, _) => const LeadsScreen()),
        GoRoute(path: '/calculator',   builder: (_, _) => const CalculatorScreen()),
        GoRoute(path: '/funding',      builder: (_, _) => const FundingScreen()),
        GoRoute(path: '/business',     builder: (_, _) => const BusinessScreen()),
        GoRoute(path: '/jobs',         builder: (_, _) => const JobsScreen()),
        GoRoute(path: '/contacts',         builder: (_, _) => const AreaContactsScreen()),
        GoRoute(path: '/settings',          builder: (_, _) => const SettingsScreen()),
        GoRoute(path: '/change-password',  builder: (_, _) => const ChangePasswordScreen()),
        GoRoute(path: '/house-calculator', builder: (_, _) => const HouseCalculatorScreen()),
      ],
    );
    return _instance!;
  }
}
