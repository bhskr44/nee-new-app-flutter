import 'package:go_router/go_router.dart';

import 'constants.dart';
import '../providers/auth_provider.dart';
import '../screens/account_frozen_screen.dart';
import '../screens/onboarding_location_screen.dart';
import '../screens/area_contacts_screen.dart';
import '../screens/associate_partner/dashboard_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/email_login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/verify_phone_screen.dart';
import '../screens/business_screen.dart';
import '../screens/calculator_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/community/community_screen.dart';
import '../screens/coverage_districts_screen.dart';
import '../screens/funding_screen.dart';
import '../screens/jobs_screen.dart';
import '../screens/leads_screen.dart';
import '../screens/main_shell.dart';
import '../screens/manpower_screen.dart';
import '../screens/my_estimates_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/products_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/request_estimate_screen.dart';
import '../screens/my_estimate_requests_screen.dart';
import '../screens/role_request_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/house_calculator_screen.dart';
import '../screens/my_field_visits_screen.dart';
import '../screens/solar_calculator_screen.dart';
import '../screens/auth/change_password_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/telecaller/telecaller_shell.dart';
import '../screens/wallet_screen.dart';

class AppRouter {
  static GoRouter? _instance;

  static GoRouter get instance {
    assert(_instance != null, 'Call AppRouter.build() first');
    return _instance!;
  }

