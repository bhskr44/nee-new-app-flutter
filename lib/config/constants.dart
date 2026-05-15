import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'NEE Construction';
  static const String appPackage = 'com.nee.construction';
  static const String appScheme = 'neeconstruction';

  // Auto-selects the right host for each platform:
  //   Web / iOS Simulator / Desktop → localhost
  //   Android Emulator              → 10.0.2.2 (maps to host loopback)
  static String get apiBaseUrl {
    if (kIsWeb) return 'http://localhost:8080/api/v1';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    return 'http://localhost:8080/api/v1';
  }

  static const Duration apiTimeout = Duration(seconds: 30);

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  static const List<String> productCategories = [
    'All', 'Cement', 'Steel', 'Bricks', 'Sand', 'Aggregates',
    'Tiles', 'Paint', 'Pipes', 'Electrical', 'Plumbing',
    'Hardware', 'Glass', 'Wood', 'Insulation', 'Roofing',
  ];

  static const List<String> workerTrades = [
    'All', 'Mason', 'Plumber', 'Electrician', 'Carpenter', 'Painter',
    'Welder', 'Tiler', 'Roofer', 'Plasterer', 'Steel Fixer',
    'Concrete Mixer', 'Equipment Operator', 'Excavator',
  ];

  static const List<String> projectTypes = [
    'Residential', 'Commercial', 'Industrial', 'Infrastructure',
    'Renovation', 'Interior', 'Landscaping',
  ];
}
