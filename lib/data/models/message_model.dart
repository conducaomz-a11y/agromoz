class MessageModel {
  const MessageModel({
    required this.id,
    required this.senderId,
    required this.isMine,
    this.text,
    this.imageUrl,
    this.sentAt,
    this.isRead = false,
    this.isSending = false,
  });

  final String id;
  final String senderId;
  final bool isMine;
  final String? text;
  final String? imageUrl;
  final DateTime? sentAt;
  final bool isRead;

  /// Local optimistic-send flag — never comes from the API.
  final bool isSending;

  bool get isImage => imageUrl != null && imageUrl!.isNotEmpty;

  factory MessageModel.fromJson(
    Map<String, dynamic> json, {
    required String currentUserId,
  }) {
    final sender = json['sender_id'].toString();
    return MessageModel(
      id: json['id'].toString(),
      senderId: sender,
      isMine: sender == currentUserId,
      text: json['text'] as String?,
      imageUrl: json['image_url'] as String?,
      sentAt: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'].toString())
          : null,
      isRead: json['is_read'] as bool? ?? false,
    );
  }
}
