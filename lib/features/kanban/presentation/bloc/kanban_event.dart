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
