import 'package:equatable/equatable.dart';

class StatusEntity extends Equatable {
  final int id;
  final String name;
  final String category; // 'sales' | 'post_sale'
  final String color;
  final int order;
  final bool isDefault;
  final bool isActive;
  final String createdAt;

  const StatusEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.order,
    required this.isDefault,
    required this.isActive,
    required this.createdAt,
  });

  bool get isSales => category == 'sales';

  @override
  List<Object?> get props => [id, name, category, color, order, isDefault, isActive];
}
