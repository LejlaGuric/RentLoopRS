import 'package:flutter/material.dart';

import '../../chat/models/chat_message_dto.dart';
import '../../chat/services/chat_realtime_service.dart';
import '../../chat/services/chat_service.dart';

class AdminConversationPage extends StatefulWidget {
  final int conversationId;
  final String userName;

  const AdminConversationPage({
    super.key,
    required this.conversationId,
    required this.userName,
  });

  @override
  State<AdminConversationPage> createState() => _AdminConversationPageState();
}

class _AdminConversationPageState extends State<AdminConversationPage> {
  final ChatService _svc = ChatService();
  final ChatRealtimeService _rt = ChatRealtimeService();

  final _msgCtrl = TextEditingController();
  final _scroll = ScrollController();

  bool _loading = true;
  String _error = '';
  List<ChatMessageDto> _messages = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _rt.disconnect(widget.conversationId);
    _msgCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final msgs = await _svc.getMessages(widget.conversationId);

      if (!mounted) return;
      setState(() => _messages = msgs);

      await _rt.connect(
        conversationId: widget.conversationId,
        onNewMessage: (raw) {
          final msg = ChatMessageDto.fromJson(raw);
          if (!mounted) return;

          setState(() {
            final exists = _messages.any((x) => x.id == msg.id);
            if (!exists) _messages.add(msg);
          });

          _scrollToBottom();
          _svc.markRead(widget.conversationId);
        },
      );

      await _svc.markRead(widget.conversationId);

      _scrollToBottom();

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '').replaceAll('"', '').trim();
        _loading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    _msgCtrl.clear();

    try {
      await _rt.sendMessage(widget.conversationId, text);
    } catch (e) {
      // fallback REST
      try {
        final sent = await _svc.sendMessageRest(widget.conversationId, text);
        if (!mounted) return;
        setState(() => _messages.add(sent));
        _scrollToBottom();
      } catch (e2) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ne mogu poslati poruku: $e2')),
        );
      }
    }
  }

  String _fmtTime(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2F5BFF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(widget.userName.isEmpty ? 'Razgovor' : widget.userName),
        actions: [
          IconButton(
            tooltip: 'Osvježi',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Builder(
              builder: (_) {
                if (_loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_error.isNotEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _error,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
                      ),
                    ),
                  );
                }
                if (_messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Nema poruka još.',
                      style: TextStyle(color: Colors.black.withOpacity(0.6), fontWeight: FontWeight.w700),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final m = _messages[i];
                    final isMine = m.isMine;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Align(
                        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 320),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMine ? blue.withOpacity(0.10) : Colors.black.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isMine ? blue.withOpacity(0.20) : Colors.black.withOpacity(0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(m.text, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text(
                                _fmtTime(m.sentAt),
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.55),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Napiši poruku...',
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: blue.withOpacity(0.6)),
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded),
                    color: blue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
