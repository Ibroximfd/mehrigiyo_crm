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
  final String? statusError;

  const LeadDetailLoaded({
    required this.lead,
    required this.history,
    this.statusError,
  });

  @override
  List<Object?> get props => [lead, history, statusError];
}

class LeadDetailChangingStatus extends LeadDetailState {
  final LeadEntity lead;
  final List<LeadStatusHistory> history;

  const LeadDetailChangingStatus({required this.lead, required this.history});

  @override
  List<Object?> get props => [lead, history];
}

class LeadDetailError extends LeadDetailState {
  final String message;
  const LeadDetailError(this.message);
  @override
  List<Object?> get props => [message];
}
