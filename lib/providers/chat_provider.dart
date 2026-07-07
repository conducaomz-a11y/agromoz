import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/conversation_model.dart';
import '../data/models/message_model.dart';
import '../data/repositories/message_repository.dart';
import 'base_view_state.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({MessageRepository? repository})
      : _repo = repository ?? MessageRepository();

  final MessageRepository _repo;

  // Conversations list
  ViewStatus conversationsStatus = ViewStatus.initial;
  String? error;
  List<ConversationModel> conversations = [];

  // Active thread
  ViewStatus messagesStatus = ViewStatus.initial;
  List<MessageModel> messages = [];
  bool isSending = false;

  Future<void> loadConversations({bool refresh = false}) async {
    if (!refresh) {
      conversationsStatus = ViewStatus.loading;
      notifyListeners();
    }
    try {
      conversations = await _repo.fetchConversations();
      conversationsStatus =
          conversations.isEmpty ? ViewStatus.empty : ViewStatus.success;
      error = null;
    } on ApiException catch (e) {
      conversationsStatus = ViewStatus.error;
      error = e.message;
    }
    notifyListeners();
  }

  Future<void> loadMessages(String conversationId, String userId) async {
    messagesStatus = ViewStatus.loading;
    messages = [];
    notifyListeners();
    try {
      messages =
          await _repo.fetchMessages(conversationId, currentUserId: userId);
      messagesStatus = ViewStatus.success;
    } on ApiException catch (e) {
      messagesStatus = ViewStatus.error;
      error = e.message;
    }
    notifyListeners();
  }

  Future<void> sendText(
    String conversationId,
    String userId,
    String text,
  ) async {
    if (text.trim().isEmpty) return;
    // Optimistic bubble.
    final temp = MessageModel(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      senderId: userId,
      isMine: true,
      text: text.trim(),
      sentAt: DateTime.now(),
      isSending: true,
    );
    messages.add(temp);
    isSending = true;
    notifyListeners();
    try {
      final sent = await _repo.sendText(
        conversationId,
        text: text.trim(),
        currentUserId: userId,
      );
      final i = messages.indexOf(temp);
      if (i != -1) messages[i] = sent;
    } on ApiException {
      messages.remove(temp);
    } finally {
      isSending = false;
      notifyListeners();
    }
  }
}
