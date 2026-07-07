class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    this.body,
    this.type = 'general',
    this.isRead = false,
    this.createdAt,
    this.targetId,
  });

  final String id;
  final String title;
  final String? body;

  /// message | order | product | promo | general
  final String type;
  final bool isRead;
  final DateTime? createdAt;
  final String? targetId;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'].toString(),
        title: json['title'] as String? ?? '',
        body: json['body'] as String?,
        type: json['type'] as String? ?? 'general',
        isRead: json['is_read'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        targetId: json['target_id']?.toString(),
      );
}
