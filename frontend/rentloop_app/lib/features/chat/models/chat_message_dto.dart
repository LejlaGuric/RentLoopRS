class ChatMessageDto {
  final int id;
  final int conversationId;
  final int senderUserId;
  final String senderName;
  final String text;
  final DateTime sentAt;
  final bool isRead;
  final bool isMine;

  ChatMessageDto({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.senderName,
    required this.text,
    required this.sentAt,
    required this.isRead,
    required this.isMine,
  });

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) {
    return ChatMessageDto(
      id: (json['id'] as num).toInt(),
      conversationId: (json['conversationId'] as num).toInt(),
      senderUserId: (json['senderUserId'] as num).toInt(),
      senderName: (json['senderName'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      sentAt: DateTime.parse(json['sentAt'].toString()),
      isRead: json['isRead'] == true,
      isMine: json['isMine'] == true,
    );
  }
}
