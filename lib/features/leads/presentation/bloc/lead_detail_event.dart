part of 'lead_detail_bloc.dart';

abstract class LeadDetailEvent extends Equatable {
  const LeadDetailEvent();
  @override
  List<Object?> get props => [];
}

class LeadDetailLoadRequested extends LeadDetailEvent {
  final int leadId;
  const LeadDetailLoadRequested(this.leadId);
  @override
  List<Object?> get props => [leadId];
}

class LeadStatusChangeRequested extends LeadDetailEvent {
  final int statusId;
  const LeadStatusChangeRequested(this.statusId);
  @override
  List<Object?> get props => [statusId];
}