  static GoRouter build(AuthProvider auth) {
    _instance = GoRouter(
      initialLocation: '/splash',
      refreshListenable: auth,
      redirect: (context, state) {
        final status = auth.status;
        final onSplash = state.matchedLocation == '/splash';

        // Stay on splash while auth check is in progress
        if (status == AuthStatus.unknown) {
          return onSplash ? null : '/splash';
        }

        final isAuth = status == AuthStatus.authenticated;
        final onAuthRoute =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/login/email' ||
            state.matchedLocation == '/register';

        // Area Managers (telecaller role) use the regular app like everyone
        // else — "/telecaller" is a normal route they toggle into from
        // Settings ("Telecalling Mode") and back out of, not a forced mode.

        // Leave splash once auth resolves
        if (onSplash) {
          return isAuth ? '/' : '/login';
        }

        if (!isAuth && !onAuthRoute) return '/login';
        if (isAuth && onAuthRoute) return '/';

        if (isAuth) {
          // A frozen (pending-approval past 7 days, or expired guest) account is
          // locked to its own status screen — everything else, including signing
          // out, happens from there.
          final onFrozenScreen = state.matchedLocation == '/account-frozen';
          if (auth.isFrozen && !onFrozenScreen) return '/account-frozen';
          if (!auth.isFrozen && onFrozenScreen) return '/';

          // Google sign-in without a verified phone: prompt first (a merge into
          // an existing account may make onboarding below unnecessary). Not a
          // hard lock — dismissing lets the user look around; the backend's
          // PHONE_NOT_VERIFIED on the next action brings it back.
          final onVerifyPhone = state.matchedLocation == '/verify-phone';
          if (auth.shouldPromptPhoneVerification && !onVerifyPhone) {
            return '/verify-phone';
          }
          if (!auth.shouldPromptPhoneVerification && onVerifyPhone) return '/';
          // Stay put while prompting — falling through to the onboarding check
          // below would bounce to /onboarding-location, which bounces straight
          // back here (redirect loop for a new Google user with no location).
          if (onVerifyPhone) return null;

          // First-run onboarding: capture name + work location once, right
          // after registration/first login, before entering the main app.
          // Mandatory — no skip.
          // A blank name also counts as incomplete — users:reset-incomplete-addresses
          // blanks placeholder names, and an address-only profile (no coordinates
          // to clear) would otherwise slip past with no name.
          final onOnboardingLocation =
              state.matchedLocation == '/onboarding-location';
          final profile = auth.user?.profile;
          final nameMissing = (auth.user?.name.trim() ?? '').isEmpty;
          if (profile != null) {
            final needsOnboarding = !profile.hasLocation || nameMissing;
            if (!auth.isFrozen && needsOnboarding && !onOnboardingLocation) {
              return '/onboarding-location';
            }
            if (!needsOnboarding && onOnboardingLocation) return '/';
          }

          // Team-only tools (Calculator, Leads/Market-Place) and My Field
          // Visits are hidden from their normal UI entry points for
          // customer-facing roles / non-Lead-Managers (see
          // home_screen.dart's _visibleSegmentIndices, main_shell.dart's tab
          // `visible` list), but a deep link or shared URL can jump straight
          // to the route — this is the backstop that catches that too.
          final role = auth.user?.profile?.role ?? 'buyer';
          final location = state.matchedLocation;
          if (location == '/calculator' && !AppConstants.isTeamOrAdmin(role)) {
            return '/';
          }
          final blockLeads = role == 'guest' ||
              (auth.user?.profile?.isPendingApproval ?? false);
          if (location.startsWith('/leads') &&
              (blockLeads || !AppConstants.canUseMarketplace(role))) {
            return '/';
          }
          if (location == '/my-field-visits' &&
              !(auth.user?.isLeadManager ?? false)) {
            return '/';
          }
        }

        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
        GoRoute(path: '/', builder: (_, _) => const MainShell()),
        GoRoute(
          path: '/account-frozen',
          builder: (_, _) => const AccountFrozenScreen(),
        ),
        GoRoute(
          path: '/verify-phone',
          builder: (_, _) => const VerifyPhoneScreen(),
        ),
        GoRoute(
          path: '/onboarding-location',
          builder: (_, _) => const OnboardingLocationScreen(),
        ),
        GoRoute(
          path: '/telecaller',
          builder: (_, _) => const TelecallerShell(),
        ),
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(
          path: '/login/email',
          builder: (_, _) => const EmailLoginScreen(),
        ),
        GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
        GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const NotificationsScreen(),
        ),
        GoRoute(path: '/community', builder: (_, _) => const CommunityScreen()),
        GoRoute(path: '/products', builder: (_, _) => const ProductsScreen()),
        GoRoute(
          path: '/request-estimate',
          builder: (_, _) => const RequestEstimateScreen(),
        ),
        GoRoute(
          path: '/my-estimate-requests',
          builder: (_, _) => const MyEstimateRequestsScreen(),
        ),
        GoRoute(path: '/workers', builder: (_, _) => const ManpowerScreen()),
        GoRoute(path: '/leads', builder: (_, _) => const LeadsScreen()),
        GoRoute(
          path: '/my-field-visits',
          builder: (_, _) => const MyFieldVisitsScreen(),
        ),
        GoRoute(
          path: '/calculator',
          builder: (_, _) => const CalculatorScreen(),
        ),
        GoRoute(path: '/funding', builder: (_, _) => const FundingScreen()),
        GoRoute(path: '/business', builder: (_, _) => const BusinessScreen()),
        GoRoute(path: '/jobs', builder: (_, _) => const JobsScreen()),
        GoRoute(
          path: '/contacts',
          builder: (_, _) => const AreaContactsScreen(),
        ),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        GoRoute(path: '/wallet', builder: (_, _) => const WalletScreen()),
        GoRoute(
          path: '/role-request',
          builder: (_, _) => const RoleRequestScreen(),
        ),
        GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
        GoRoute(
          path: '/my-estimates',
          builder: (_, _) => const MyEstimatesScreen(),
        ),
        GoRoute(
          path: '/coverage-districts',
          builder: (_, _) => const CoverageDistrictsScreen(),
        ),
        GoRoute(
          path: '/associate-partner-dashboard',
          builder: (_, _) => const AssociatePartnerDashboardScreen(),
        ),
        GoRoute(
          path: '/change-password',
          builder: (_, _) => const ChangePasswordScreen(),
        ),
        GoRoute(
          path: '/house-calculator',
          builder: (_, _) => const HouseCalculatorScreen(),
        ),
        GoRoute(
          path: '/interior-calculator',
          builder: (_, _) => const InteriorCalculatorScreen(),
        ),
        GoRoute(
          path: '/solar-calculator',
          builder: (_, _) => const SolarCalculatorScreen(),
        ),
      ],
    );
    return _instance!;
  }
}
