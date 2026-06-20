part of 'admin_leads_bloc.dart';

abstract class AdminLeadsEvent extends Equatable {
  const AdminLeadsEvent();
  @override
  List<Object?> get props => [];
}

class AdminLeadsLoadRequested extends AdminLeadsEvent {
  final int? statusId;
  final int? assignedTo;
  final String? source;
  const AdminLeadsLoadRequested({this.statusId, this.assignedTo, this.source});
  @override
  List<Object?> get props => [statusId, assignedTo, source];
}

class AdminLeadsLoadMore extends AdminLeadsEvent {
  const AdminLeadsLoadMore();
}

class AdminLeadsFilterChanged extends AdminLeadsEvent {
  final int? statusId;
  final int? assignedTo;
  const AdminLeadsFilterChanged({this.statusId, this.assignedTo});
  @override
  List<Object?> get props => [statusId, assignedTo];
}

class AdminLeadsAssignRequested extends AdminLeadsEvent {
  final List<int> leadIds;
  final int operatorId;
  const AdminLeadsAssignRequested({required this.leadIds, required this.operatorId});
  @override
  List<Object?> get props => [leadIds, operatorId];
}

class AdminLeadSelectionToggled extends AdminLeadsEvent {
  final int leadId;
  const AdminLeadSelectionToggled(this.leadId);
  @override
  List<Object?> get props => [leadId];
}

class AdminLeadSelectionCleared extends AdminLeadsEvent {
  const AdminLeadSelectionCleared();
}
