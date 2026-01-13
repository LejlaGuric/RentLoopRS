class LookupItem {
  final int id;
  final String name;

  const LookupItem({required this.id, required this.name});

  factory LookupItem.fromJson(Map<String, dynamic> json) {
    return LookupItem(
      id: (json['id'] ?? json['Id']) as int,
      name: (json['name'] ?? json['Name'] ?? '').toString(),
    );
  }
}
