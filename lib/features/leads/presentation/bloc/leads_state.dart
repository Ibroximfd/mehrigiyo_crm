part of 'leads_bloc.dart';

abstract class LeadsState extends Equatable {
  const LeadsState();
  @override
  List<Object?> get props => [];
}

class LeadsInitial extends LeadsState {}

class LeadsLoading extends LeadsState {}

class LeadsLoaded extends LeadsState {
  final List<LeadEntity> leads;
  final bool hasMore;
  final int page;
  final int? filterStatusId;

  const LeadsLoaded({
    required this.leads,
    this.hasMore = false,
    this.page = 1,
    this.filterStatusId,
  });

  LeadsLoaded copyWith({
    List<LeadEntity>? leads,
    bool? hasMore,
    int? page,
    int? filterStatusId,
  }) =>
      LeadsLoaded(
        leads: leads ?? this.leads,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        filterStatusId: filterStatusId ?? this.filterStatusId,
      );

  @override
  List<Object?> get props => [leads, hasMore, page, filterStatusId];
}

class LeadsError extends LeadsState {
  final String message;
  const LeadsError(this.message);
  @override
  List<Object?> get props => [message];
}

class LeadCreating extends LeadsState {
  final List<LeadEntity> leads;
  const LeadCreating(this.leads);
  @override
  List<Object?> get props => [leads];
}

class LeadCreated extends LeadsState {
  final LeadEntity lead;
  final List<LeadEntity> leads;
  const LeadCreated({required this.lead, required this.leads});
  @override
  List<Object?> get props => [lead, leads];
}

class LeadCreateError extends LeadsState {
  final String message;
  final List<LeadEntity> leads;
  const LeadCreateError({required this.message, required this.leads});
  @override
  List<Object?> get props => [message, leads];
}
