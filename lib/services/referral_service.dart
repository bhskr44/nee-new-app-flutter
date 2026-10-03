import 'package:flutter/foundation.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:share_plus/share_plus.dart';
import 'storage_service.dart';

class ReferralService {
  static const _storageKey = 'install_referral_code';
  static const _usedKey = 'install_referral_used';

  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=in.complit.neep';

  /// Call once at app startup (before runApp or in main()).
  /// Reads the Play Install Referrer and caches the code so registration
  /// screens can pre-fill it without waiting.
  static Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    // Don't overwrite a code we already stored
    final existing = await StorageService.getString(_storageKey);
    if (existing != null && existing.isNotEmpty) return;

    try {
      final details = await PlayInstallReferrer.installReferrer;
      final raw = details.installReferrer?.trim() ?? '';

      if (raw.isNotEmpty) {
        // The referrer is a URL-encoded query string (e.g. "ref=NEE123&utm_source=whatsapp").
        // Only treat it as a referral code if it contains an explicit `ref` parameter.
        final params = Uri.splitQueryString(raw);
        final refCode = params['ref']?.trim() ?? '';
        if (refCode.isNotEmpty) {
          await StorageService.saveString(_storageKey, refCode);
        }
        // Everything else (utm_source, organic, (not set), etc.) is ignored.
      }
    } catch (_) {
      // Google Play Services unavailable or not on Android — safe to ignore
    }
  }

  /// Returns the referral code from the install link, or null if none.
  static Future<String?> getPendingCode() async {
    final used = await StorageService.getString(_usedKey);
    if (used == '1') return null; // already applied
    return StorageService.getString(_storageKey);
  }

  /// Call after the referral code is successfully submitted so it isn't
  /// auto-filled again on future registrations.
  static Future<void> markUsed() async {
    await StorageService.saveString(_usedKey, '1');
  }

  /// Opens the native share sheet with an invite message carrying the user's
  /// own referral code (the "NEE{userId}" scheme the backend understands —
  /// see AuthController::resolveReferrer). Shared by the Settings screen and
  /// the home drawer so both "Invite a Friend" entry points stay in sync.
  static Future<void> share(int? userId) async {
    final referralCode = userId != null ? 'NEE$userId' : '';
    // Play Store passes the `referrer` param value directly to the
    // Install Referrer API — use it (not `referral`) so the app can read it.
    final shareUrl = referralCode.isNotEmpty
        ? '$_playStoreUrl&referrer=$referralCode'
        : _playStoreUrl;

    final message = referralCode.isNotEmpty
        ? 'Join me on NEE Platform — India\'s #1 Construction Platform!\n\n'
            'Find products, workers, leads, loans and more.\n\n'
            'Download here: $shareUrl\n\n'
            'Use my referral code: $referralCode'
        : 'Join me on NEE Platform — India\'s #1 Construction Platform!\n\n'
            'Download here: $shareUrl';

    await Share.share(message, subject: 'NEE Platform App');
  }
}
