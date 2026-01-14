import 'package:flutter/material.dart';

import '../models/notification_item.dart';
import '../services/notifications_service.dart';
// ako želiš kasnije navigaciju na oglas:
// import 'listing_details_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _svc = NotificationsService();

  bool _loading = true;
  String _error = '';
  List<NotificationItem> _items = [];

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
      final items = await _svc.myNotifications();

      // sort: newest first
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;
      setState(() => _items = items);
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

  IconData _iconFor(NotificationItem n) {
    // možeš proširiti po typeId
    if (n.typeId == 1) return Icons.check_circle_rounded; // approved
    if (n.typeId == 2) return Icons.close_rounded; // rejected
    return Icons.notifications_rounded;
  }

  Future<void> _open(NotificationItem n) async {
    // opcionalno označi kao pročitano
    if (!n.isRead) {
      await _svc.markAsRead(n.id);
      // lokalno osvježi state da odmah izgleda pročitano
      if (!mounted) return;
      setState(() {
        _items = _items
            .map((x) => x.id == n.id
                ? NotificationItem(
                    id: x.id,
                    typeId: x.typeId,
                    title: x.title,
                    body: x.body,
                    createdAt: x.createdAt,
                    isRead: true,
                    relatedPropertyId: x.relatedPropertyId,
                    relatedReservationId: x.relatedReservationId,
                  )
                : x)
            .toList();
      });
    }

    // kasnije možeš navigaciju:
    // if (n.relatedPropertyId != null) {
    //   Navigator.of(context).push(
    //     MaterialPageRoute(builder: (_) => ListingDetailsPage(listingId: n.relatedPropertyId!)),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2F5BFF);

    final unreadCount = _items.where((x) => !x.isRead).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text('Obavijesti'),
            if (!_loading && unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: blue.withOpacity(0.25)),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ],
        ),
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
                'Trenutno nemaš obavijesti.',
                style: TextStyle(color: Colors.black.withOpacity(0.6), fontWeight: FontWeight.w700),
              ),
            ] else ...[
              ..._items.map((n) {
                final isUnread = !n.isRead;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _open(n),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUnread ? blue.withOpacity(0.06) : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isUnread ? blue.withOpacity(0.22) : Colors.black.withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isUnread ? blue.withOpacity(0.12) : Colors.black.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _iconFor(n),
                              color: isUnread ? blue : Colors.black.withOpacity(0.55),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n.title,
                                        style: TextStyle(
                                          fontWeight: isUnread ? FontWeight.w900 : FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _fmt(n.createdAt),
                                      style: TextStyle(
                                        color: Colors.black.withOpacity(0.55),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  n.body,
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.75),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (isUnread) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: blue,
                                          borderRadius: BorderRadius.circular(99),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Novo',
                                        style: TextStyle(
                                          color: blue,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
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
