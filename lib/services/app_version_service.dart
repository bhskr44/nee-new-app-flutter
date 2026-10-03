import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/constants.dart';

class AppVersionInfo {
  final bool forceUpdate;
  final String? latestVersion;
  final String? minVersion;
  final String storeUrl;
  final String? releaseNotes;
  final String currentVersion;

  const AppVersionInfo({
    required this.forceUpdate,
    required this.currentVersion,
    this.latestVersion,
    this.minVersion,
    required this.storeUrl,
    this.releaseNotes,
  });
}

class AppVersionService {
  AppVersionService._();
  static final AppVersionService instance = AppVersionService._();

  static const _fallbackStoreUrl =
      'https://play.google.com/store/apps/details?id=${AppConstants.appPackage}';

  Future<AppVersionInfo?> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version; // e.g. "3.1.4"

      final dio = Dio(BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final response = await dio.get(
        '/app-version',
        queryParameters: {
          'platform': 'android',
          'current_version': currentVersion,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return AppVersionInfo(
          forceUpdate: data['force_update'] as bool? ?? false,
          currentVersion: currentVersion,
          latestVersion: data['latest_version'] as String?,
          minVersion: data['min_version'] as String?,
          storeUrl: (data['store_url'] as String?)?.isNotEmpty == true
              ? data['store_url'] as String
              : _fallbackStoreUrl,
          releaseNotes: data['release_notes'] as String?,
        );
      }
    } catch (_) {
      // Network failure — allow the app to open normally
    }
    return null;
  }
}
