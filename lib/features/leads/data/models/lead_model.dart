import '../../domain/entities/lead_entity.dart';

class LeadModel extends LeadEntity {
  const LeadModel({
    required super.id,
    required super.fullName,
    required super.phone,
    super.statusId,
    super.statusName,
    required super.source,
    super.assignedTo,
    super.region,
    super.note,
    super.clientUser,
    super.createdByName,
    required super.createdAt,
    required super.updatedAt,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    final assigned = json['assigned_to'];
    return LeadModel(
      id: json['id'] as int,
      fullName: json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      statusId: json['status'] is int ? json['status'] as int : null,
      statusName: json['status_name']?.toString(),
      source: json['source']?.toString() ?? 'manual',
      assignedTo: assigned is Map
          ? AssignedTo(
              id: assigned['id'] as int,
              fullName: assigned['full_name']?.toString() ?? '',
            )
          : null,
      region: json['region']?.toString(),
      note: json['note']?.toString(),
      clientUser: json['client_user']?.toString(),
      createdByName: (json['created_by'] as Map?)?.values.lastOrNull?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}

class LeadStatusHistoryModel extends LeadStatusHistory {
  const LeadStatusHistoryModel({
    required super.id,
    super.fromStatusId,
    super.fromStatusName,
    required super.toStatusId,
    required super.toStatusName,
    super.changedByName,
    required super.createdAt,
  });

  factory LeadStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    final from = json['from_status'] as Map<String, dynamic>?;
    final to = json['to_status'] as Map<String, dynamic>? ?? {};
    final changedBy = json['changed_by'] as Map<String, dynamic>?;
    return LeadStatusHistoryModel(
      id: json['id'] as int,
      fromStatusId: from?['id'] as int?,
      fromStatusName: from?['name']?.toString(),
      toStatusId: to['id'] as int? ?? 0,
      toStatusName: to['name']?.toString() ?? '',
      changedByName: changedBy?['full_name']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
