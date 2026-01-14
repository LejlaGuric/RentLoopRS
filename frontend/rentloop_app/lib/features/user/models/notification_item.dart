class NotificationItem {
  final int id;
  final int typeId;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  final int? relatedPropertyId;
  final int? relatedReservationId;

  NotificationItem({
    required this.id,
    required this.typeId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    this.relatedPropertyId,
    this.relatedReservationId,
  });

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is String) {
      final dt = DateTime.tryParse(v);
      return dt ?? DateTime.now();
    }
    return DateTime.now();
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] ?? 0) as int,
      typeId: (json['typeId'] ?? 0) as int,
      title: (json['title'] ?? '') as String,
      body: (json['body'] ?? '') as String,
      createdAt: _parseDate(json['createdAt']).toLocal(),
      isRead: (json['isRead'] ?? false) as bool,
      relatedPropertyId: json['relatedPropertyId'] as int?,
      relatedReservationId: json['relatedReservationId'] as int?,
    );
  }
}
