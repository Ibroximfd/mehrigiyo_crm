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
    // `status` may come back as an int id or a nested {id, name} object
    // depending on the endpoint — handle both so parsing never throws.
    final status = json['status'];
    return LeadModel(
      id: (json['id'] as num).toInt(),
      fullName: json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      statusId: status is num
          ? status.toInt()
          : status is Map
              ? (status['id'] as num?)?.toInt()
              : null,
      statusName: json['status_name']?.toString() ??
          (status is Map ? status['name']?.toString() : null),
      source: json['source']?.toString() ?? 'manual',
      assignedTo: assigned is Map
          ? AssignedTo(
              id: (assigned['id'] as num?)?.toInt() ?? 0,
              fullName: assigned['full_name']?.toString() ?? '',
            )
          : null,
      region: json['region']?.toString(),
      note: json['note']?.toString(),
      clientUser: json['client_user']?.toString(),
      createdByName: json['created_by'] is Map
          ? (json['created_by'] as Map)['full_name']?.toString()
          : null,
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
