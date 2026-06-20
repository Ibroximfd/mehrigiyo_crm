import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../leads/domain/entities/lead_entity.dart';
import '../../../leads/domain/usecases/lead_usecases.dart';
import '../../../statuses/domain/entities/status_entity.dart';
import '../../../statuses/domain/usecases/status_usecases.dart';

part 'kanban_event.dart';
part 'kanban_state.dart';

class KanbanBloc extends Bloc<KanbanEvent, KanbanState> {
  final GetStatusesUseCase getStatuses;
  final GetMyLeadsUseCase getMyLeads;
  final ChangeLeadStatusUseCase changeStatus;
  final CreateLeadUseCase createLead;

  KanbanBloc({
    required this.getStatuses,
    required this.getMyLeads,
    required this.changeStatus,
    required this.createLead,
  }) : super(KanbanInitial()) {
    on<KanbanLoadRequested>(_onLoad);
    on<KanbanLeadStatusChanged>(_onStatusChange);
    on<KanbanCreateLead>(_onCreate);
  }

  Future<void> _onLoad(KanbanLoadRequested event, Emitter<KanbanState> emit) async {
    emit(KanbanLoading());

    final statusResult = await getStatuses();
    final List<StatusEntity> statuses = statusResult.fold((_) => [], (s) => s);

    if (statuses.isEmpty) {
      emit(const KanbanError('Statuslar topilmadi. Admin statuslar yaratishi kerak.'));
      return;
    }

    final leadsResult = await getMyLeads();
    final List<LeadEntity> allLeads = leadsResult.fold((_) => [], (l) => l);

    final grouped = <int, List<LeadEntity>>{};
    for (final s in statuses) {
      grouped[s.id] = allLeads.where((l) => l.statusId == s.id).toList();
    }

    emit(KanbanLoaded(statuses: statuses, leadsByStatus: grouped));
  }

  Future<void> _onStatusChange(KanbanLeadStatusChanged event, Emitter<KanbanState> emit) async {
    final cur = state;
    if (cur is! KanbanLoaded) return;

    // Optimistic update
    final updated = Map<int, List<LeadEntity>>.from(
      cur.leadsByStatus.map((k, v) => MapEntry(k, List<LeadEntity>.from(v))),
    );
    LeadEntity? movedLead;
    updated[event.oldStatusId]?.removeWhere((l) {
      if (l.id == event.leadId) {
        movedLead = l.copyWith(statusId: event.newStatusId);
        return true;
      }
      return false;
    });
    if (movedLead != null) {
      updated[event.newStatusId] = [movedLead!, ...(updated[event.newStatusId] ?? [])];
    }
    emit(cur.copyWith(leadsByStatus: updated, isMoving: true));

    final result = await changeStatus(leadId: event.leadId, statusId: event.newStatusId);
    result.fold(
      (f) {
        // Rollback
        final rollback = Map<int, List<LeadEntity>>.from(cur.leadsByStatus);
        emit(cur.copyWith(leadsByStatus: rollback, isMoving: false));
      },
      (lead) => emit(cur.copyWith(isMoving: false)),
    );
  }

  Future<void> _onCreate(KanbanCreateLead event, Emitter<KanbanState> emit) async {
    final cur = state;
    if (cur is! KanbanLoaded) return;

    final result = await createLead(
      fullName: event.fullName, phone: event.phone,
      region: event.region, note: event.note, statusId: event.statusId,
    );
    result.fold(
      (_) => null,
      (lead) {
        final updated = Map<int, List<LeadEntity>>.from(
          cur.leadsByStatus.map((k, v) => MapEntry(k, List<LeadEntity>.from(v))),
        );
        final targetStatusId = lead.statusId;
        if (targetStatusId != null && updated.containsKey(targetStatusId)) {
          updated[targetStatusId] = [lead, ...updated[targetStatusId]!];
        } else {
          final defaultStatus = cur.statuses.firstWhere(
            (s) => s.isDefault,
            orElse: () => cur.statuses.first,
          );
          updated[defaultStatus.id] = [lead, ...(updated[defaultStatus.id] ?? [])];
        }
        emit(cur.copyWith(leadsByStatus: updated));
      },
    );
  }
}
