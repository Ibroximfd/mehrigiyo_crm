import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/websocket/operator_ws_service.dart';
import '../../../leads/data/models/lead_model.dart';
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
  final OperatorWsService wsService;

  bool _wsStarted = false;

  KanbanBloc({
    required this.getStatuses,
    required this.getMyLeads,
    required this.changeStatus,
    required this.createLead,
    required this.wsService,
  }) : super(KanbanInitial()) {
    on<KanbanLoadRequested>(_onLoad);
    on<KanbanLeadStatusChanged>(_onStatusChange);
    on<KanbanCreateLead>(_onCreate);
    // WebSocket — droppable ensures only one subscription runs at a time
    on<KanbanWsConnectRequested>(_onWsConnect, transformer: droppable());
    on<KanbanWsLeadStatusChanged>(_onWsStatusChanged);
    on<KanbanWsLeadAssigned>(_onWsLeadAssigned);
    on<KanbanWsLeadCreated>(_onWsLeadCreated);
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

    // Start WebSocket subscription once
    if (!_wsStarted) {
      _wsStarted = true;
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isNotEmpty) {
        wsService.connect(token);
        add(const KanbanWsConnectRequested());
      }
    }
  }

  Future<void> _onStatusChange(
    KanbanLeadStatusChanged event,
    Emitter<KanbanState> emit,
  ) async {
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
      (f) => emit(cur.copyWith(leadsByStatus: cur.leadsByStatus, isMoving: false)),
      (_) => emit(cur.copyWith(isMoving: false)),
    );
  }

  Future<void> _onCreate(KanbanCreateLead event, Emitter<KanbanState> emit) async {
    final cur = state;
    if (cur is! KanbanLoaded) return;

    final result = await createLead(
      fullName: event.fullName,
      phone: event.phone,
      region: event.region,
      note: event.note,
      statusId: event.statusId,
    );
    result.fold(
      (_) => null,
      (lead) {
        final updated = Map<int, List<LeadEntity>>.from(
          cur.leadsByStatus.map((k, v) => MapEntry(k, List<LeadEntity>.from(v))),
        );
        final targetId = lead.statusId;
        if (targetId != null && updated.containsKey(targetId)) {
          updated[targetId] = [lead, ...updated[targetId]!];
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

  // ── WebSocket handlers ────────────────────────────────────────────────────

  Future<void> _onWsConnect(
    KanbanWsConnectRequested event,
    Emitter<KanbanState> emit,
  ) async {
    // Runs forever (until bloc is closed). droppable() prevents duplicates.
    await emit.onEach(
      wsService.events,
      onData: (data) {
        final type = data['type'] as String?;
        switch (type) {
          case 'lead_status_changed':
            add(KanbanWsLeadStatusChanged(
              leadId: data['lead_id'] as int,
              fromStatus: data['from_status'] as int,
              toStatus: data['to_status'] as int,
            ));
          case 'lead_assigned':
            final list = data['leads'] as List? ?? [];
            final leads = list
                .map((j) => LeadModel.fromJson(j as Map<String, dynamic>))
                .toList();
            add(KanbanWsLeadAssigned(leads));
          case 'lead_created':
            final j = data['lead'] as Map<String, dynamic>?;
            if (j != null) add(KanbanWsLeadCreated(LeadModel.fromJson(j)));
        }
      },
    );
  }

  void _onWsStatusChanged(KanbanWsLeadStatusChanged event, Emitter<KanbanState> emit) {
    final cur = state;
    if (cur is! KanbanLoaded) return;

    final updated = Map<int, List<LeadEntity>>.from(
      cur.leadsByStatus.map((k, v) => MapEntry(k, List<LeadEntity>.from(v))),
    );
    LeadEntity? moved;
    updated[event.fromStatus]?.removeWhere((l) {
      if (l.id == event.leadId) {
        moved = l.copyWith(statusId: event.toStatus);
        return true;
      }
      return false;
    });
    if (moved != null && updated.containsKey(event.toStatus)) {
      // Skip if already there (self-update echo)
      final alreadyThere = updated[event.toStatus]!.any((l) => l.id == event.leadId);
      if (!alreadyThere) {
        updated[event.toStatus] = [moved!, ...updated[event.toStatus]!];
      }
    }
    emit(cur.copyWith(leadsByStatus: updated));
  }

  void _onWsLeadAssigned(KanbanWsLeadAssigned event, Emitter<KanbanState> emit) {
    final cur = state;
    if (cur is! KanbanLoaded) return;

    final updated = Map<int, List<LeadEntity>>.from(
      cur.leadsByStatus.map((k, v) => MapEntry(k, List<LeadEntity>.from(v))),
    );
    for (final lead in event.leads) {
      final statusId = lead.statusId;
      if (statusId == null || !updated.containsKey(statusId)) continue;
      final alreadyThere = updated[statusId]!.any((l) => l.id == lead.id);
      if (!alreadyThere) {
        updated[statusId] = [lead, ...updated[statusId]!];
      }
    }
    emit(cur.copyWith(leadsByStatus: updated));
  }

  void _onWsLeadCreated(KanbanWsLeadCreated event, Emitter<KanbanState> emit) {
    final cur = state;
    if (cur is! KanbanLoaded) return;

    final lead = event.lead;
    final statusId = lead.statusId;
    if (statusId == null) return;

    final updated = Map<int, List<LeadEntity>>.from(
      cur.leadsByStatus.map((k, v) => MapEntry(k, List<LeadEntity>.from(v))),
    );
    if (!updated.containsKey(statusId)) return;
    final alreadyThere = updated[statusId]!.any((l) => l.id == lead.id);
    if (!alreadyThere) {
      updated[statusId] = [lead, ...updated[statusId]!];
      emit(cur.copyWith(leadsByStatus: updated));
    }
  }

  @override
  Future<void> close() {
    _wsStarted = false;
    wsService.disconnect();
    return super.close();
  }
}
