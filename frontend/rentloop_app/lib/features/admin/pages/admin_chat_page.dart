import 'package:flutter/material.dart';

import '../../chat/models/admin_conversation_dto.dart';
import '../../chat/services/chat_service.dart';
import '../../chat/pages/admin_conversation_page.dart';

class AdminChatPage extends StatefulWidget {
  const AdminChatPage({super.key});

  @override
  State<AdminChatPage> createState() => _AdminChatPageState();
}

class _AdminChatPageState extends State<AdminChatPage> {
  final ChatService _svc = ChatService();

  bool _loading = true;
  String _error = '';
  List<AdminConversationDto> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final list = await _svc.getAdminConversations();
      list.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

      if (!mounted) return;
      setState(() => _items = list);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '').replaceAll('"', '').trim();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}  $hh:$mi';
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
        title: const Text('Admin Inbox'),
        actions: [
          IconButton(
            tooltip: 'Osvježi',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (_loading) ...[
              const SizedBox(height: 60),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 60),
            ] else if (_error.isNotEmpty) ...[
              Text(_error, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
            ] else if (_items.isEmpty) ...[
              const SizedBox(height: 40),
              Text(
                'Nema razgovora još.',
                style: TextStyle(color: Colors.black.withOpacity(0.6), fontWeight: FontWeight.w700),
              ),
            ] else ...[
              ..._items.map((c) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminConversationPage(
                            conversationId: c.id,
                            userName: c.userName,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: blue.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.person_rounded, color: blue),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.userName.isEmpty ? 'User #${c.userId}' : c.userName,
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  c.lastMessageText ?? '(nema poruka još)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _fmt(c.lastMessageAt),
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.55),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
