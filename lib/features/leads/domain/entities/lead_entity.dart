import 'package:equatable/equatable.dart';

class AssignedTo extends Equatable {
  final int id;
  final String fullName;
  const AssignedTo({required this.id, required this.fullName});
  @override
  List<Object?> get props => [id, fullName];
}

class LeadEntity extends Equatable {
  final int id;
  final String fullName;
  final String phone;
  final int? statusId;
  final String? statusName;
  final String source;
  final AssignedTo? assignedTo;
  final String? region;
  final String? note;
  final String? clientUser;
  final String? createdByName;
  final String createdAt;
  final String updatedAt;

  const LeadEntity({
    required this.id,
    required this.fullName,
    required this.phone,
    this.statusId,
    this.statusName,
    required this.source,
    this.assignedTo,
    this.region,
    this.note,
    this.clientUser,
    this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  LeadEntity copyWith({int? statusId, String? statusName}) => LeadEntity(
        id: id,
        fullName: fullName,
        phone: phone,
        statusId: statusId ?? this.statusId,
        statusName: statusName ?? this.statusName,
        source: source,
        assignedTo: assignedTo,
        region: region,
        note: note,
        clientUser: clientUser,
        createdByName: createdByName,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  @override
  List<Object?> get props => [id, fullName, phone, statusId, source, createdAt];
}

class LeadStatusHistory extends Equatable {
  final int id;
  final int? fromStatusId;
  final String? fromStatusName;
  final int toStatusId;
  final String toStatusName;
  final String? changedByName;
  final String createdAt;

  const LeadStatusHistory({
    required this.id,
    this.fromStatusId,
    this.fromStatusName,
    required this.toStatusId,
    required this.toStatusName,
    this.changedByName,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id];
}
