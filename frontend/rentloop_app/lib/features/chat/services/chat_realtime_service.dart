import 'package:signalr_netcore/signalr_client.dart';

import '../../../core/config/api_config.dart';
import '../../../core/storage/token_storage.dart';

class ChatRealtimeService {
  HubConnection? _hub;
  final TokenStorage _storage = TokenStorage();

  bool get isConnected => _hub?.state == HubConnectionState.Connected;

  Future<void> connect({
    required int conversationId,
    required void Function(Map<String, dynamic> msg) onNewMessage,
  }) async {
    final hubUrl = '${ApiConfig.baseUrl}/hubs/chat';

    _hub = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => (await _storage.getToken()) ?? '',
          ),
        )
        .withAutomaticReconnect()
        .build();

    _hub!.on('NewMessage', (args) {
      if (args == null || args.isEmpty) return;
      final raw = args[0];

      if (raw is Map) {
        onNewMessage(Map<String, dynamic>.from(raw));
      }
    });

    await _hub!.start();
    await _hub!.invoke('JoinConversation', args: [conversationId]);
  }

  Future<void> sendMessage(int conversationId, String text) async {
    if (_hub == null) throw Exception('SignalR nije spojen.');
    await _hub!.invoke('SendMessage', args: [conversationId, text]);
  }

  Future<void> markRead(int conversationId) async {
    if (_hub == null) return;
    await _hub!.invoke('MarkRead', args: [conversationId]);
  }

  Future<void> disconnect(int conversationId) async {
    try {
      await _hub?.invoke('LeaveConversation', args: [conversationId]);
    } catch (_) {}
    await _hub?.stop();
    _hub = null;
  }
}
