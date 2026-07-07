import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class MessageRepository {
  MessageRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;
  final ApiClient _client;

  Future<List<ConversationModel>> fetchConversations() async {
    final data =
        await _client.get<Map<String, dynamic>>(ApiEndpoints.conversations);
    return (data['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ConversationModel.fromJson)
        .toList();
  }

  Future<List<MessageModel>> fetchMessages(
    String conversationId, {
    required String currentUserId,
  }) async {
    final data = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.conversationMessages(conversationId),
    );
    return (data['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => MessageModel.fromJson(e, currentUserId: currentUserId))
        .toList();
  }

  Future<MessageModel> sendText(
    String conversationId, {
    required String text,
    required String currentUserId,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.sendMessage(conversationId),
      data: {'text': text},
    );
    return MessageModel.fromJson(
      (data['data'] ?? data) as Map<String, dynamic>,
      currentUserId: currentUserId,
    );
  }

  Future<MessageModel> sendImage(
    String conversationId, {
    required String filePath,
    required String currentUserId,
  }) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath),
    });
    final data = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.sendMessage(conversationId),
      data: form,
    );
    return MessageModel.fromJson(
      (data['data'] ?? data) as Map<String, dynamic>,
      currentUserId: currentUserId,
    );
  }
}
