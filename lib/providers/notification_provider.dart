import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
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

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  Future<void> load({bool refresh = false}) async {
    if (!refresh) {
      status = ViewStatus.loading;
      notifyListeners();
    }
    try {
      notifications = await _repo.fetchAll();
      status = notifications.isEmpty ? ViewStatus.empty : ViewStatus.success;
      error = null;
    } on ApiException catch (e) {
      status = ViewStatus.error;
      error = e.message;
    }
    notifyListeners();
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
