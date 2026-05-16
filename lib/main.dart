import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/clarity_service.dart';
import 'package:provider/provider.dart';

import 'config/router.dart';
import 'providers/auth_provider.dart';
import 'providers/area_contact_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/funding_provider.dart';
import 'providers/job_provider.dart';
import 'providers/lead_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/product_provider.dart';
import 'providers/worker_provider.dart';
import 'services/deep_link_service.dart';
import 'services/notification_service.dart';

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

  // Dismiss native splash; the animated Flutter splash screen takes over
  FlutterNativeSplash.remove();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuthStatus()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()..init()),
        ChangeNotifierProvider(create: (_) => ProductProvider()..fetch()),
        ChangeNotifierProvider(create: (_) => WorkerProvider()..fetch()),
        ChangeNotifierProvider(create: (_) => LeadProvider()..fetch()),
        ChangeNotifierProvider(create: (_) => JobProvider()..fetchJobs()..fetchCourses()),
        ChangeNotifierProvider(create: (_) => FundingProvider()..fetch()),
        ChangeNotifierProvider(create: (_) => AreaContactProvider()..fetch()),
      ],
      child: const NEEApp(),
    ),
  );
}

class NEEApp extends StatefulWidget {
  const NEEApp({super.key});

  @override
  State<NEEApp> createState() => _NEEAppState();
}

class _NEEAppState extends State<NEEApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Microsoft Clarity — session recording & heatmaps (mobile only)
      initClarity(context);

      // Wire deep links into the router
      final router = AppRouter.instance;
      deepLinkService.setRouter(router);
      deepLinkService.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFE65100);

    return MaterialApp.router(
      title: 'NEE Construction',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.build(context.read<AuthProvider>()),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
      ),
    );
  }
}
