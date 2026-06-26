part of 'kanban_bloc.dart';

abstract class KanbanState extends Equatable {
  const KanbanState();
  @override
  List<Object?> get props => [];
}

class KanbanInitial extends KanbanState {}

class KanbanLoading extends KanbanState {}

class KanbanLoaded extends KanbanState {
  /// Full universe of statuses (both categories) — used for the filter options.
  final List<StatusEntity> statuses;
  final Map<int, List<LeadEntity>> leadsByStatus;
  final bool isMoving;

  /// Active filters. [category] null = all categories; [selectedStatusIds]
  /// empty = all statuses within the category. [isFiltering] is true while a
  /// filtered reload is in flight (keeps the board visible instead of a spinner).
  final String? category;
  final Set<int> selectedStatusIds;
  final bool isFiltering;

  const KanbanLoaded({
    required this.statuses,
    required this.leadsByStatus,
    this.isMoving = false,
    this.category,
    this.selectedStatusIds = const {},
    this.isFiltering = false,
  });

  /// Statuses (columns) that should be rendered given the active filters.
  List<StatusEntity> get visibleStatuses {
    Iterable<StatusEntity> v = statuses;
    if (category != null) v = v.where((s) => s.category == category);
    if (selectedStatusIds.isNotEmpty) {
      v = v.where((s) => selectedStatusIds.contains(s.id));
    }
    return v.toList();
  }

  bool get hasActiveFilter => category != null || selectedStatusIds.isNotEmpty;

  KanbanLoaded copyWith({
    List<StatusEntity>? statuses,
    Map<int, List<LeadEntity>>? leadsByStatus,
    bool? isMoving,
    String? category,
    bool clearCategory = false,
    Set<int>? selectedStatusIds,
    bool? isFiltering,
  }) =>
      KanbanLoaded(
        statuses: statuses ?? this.statuses,
        leadsByStatus: leadsByStatus ?? this.leadsByStatus,
        isMoving: isMoving ?? this.isMoving,
        category: clearCategory ? null : (category ?? this.category),
        selectedStatusIds: selectedStatusIds ?? this.selectedStatusIds,
        isFiltering: isFiltering ?? this.isFiltering,
      );

  @override
  List<Object?> get props =>
      [statuses, leadsByStatus, isMoving, category, selectedStatusIds, isFiltering];
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
    super.category,
    super.selectedStatusIds,
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
