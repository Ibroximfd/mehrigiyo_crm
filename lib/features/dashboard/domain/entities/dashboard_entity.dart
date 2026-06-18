import 'package:equatable/equatable.dart';

class DashboardEntity extends Equatable {
  final int newConsultationsCount;
  final int inProgressConsultationsCount;
  final int completedConsultationsCount;
  final int totalConsultationsCount;
  final int personalNew;
  final int personalInProgress;
  final int personalCompleted;
  final int personalTotal;

  const DashboardEntity({
    required this.newConsultationsCount,
    required this.inProgressConsultationsCount,
    required this.completedConsultationsCount,
    required this.totalConsultationsCount,
    required this.personalNew,
    required this.personalInProgress,
    required this.personalCompleted,
    required this.personalTotal,
  });

  @override
  List<Object?> get props => [
    newConsultationsCount,
    inProgressConsultationsCount,
    completedConsultationsCount,
    totalConsultationsCount,
    personalNew,
    personalInProgress,
    personalCompleted,
    personalTotal,
  ];
}
