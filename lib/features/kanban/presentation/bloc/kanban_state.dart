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

/// A drag/move was reverted because the API call failed. Subtype of
/// [KanbanLoaded] so the board still renders normally; the page listens for
/// this specific type to surface a one-shot error SnackBar. [nonce] keeps two
/// consecutive identical failures distinct so the listener always fires.
class KanbanMoveFailure extends KanbanLoaded {
  final String error;
  final int nonce;

  KanbanMoveFailure({
    required super.statuses,
    required super.leadsByStatus,
    required this.error,
  })  : nonce = DateTime.now().microsecondsSinceEpoch,
        super(isMoving: false);

  @override
  List<Object?> get props => [...super.props, error, nonce];
}

class KanbanError extends KanbanState {
  final String message;
  const KanbanError(this.message);
  @override
  List<Object?> get props => [message];
}
