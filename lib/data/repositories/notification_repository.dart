import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  NotificationRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;
  final ApiClient _client;

  Future<List<NotificationModel>> fetchAll() async {
    final data =
        await _client.get<Map<String, dynamic>>(ApiEndpoints.notifications);
    return (data['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();
  }

  Future<void> markAsRead(String id) =>
      _client.patch<void>('${ApiEndpoints.notifications}/$id/read');

  Future<void> markAllAsRead() =>
      _client.post<void>('${ApiEndpoints.notifications}/read-all');

  /// Register an FCM device token — ready for Firebase Cloud Messaging.
  Future<void> registerDeviceToken(String token) => _client.post<void>(
        ApiEndpoints.deviceToken,
        data: {'token': token, 'platform': 'mobile'},
      );
}
