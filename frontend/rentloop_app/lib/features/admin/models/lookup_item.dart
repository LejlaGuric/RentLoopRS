class LookupItem {
  final int id;
  final String name;

  LookupItem({required this.id, required this.name});

  factory LookupItem.fromJson(Map<String, dynamic> json) {
    return LookupItem(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
    );
  }
}
