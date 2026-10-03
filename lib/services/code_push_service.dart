import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Over-the-air updates via Shorebird code push — ships Dart-side changes
/// (screens, logic, fixes) straight to installed apps without a Play Store
/// release. Native changes (new plugins, permissions, Android config) still
/// need a normal store release via fastlane.
///
/// Only does anything in builds made with `shorebird release` (the fastlane
/// lanes do this); in debug or plain `flutter build` it's a silent no-op.
class CodePushService {
  CodePushService._();
  static final CodePushService instance = CodePushService._();

  final _updater = ShorebirdUpdater();
  bool _busy = false;
  bool _prompted = false;
  DateTime? _lastCheck;

  /// Checks for a patch, downloads it in the background, then offers a
  /// restart through [messengerKey]. Throttled so frequent app resumes
  /// don't hammer the update server.
  Future<void> checkAndPrompt(GlobalKey<ScaffoldMessengerState> messengerKey) async {
    if (!_updater.isAvailable || _busy || _prompted) return;
    if (_lastCheck != null && DateTime.now().difference(_lastCheck!) < const Duration(minutes: 15)) return;

    _busy = true;
    _lastCheck = DateTime.now();
    try {
      var status = await _updater.checkForUpdate();
      if (status == UpdateStatus.outdated) {
        await _updater.update();
        status = UpdateStatus.restartRequired;
      }
      if (status == UpdateStatus.restartRequired) {
        _prompted = true;
        _showRestartPrompt(messengerKey);
      }
    } on UpdateException catch (_) {
      // Download/install failed — the app keeps running the current code and
      // the next check retries.
    } catch (_) {
      // Network or updater error — never block the app over an update.
    } finally {
      _busy = false;
    }
  }

  void _showRestartPrompt(GlobalKey<ScaffoldMessengerState> messengerKey) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: const Text('A new update is ready. Restart the app to apply it.'),
        duration: const Duration(days: 1),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'RESTART',
          // A fresh process is needed for the Shorebird engine to load the patch.
          onPressed: () => Restart.restartApp(mode: RestartMode.process),
        ),
      ),
    );
  }
}
