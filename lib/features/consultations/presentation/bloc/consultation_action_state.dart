import 'package:equatable/equatable.dart';
import '../../domain/entities/consultation_entity.dart';

abstract class ConsultationActionState extends Equatable {
  const ConsultationActionState();

  @override
  List<Object?> get props => [];
}

class ConsultationActionInitial extends ConsultationActionState {}

class ConsultationActionLoading extends ConsultationActionState {}

class ConsultationActionSuccess extends ConsultationActionState {
  final ConsultationEntity updated;
  final String message;

  const ConsultationActionSuccess({
    required this.updated,
    required this.message,
  });

  @override
  List<Object?> get props => [updated, message];
}

class ConsultationActionError extends ConsultationActionState {
  final String message;
  const ConsultationActionError(this.message);

  @override
  List<Object?> get props => [message];
}
