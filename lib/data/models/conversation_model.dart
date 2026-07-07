import 'user_model.dart';

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  final String id;
  final UserModel otherUser;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      ConversationModel(
        id: json['id'].toString(),
        otherUser:
            UserModel.fromJson(json['other_user'] as Map<String, dynamic>? ?? {'id': '0', 'name': '—'}),
        lastMessage: json['last_message'] as String?,
        lastMessageAt: json['last_message_at'] != null
            ? DateTime.tryParse(json['last_message_at'].toString())
            : null,
        unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      );
}
