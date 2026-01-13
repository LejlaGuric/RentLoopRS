class AdminUser {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final int role; // 1 admin, 2 client
  final bool isActive;
  final String? phone;
  final String? address;

  const AdminUser({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isActive,
    required this.phone,
    required this.address,
  });

  String get fullName {
    final fn = (firstName ?? '').trim();
    final ln = (lastName ?? '').trim();
    final name = ('$fn $ln').trim();
    return name.isEmpty ? '-' : name;
  }

  String get roleText => role == 1 ? 'Admin' : 'Klijent';

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: (json['id'] as num).toInt(),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      role: (json['role'] as num).toInt(),
      isActive: (json['isActive'] as bool?) ?? false,
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
    );
  }
}
