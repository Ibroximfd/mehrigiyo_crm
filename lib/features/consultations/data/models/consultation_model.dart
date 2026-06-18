import '../../domain/entities/consultation_entity.dart';

class ConsultationModel extends ConsultationEntity {
  const ConsultationModel({
    required super.id,
    required super.clientName,
    required super.phone,
    required super.issueDescription,
    required super.status,
    required super.statusDisplay,
    required super.createdAt,
    super.updatedAt,
    super.operatorNote,
    super.operatorId,
    super.operatorName,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    return ConsultationModel(
      id: json['id']?.toString() ?? '',
      clientName: json['full_name'] ?? json['client_name'] ?? 'Noma\'lum',
      phone: json['phone']?.toString() ?? '',
      issueDescription: json['problem'] ?? json['issue_description'] ?? '',
      status: (json['status'] as num?)?.toInt() ?? 1,
      statusDisplay: json['status_display'] ?? _statusLabel(json['status']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      operatorNote: json['operator_note'],
      operatorId: json['operator_id']?.toString(),
      operatorName: json['operator_name'],
    );
  }

  static String _statusLabel(dynamic status) {
    switch (status) {
      case 1:
        return 'Yangi';
      case 2:
        return 'Jarayonda';
      case 3:
        return 'Tugatilgan';
      default:
        return 'Noma\'lum';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': clientName,
    'phone': phone,
    'problem': issueDescription,
    'status': status,
    'status_display': statusDisplay,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'operator_note': operatorNote,
    'operator_id': operatorId,
    'operator_name': operatorName,
  };
}
