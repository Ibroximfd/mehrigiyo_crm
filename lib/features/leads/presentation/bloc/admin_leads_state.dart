part of 'admin_leads_bloc.dart';

abstract class AdminLeadsState extends Equatable {
  const AdminLeadsState();
  @override
  List<Object?> get props => [];
}

class AdminLeadsInitial extends AdminLeadsState {}

class AdminLeadsLoading extends AdminLeadsState {}

class AdminLeadsLoaded extends AdminLeadsState {
  final List<LeadEntity> leads;
  final bool hasMore;
  final int page;
  final int? filterStatusId;
  final int? filterOperatorId;
  final bool filterUnassigned;
  final Set<int> selectedIds;
  final String? assignError;

  const AdminLeadsLoaded({
    required this.leads,
    this.hasMore = false,
    this.page = 1,
    this.filterStatusId,
    this.filterOperatorId,
    this.filterUnassigned = false,
    this.selectedIds = const {},
    this.assignError,
  });

  AdminLeadsLoaded copyWith({
    List<LeadEntity>? leads,
    bool? hasMore,
    int? page,
    int? filterStatusId,
    int? filterOperatorId,
    bool? filterUnassigned,
    Set<int>? selectedIds,
    String? assignError,
  }) =>
      AdminLeadsLoaded(
        leads: leads ?? this.leads,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        filterStatusId: filterStatusId ?? this.filterStatusId,
        filterOperatorId: filterOperatorId ?? this.filterOperatorId,
        filterUnassigned: filterUnassigned ?? this.filterUnassigned,
        selectedIds: selectedIds ?? this.selectedIds,
        assignError: assignError ?? this.assignError,
      );

  @override
  List<Object?> get props => [leads, hasMore, page, filterStatusId, filterOperatorId, filterUnassigned, selectedIds, assignError];
}

class AdminLeadsError extends AdminLeadsState {
  final String message;
  const AdminLeadsError(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminLeadsAssigning extends AdminLeadsState {
  final List<LeadEntity> leads;
  const AdminLeadsAssigning(this.leads);
  @override
  List<Object?> get props => [leads];
}

class AdminLeadsAssigned extends AdminLeadsState {
  final int count;
  const AdminLeadsAssigned(this.count);
  @override
  List<Object?> get props => [count];
}

class AdminLeadsBulkCreating extends AdminLeadsState {}

class AdminLeadsBulkCreated extends AdminLeadsState {
  final int count;
  const AdminLeadsBulkCreated(this.count);
  @override
  List<Object?> get props => [count];
}
