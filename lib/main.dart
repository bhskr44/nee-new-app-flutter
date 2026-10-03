import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/clarity_service.dart';
import 'package:provider/provider.dart';
import 'widgets/force_update_overlay.dart';

import 'config/router.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/area_contact_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/community_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/funding_provider.dart';
import 'providers/job_provider.dart';
import 'providers/lead_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/product_provider.dart';
import 'providers/telecaller_provider.dart';
import 'providers/worker_provider.dart';
import 'services/code_push_service.dart';
import 'services/deep_link_service.dart';
import 'services/notification_service.dart';
import 'services/referral_service.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Keep the native splash visible until we're ready to show the Flutter UI
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // Firebase — add google-services.json to android/app/ before enabling
  try {
    await Firebase.initializeApp();
    await notificationService.initialize();
  } catch (_) {
    // Firebase not configured yet — notifications disabled in dev
  }

  // Read Play Install Referrer so registration screens can auto-fill the code
  await ReferralService.initialize();

  // Dismiss native splash; the animated Flutter splash screen takes over
  FlutterNativeSplash.remove();

  runApp(
    ForceUpdateOverlay(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider()..checkAuthStatus(),
          ),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => DashboardProvider()..init()),
          ChangeNotifierProvider(create: (_) => ProductProvider()..fetch()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => WorkerProvider()..fetch()),
          ChangeNotifierProvider(create: (_) => LeadProvider()..fetch()),
          ChangeNotifierProvider(
            create:
                (_) =>
                    JobProvider()
                      ..fetchJobs()
                      ..fetchCourses(),
          ),
          ChangeNotifierProvider(create: (_) => FundingProvider()..fetch()),
          ChangeNotifierProvider(create: (_) => AreaContactProvider()..fetch()),
          // No eager fetch: telecaller endpoints require the telecaller role,
          // so this loads only once a telecaller screen is opened.
          ChangeNotifierProvider(create: (_) => TelecallerProvider()),
          // No eager fetch: community endpoints require auth, loads when the tab opens.
          ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ],
        child: const NEEApp(),
      ),
    ),
  );
}

class NEEApp extends StatefulWidget {
  const NEEApp({super.key});

  @override
  State<NEEApp> createState() => _NEEAppState();
}

class _NEEAppState extends State<NEEApp> with WidgetsBindingObserver {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CodePushService.instance.checkAndPrompt(_messengerKey);

      // Microsoft Clarity — session recording & heatmaps (mobile only)
      initClarity(context);

      // Wire deep links into the router
      final router = AppRouter.instance;
      deepLinkService.setRouter(router);
      deepLinkService.initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Telecallers keep the app open all day — also check when it comes back
    // to the foreground, not just on cold start.
    if (state == AppLifecycleState.resumed) {
      CodePushService.instance.checkAndPrompt(_messengerKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NEE Platform',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      routerConfig: AppRouter.build(context.read<AuthProvider>()),
      scrollBehavior: const AppScrollBehavior(),
      theme: AppTheme.light(textTheme: GoogleFonts.poppinsTextTheme()),
    );
  }
}
