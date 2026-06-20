import '../../domain/entities/status_entity.dart';

class StatusModel extends StatusEntity {
  const StatusModel({
    required super.id,
    required super.name,
    required super.category,
    required super.color,
    required super.order,
    required super.isDefault,
    required super.isActive,
    required super.createdAt,
  });

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    return StatusModel(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'sales',
      color: json['color']?.toString() ?? '#6b7280',
      order: json['order'] as int? ?? 0,
      isDefault: json['is_default'] == true,
      isActive: json['is_active'] != false,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
