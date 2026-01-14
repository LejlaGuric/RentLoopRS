class AdminConversationDto {
  final int id;
  final int userId;
  final String userName;
  final int? adminId;
  final DateTime lastMessageAt;
  final String? lastMessageText;

  AdminConversationDto({
    required this.id,
    required this.userId,
    required this.userName,
    required this.adminId,
    required this.lastMessageAt,
    required this.lastMessageText,
  });

  factory AdminConversationDto.fromJson(Map<String, dynamic> json) {
    return AdminConversationDto(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      userName: (json['userName'] ?? '').toString(),
      adminId: json['adminId'] == null ? null : (json['adminId'] as num).toInt(),
      lastMessageAt: DateTime.parse(json['lastMessageAt'].toString()),
      lastMessageText: json['lastMessageText']?.toString(),
    );
  }
}
