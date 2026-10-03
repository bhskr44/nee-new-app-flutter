import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Background message handling — no UI access here
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'nee_high_importance',
    'NEE Notifications',
    description: 'NEE Platform app notifications',
    importance: Importance.max,
    playSound: true,
  );

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Must run before _requestPermissions() — the Android permission request
    // goes through the local-notifications plugin, which needs to already be
    // initialized before its platform-specific implementation is resolvable.
    await _setupLocalNotifications();
    await _requestPermissions();
    await _setupForegroundListener();
    await _registerToken();

    // Broadcasts (new lead/product/business/community post) go out over this
    // topic — without subscribing, sendBroadcast() on the backend reaches no
    // one, since a topic send only delivers to devices that opted in.
    try {
      await subscribeToTopic('all');
    } catch (_) {}
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } else if (Platform.isAndroid) {
      // FirebaseMessaging.requestPermission() only *reads* status on Android —
      // it never shows the OS's POST_NOTIFICATIONS prompt (required on API 33+).
      // This is the actual call that triggers it.
      final androidPlugin =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  Future<void> _setupLocalNotifications() async {
    // A flat white silhouette, not the full-color app icon — Android tints
    // status-bar icons using their alpha channel, so a solid-background
    // launcher icon renders as an unrecognizable white blob there.
    const android = AndroidInitializationSettings('@mipmap/ic_stat_notify');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidPlugin?.createNotificationChannel(_androidChannel);
  }

  void _onNotificationTap(NotificationResponse response) {
    // Navigation handled via GoRouter — deep link will be triggered
  }

  Future<void> _setupForegroundListener() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_stat_notify',
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/ic_launcher',
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['route'],
      );
    });

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> _registerToken() async {
    final token = await getToken();
    if (token != null) {
      try {
        final platform = Platform.isIOS ? 'ios' : 'android';
        await apiService.registerFcmToken(token, platform);
      } catch (_) {
        // Not authenticated yet — will register after login
      }
    }

    _messaging.onTokenRefresh.listen((newToken) async {
      try {
        final platform = Platform.isIOS ? 'ios' : 'android';
        await apiService.registerFcmToken(newToken, platform);
      } catch (_) {}
    });
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}

final notificationService = NotificationService();
