import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.token,
    super.phone,
    super.role,
  });

  factory UserModel.fromLoginJson(Map<String, dynamic> json) {
    final operator = json['operator'] as Map<String, dynamic>? ?? {};
    return UserModel(
      id: operator['id']?.toString() ?? '',
      name: operator['full_name'] ?? operator['name'] ?? '',
      token: json['access'] ?? '',
      phone: operator['phone']?.toString(),
    );
  }

  factory UserModel.fromProfileJson(Map<String, dynamic> json) {
    final operator = json['operator'] as Map<String, dynamic>? ?? json;
    return UserModel(
      id: operator['id']?.toString() ?? '',
      name: operator['full_name'] ?? operator['name'] ?? '',
      token: '',
      phone: operator['phone']?.toString(),
      role: operator['role'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'token': token,
    'phone': phone,
    'role': role,
  };
}
