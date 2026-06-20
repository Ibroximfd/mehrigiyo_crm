import '../../domain/entities/operator_entity.dart';

class OperatorModel extends OperatorEntity {
  const OperatorModel({
    required super.id,
    required super.fullName,
    required super.username,
    required super.commissionPercent,
    required super.isAdmin,
    super.filialId,
    super.filialName,
    required super.isActive,
    required super.createdAt,
  });

  factory OperatorModel.fromJson(Map<String, dynamic> json) {
    return OperatorModel(
      id: json['id'] as int,
      fullName: json['full_name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      commissionPercent: json['commission_percent']?.toString() ?? '10.00',
      isAdmin: json['is_admin'] == true,
      filialId: json['filial'] is int ? json['filial'] as int : null,
      filialName: json['filial_name']?.toString(),
      isActive: json['is_active'] == true,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
