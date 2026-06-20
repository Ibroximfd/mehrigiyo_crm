import 'package:equatable/equatable.dart';

class OperatorEntity extends Equatable {
  final int id;
  final String fullName;
  final String username;
  final String commissionPercent;
  final bool isAdmin;
  final int? filialId;
  final String? filialName;
  final bool isActive;
  final String createdAt;

  const OperatorEntity({
    required this.id,
    required this.fullName,
    required this.username,
    required this.commissionPercent,
    required this.isAdmin,
    this.filialId,
    this.filialName,
    required this.isActive,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id, fullName, username, commissionPercent, isAdmin,
        filialId, filialName, isActive, createdAt,
      ];
}
