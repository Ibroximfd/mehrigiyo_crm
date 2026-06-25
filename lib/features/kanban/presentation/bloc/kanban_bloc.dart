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

    // Optimistic move — the lead jumps to the new column immediately.
    final optimistic = _moveLead(
      cur.leadsByStatus,
      leadId: event.leadId,
      toStatusId: event.newStatusId,
    );
    if (optimistic == null) return; // lead not found or already there
    emit(cur.copyWith(leadsByStatus: optimistic, isMoving: true));

    final result = await changeStatus(leadId: event.leadId, statusId: event.newStatusId);

    // Re-read the latest state: other WS events may have arrived during the await.
    final latest = state;
    if (latest is! KanbanLoaded) return;

    result.fold(
      (_) {
        // Genuine API failure — revert just this lead, based on the latest state
        // (never wipe concurrent updates by reusing the stale snapshot).
        final reverted = _moveLead(
          latest.leadsByStatus,
          leadId: event.leadId,
          toStatusId: event.oldStatusId,
        );
        emit(latest.copyWith(
          leadsByStatus: reverted ?? latest.leadsByStatus,
          isMoving: false,
        ));
      },
      // Success — keep the optimistic state; the WS echo is idempotent (no-op).
      (_) => emit(latest.copyWith(isMoving: false)),
    );
  }

  /// Moves a lead to [toStatusId] regardless of where it currently sits, and
  /// returns a fresh map. Returns null when there is nothing to do — the lead
  /// isn't on the board, it's already in the target column, or the target
  /// column isn't loaded. Idempotent and duplicate-safe.
  Map<int, List<LeadEntity>>? _moveLead(
    Map<int, List<LeadEntity>> source, {
    required int leadId,
    required int toStatusId,
  }) {
    LeadEntity? lead;
    int? currentStatusId;
    for (final entry in source.entries) {
      for (final l in entry.value) {
        if (l.id == leadId) {
          lead = l;
          currentStatusId = entry.key;
          break;
        }
      }
      if (lead != null) break;
    }
    if (lead == null) return null;
    if (currentStatusId == toStatusId) return null; // already there
    if (!source.containsKey(toStatusId)) return null; // target not loaded

    final moved = lead.copyWith(statusId: toStatusId);
    final updated = <int, List<LeadEntity>>{};
    source.forEach((k, v) {
      updated[k] = v.where((l) => l.id != leadId).toList();
    });
    updated[toStatusId] = [moved, ...updated[toStatusId]!];
    return updated;
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

    // Idempotent: if the lead is already in the target column (e.g. this is the
    // echo of our own optimistic move), _moveLead returns null and we skip the
    // emit — so no flicker and no extra rebuild.
    final updated = _moveLead(
      cur.leadsByStatus,
      leadId: event.leadId,
      toStatusId: event.toStatus,
    );
    if (updated != null) emit(cur.copyWith(leadsByStatus: updated));
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
