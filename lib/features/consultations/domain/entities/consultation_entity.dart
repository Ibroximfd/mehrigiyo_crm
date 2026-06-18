import 'package:equatable/equatable.dart';

class ConsultationEntity extends Equatable {
  final String id;
  final String clientName;
  final String phone;
  final String issueDescription;
  final int status;
  final String statusDisplay;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? operatorNote;
  final String? operatorId;
  final String? operatorName;

  const ConsultationEntity({
    required this.id,
    required this.clientName,
    required this.phone,
    required this.issueDescription,
    required this.status,
    required this.statusDisplay,
    required this.createdAt,
    this.updatedAt,
    this.operatorNote,
    this.operatorId,
    this.operatorName,
  });

  ConsultationEntity copyWith({
    String? operatorNote,
    int? status,
    String? statusDisplay,
    DateTime? updatedAt,
  }) {
    return ConsultationEntity(
      id: id,
      clientName: clientName,
      phone: phone,
      issueDescription: issueDescription,
      status: status ?? this.status,
      statusDisplay: statusDisplay ?? this.statusDisplay,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      operatorNote: operatorNote ?? this.operatorNote,
      operatorId: operatorId,
      operatorName: operatorName,
    );
  }

  @override
  List<Object?> get props => [
    id,
    clientName,
    phone,
    issueDescription,
    status,
    statusDisplay,
    createdAt,
    updatedAt,
    operatorNote,
    operatorId,
    operatorName,
  ];
}
