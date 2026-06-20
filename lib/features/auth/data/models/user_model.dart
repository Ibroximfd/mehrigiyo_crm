import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.token,
    super.refreshToken,
    super.phone,
    super.role,
    super.isAdmin,
    super.filialId,
    super.filialName,
    super.commissionPercent,
  });

  /// Parses the new operator sales system login response
  factory UserModel.fromOperatorLoginJson(Map<String, dynamic> json) {
    final op = json['operator'] as Map<String, dynamic>? ?? {};
    final filial = json['filial'] as Map<String, dynamic>?;
    return UserModel(
      id: op['id']?.toString() ?? '',
      name: op['full_name']?.toString() ?? '',
      token: json['access']?.toString() ?? '',
      refreshToken: json['refresh']?.toString(),
      phone: op['username']?.toString(),
      isAdmin: json['is_admin'] == true || op['is_admin'] == true,
      filialId: (filial?['id'] ?? op['filial']) is int
          ? (filial?['id'] ?? op['filial']) as int
          : int.tryParse('${filial?['id'] ?? op['filial'] ?? ''}'),
      filialName: filial?['name']?.toString() ?? op['filial_name']?.toString(),
      commissionPercent: op['commission_percent']?.toString(),
    );
  }

  /// Parses the legacy support login response
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

  factory UserModel.fromPrefs(Map<String, String?> prefs) {
    return UserModel(
      id: prefs['operator_id'] ?? '',
      name: prefs['operator_name'] ?? '',
      token: prefs['auth_token'] ?? '',
      refreshToken: prefs['operator_refresh'],
      phone: prefs['operator_phone'],
      isAdmin: prefs['operator_is_admin'] == 'true',
      filialId: int.tryParse(prefs['operator_filial_id'] ?? ''),
      filialName: prefs['operator_filial_name'],
      commissionPercent: prefs['operator_commission'],
    );
  }
}
