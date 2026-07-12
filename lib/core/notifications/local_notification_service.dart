import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles device-level notifications shown in the system tray.
///
/// Used two ways:
///  * FCM push messages received while the app is in the foreground are
///    re-displayed through here (Android doesn't auto-show foreground pushes).
///  * The in-app notification poller raises a local alert when it detects new
///    unread items, even without a push server round-trip.
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance =
      LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  /// Called once at startup. [onTap] receives the payload (e.g. a route or id).
  Future<void> init({void Function(String? payload)? onTap}) async {
    if (_initialised) return;

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) =>
          onTap?.call(response.payload),
    );

    // Android 13+ needs an explicit runtime permission request.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialised = true;
  }

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'agromoz_general',
    'Notificações AgroMoz',
    channelDescription: 'Mensagens, novidades e alertas do AgroMoz',
    importance: Importance.high,
    priority: Priority.high,
  );

  /// Show a one-off notification. [id] lets you overwrite/update an existing one.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialised) return;
    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(android: _androidDetails, iOS: DarwinNotificationDetails()),
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('LocalNotification error: $e');
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
