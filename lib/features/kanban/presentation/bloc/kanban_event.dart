part of 'kanban_bloc.dart';

abstract class KanbanEvent extends Equatable {
  const KanbanEvent();
  @override
  List<Object?> get props => [];
}

class KanbanLoadRequested extends KanbanEvent {
  const KanbanLoadRequested();
}

class KanbanLeadStatusChanged extends KanbanEvent {
  final int leadId;
  final int newStatusId;
  final int oldStatusId;

  const KanbanLeadStatusChanged({
    required this.leadId,
    required this.newStatusId,
    required this.oldStatusId,
  });

  @override
  List<Object?> get props => [leadId, newStatusId, oldStatusId];
}

class KanbanCreateLead extends KanbanEvent {
  final String fullName;
  final String phone;
  final String? region;
  final String? note;
  final int? statusId;

  const KanbanCreateLead({
    required this.fullName,
    required this.phone,
    this.region,
    this.note,
    this.statusId,
  });

  @override
  List<Object?> get props => [fullName, phone, region, note, statusId];
}

// WebSocket events (internal — dispatched from WS stream handler)
class KanbanWsConnectRequested extends KanbanEvent {
  const KanbanWsConnectRequested();
}

class KanbanWsLeadStatusChanged extends KanbanEvent {
  final int leadId;
  final int fromStatus;
  final int toStatus;
  const KanbanWsLeadStatusChanged({
    required this.leadId,
    required this.fromStatus,
    required this.toStatus,
  });
  @override
  List<Object?> get props => [leadId, fromStatus, toStatus];
}

class KanbanWsLeadAssigned extends KanbanEvent {
  final List<LeadEntity> leads;
  const KanbanWsLeadAssigned(this.leads);
  @override
  List<Object?> get props => [leads];
}

class KanbanWsLeadCreated extends KanbanEvent {
  final LeadEntity lead;
  const KanbanWsLeadCreated(this.lead);
  @override
  List<Object?> get props => [lead];
}
