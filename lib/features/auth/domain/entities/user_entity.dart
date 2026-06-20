import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String token;
  final String? refreshToken;
  final String? phone;
  final String? role;
  final bool isAdmin;
  final int? filialId;
  final String? filialName;
  final String? commissionPercent;

  const UserEntity({
    required this.id,
    required this.name,
    required this.token,
    this.refreshToken,
    this.phone,
    this.role,
    this.isAdmin = false,
    this.filialId,
    this.filialName,
    this.commissionPercent,
  });

  @override
  List<Object?> get props => [
        id, name, token, refreshToken, phone, role,
        isAdmin, filialId, filialName, commissionPercent,
      ];
}
