import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/notifications/local_notification_service.dart';
import '../data/models/notification_model.dart';
import '../data/repositories/notification_repository.dart';
import 'base_view_state.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({NotificationRepository? repository})
      : _repo = repository ?? NotificationRepository();

  final NotificationRepository _repo;

  ViewStatus status = ViewStatus.initial;
  String? error;
  List<NotificationModel> notifications = [];

  /// IDs already seen — used to avoid re-alerting for the same notification.
  final Set<String> _knownIds = {};
  bool _primed = false;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  /// Limpa os dados ao trocar de conta.
  void reset() {
    notifications = [];
    _knownIds.clear();
    _primed = false;
    status = ViewStatus.initial;
    error = null;
    notifyListeners();
  }

  Future<void> load({bool refresh = false}) async {
    if (!refresh) {
      status = ViewStatus.loading;
      notifyListeners();
    }
    try {
      final fresh = await _repo.fetchAll();
      _raiseLocalAlertsFor(fresh);
      notifications = fresh;
      status = notifications.isEmpty ? ViewStatus.empty : ViewStatus.success;
      error = null;
    } on ApiException catch (e) {
      status = ViewStatus.error;
      error = e.message;
    }
    notifyListeners();
  }

  /// Fires a device notification for any unread item we haven't seen before.
  /// The first load only *primes* the known set (so we don't spam the tray
  /// with the whole backlog when the screen opens).
  void _raiseLocalAlertsFor(List<NotificationModel> fresh) {
    if (!_primed) {
      _knownIds
        ..clear()
        ..addAll(fresh.map((n) => n.id));
      _primed = true;
      return;
    }
    for (final n in fresh) {
      if (!_knownIds.contains(n.id) && !n.isRead) {
        LocalNotificationService.instance.show(
          id: n.id.hashCode,
          title: n.title,
          body: n.body ?? '',
          payload: n.id,
        );
      }
      _knownIds.add(n.id);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _repo.markAllAsRead();
      await load(refresh: true);
    } on ApiException {
      // silently ignore — pull-to-refresh will resync
    }
  }
}
