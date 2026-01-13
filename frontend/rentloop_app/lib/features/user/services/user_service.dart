import 'dart:convert';
import '../../../core/http/api_client.dart';

class UserProfileDto {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? address;
  final int role;
  final bool isActive;

  UserProfileDto({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.address,
    required this.role,
    required this.isActive,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> j) => UserProfileDto(
        id: (j['id'] ?? 0) as int,
        username: (j['username'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        firstName: j['firstName'] as String?,
        lastName: j['lastName'] as String?,
        phone: j['phone'] as String?,
        address: j['address'] as String?,
        role: (j['role'] ?? 0) as int,
        isActive: (j['isActive'] ?? true) as bool,
      );
}

class UpdateMeRequest {
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? address;

  UpdateMeRequest({this.firstName, this.lastName, this.phone, this.address});

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'address': address,
      };
}

class UserService {
  final ApiClient _api = ApiClient();

  Future<UserProfileDto> me() async {
    final res = await _api.get('/api/users/me', auth: true);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Ne mogu učitati profil (${res.statusCode}): ${res.body}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return UserProfileDto.fromJson(j);
  }

  Future<UserProfileDto> updateMe(UpdateMeRequest req) async {
            final res = await _api.put(
          '/api/users/me',
          req.toJson(),
          auth: true,
        );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Ne mogu sačuvati profil (${res.statusCode}): ${res.body}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return UserProfileDto.fromJson(j);
  }
}
