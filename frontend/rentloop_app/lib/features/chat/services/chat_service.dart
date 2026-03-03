import 'dart:convert';

import '../../../core/http/api_client.dart';
import '../models/chat_message_dto.dart';
import '../models/admin_conversation_dto.dart';

class ChatService {
  final ApiClient _api = ApiClient();

  Future<int> getMyConversationId() async {
    final res = await _api.get('/api/chat/my-conversation', auth: true);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(res.body);
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['conversationId'] as num).toInt();
  }

  Future<List<ChatMessageDto>> getMessages(int conversationId) async {
    final res = await _api.get('/api/chat/conversations/$conversationId/messages', auth: true);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(res.body);
    }

    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => ChatMessageDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(int conversationId) async {
    final res = await _api.postEmpty('/api/chat/conversations/$conversationId/read', auth: true);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(res.body);
    }
  }

  // fallback (ako SignalR faila)
  Future<ChatMessageDto> sendMessageRest(int conversationId, String text) async {
    final res = await _api.post(
      '/api/chat/conversations/$conversationId/messages',
      {'text': text},
      auth: true,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(res.body);
    }

    return ChatMessageDto.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<AdminConversationDto>> getAdminConversations() async {
  final res = await _api.get('/api/chat/admin/conversations', auth: true);

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception(res.body);
  }

  final list = jsonDecode(res.body) as List<dynamic>;
  return list
      .map((e) => AdminConversationDto.fromJson(e as Map<String, dynamic>))
      .toList();
}

}


