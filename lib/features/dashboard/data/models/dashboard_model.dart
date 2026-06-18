import '../../domain/entities/dashboard_entity.dart';

class DashboardModel extends DashboardEntity {
  const DashboardModel({
    required super.newConsultationsCount,
    required super.inProgressConsultationsCount,
    required super.completedConsultationsCount,
    required super.totalConsultationsCount,
    required super.personalNew,
    required super.personalInProgress,
    required super.personalCompleted,
    required super.personalTotal,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final general = json['general'] as Map<String, dynamic>? ?? {};
    final personal = json['personal'] as Map<String, dynamic>? ?? {};
    return DashboardModel(
      newConsultationsCount: (general['yangi'] as num?)?.toInt() ?? 0,
      inProgressConsultationsCount:
          (general['jarayonda'] as num?)?.toInt() ?? 0,
      completedConsultationsCount:
          (general['tugatilgan'] as num?)?.toInt() ?? 0,
      totalConsultationsCount: (general['total'] as num?)?.toInt() ?? 0,
      personalNew: (personal['yangi'] as num?)?.toInt() ?? 0,
      personalInProgress: (personal['jarayonda'] as num?)?.toInt() ?? 0,
      personalCompleted: (personal['tugatilgan'] as num?)?.toInt() ?? 0,
      personalTotal: (personal['total'] as num?)?.toInt() ?? 0,
    );
  }
}
