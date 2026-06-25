part of 'lead_detail_bloc.dart';

abstract class LeadDetailState extends Equatable {
  const LeadDetailState();
  @override
  List<Object?> get props => [];
}

class LeadDetailInitial extends LeadDetailState {}

class LeadDetailLoading extends LeadDetailState {}

class LeadDetailLoaded extends LeadDetailState {
  final LeadEntity lead;
  final List<LeadStatusHistory> history;
  final List<StatusEntity> statuses;
  final String? statusError;

  const LeadDetailLoaded({
    required this.lead,
    required this.history,
    this.statuses = const [],
    this.statusError,
  });

  @override
  List<Object?> get props => [lead, history, statuses, statusError];
}

class LeadDetailChangingStatus extends LeadDetailState {
  final LeadEntity lead;
  final List<LeadStatusHistory> history;
  final List<StatusEntity> statuses;

  const LeadDetailChangingStatus({
    required this.lead,
    required this.history,
    this.statuses = const [],
  });

  @override
  List<Object?> get props => [lead, history, statuses];
}

class LeadDetailError extends LeadDetailState {
  final String message;
  const LeadDetailError(this.message);
  @override
  List<Object?> get props => [message];
}
