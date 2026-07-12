import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/notification_repository.dart';
import 'local_notification_service.dart';

/// Background/terminated push handler. MUST be a top-level function annotated
/// with @pragma so it survives tree-shaking and can run in its own isolate.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // Keep this minimal: the OS displays the notification payload itself when
  // the app isn't in the foreground. Heavy work here is discouraged.
  if (kDebugMode) {
    debugPrint('BG push: ${message.messageId}');
  }
}

/// Wires Firebase Cloud Messaging into the app:
///  * asks for permission
///  * registers the device token with the AgroMoz backend (/devices)
///  * shows foreground pushes via [LocalNotificationService]
///
/// Safe to call even if Firebase isn't fully configured yet — it catches and
/// logs so the app still runs locally without google-services.json.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final NotificationRepository _repo = NotificationRepository();
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    try {
      await _fcm.requestPermission(alert: true, badge: true, sound: true);

      // Foreground pushes -> re-display locally (Android won't show them).
      FirebaseMessaging.onMessage.listen((message) {
        final n = message.notification;
        if (n != null) {
          LocalNotificationService.instance.show(
            id: message.hashCode,
            title: n.title ?? 'AgroMoz',
            body: n.body ?? '',
            payload: message.data['route'] as String?,
          );
        }
      });

      await _syncToken();
      _fcm.onTokenRefresh.listen(_sendToken);
      _started = true;
    } catch (e) {
      if (kDebugMode) debugPrint('Push init skipped: $e');
    }
  }

  /// Call after a successful login so the token is tied to the account.
  Future<void> syncAfterLogin() => _syncToken();

  Future<void> _syncToken() async {
    final token = await _fcm.getToken();
    if (token != null) await _sendToken(token);
  }

  Future<void> _sendToken(String token) async {
    try {
      await _repo.registerDeviceToken(token);
    } catch (e) {
      if (kDebugMode) debugPrint('Token register failed: $e');
    }
  }
}
