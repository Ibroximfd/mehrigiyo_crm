part of 'kanban_bloc.dart';

abstract class KanbanState extends Equatable {
  const KanbanState();
  @override
  List<Object?> get props => [];
}

class KanbanInitial extends KanbanState {}

class KanbanLoading extends KanbanState {}

class KanbanLoaded extends KanbanState {
  final List<StatusEntity> statuses;
  final Map<int, List<LeadEntity>> leadsByStatus;
  final bool isMoving;

  const KanbanLoaded({
    required this.statuses,
    required this.leadsByStatus,
    this.isMoving = false,
  });

  KanbanLoaded copyWith({
    List<StatusEntity>? statuses,
    Map<int, List<LeadEntity>>? leadsByStatus,
    bool? isMoving,
  }) =>
      KanbanLoaded(
        statuses: statuses ?? this.statuses,
        leadsByStatus: leadsByStatus ?? this.leadsByStatus,
        isMoving: isMoving ?? this.isMoving,
      );

  @override
  List<Object?> get props => [statuses, leadsByStatus, isMoving];
}

class KanbanError extends KanbanState {
  final String message;
  const KanbanError(this.message);
  @override
  List<Object?> get props => [message];
}
