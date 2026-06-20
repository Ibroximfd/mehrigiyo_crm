import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/bulk_lead_input.dart';
import '../../domain/entities/lead_entity.dart';
import '../../domain/usecases/lead_usecases.dart';

part 'admin_leads_event.dart';
part 'admin_leads_state.dart';

class AdminLeadsBloc extends Bloc<AdminLeadsEvent, AdminLeadsState> {
  final GetAdminLeadsUseCase getAdminLeads;
  final AssignLeadsUseCase assignLeads;
  final BulkCreateLeadsUseCase bulkCreateLeads;

  AdminLeadsBloc({
    required this.getAdminLeads,
    required this.assignLeads,
    required this.bulkCreateLeads,
  }) : super(AdminLeadsInitial()) {
    on<AdminLeadsLoadRequested>(_onLoad);
    on<AdminLeadsLoadMore>(_onLoadMore);
    on<AdminLeadsFilterChanged>(_onFilter);
    on<AdminLeadsAssignRequested>(_onAssign);
    on<AdminLeadSelectionToggled>(_onToggle);
    on<AdminLeadSelectionCleared>(_onClearSelection);
    on<AdminLeadsBulkCreateRequested>(_onBulkCreate);
  }

  Future<void> _onLoad(AdminLeadsLoadRequested event, Emitter<AdminLeadsState> emit) async {
    emit(AdminLeadsLoading());
    final result = await getAdminLeads(
      statusId: event.statusId, assignedTo: event.assignedTo, source: event.source,
    );
    result.fold(
      (f) => emit(AdminLeadsError(f.message)),
      (leads) => emit(AdminLeadsLoaded(
        leads: leads, hasMore: leads.length >= 20,
        filterStatusId: event.statusId, filterOperatorId: event.assignedTo,
      )),
    );
  }

  Future<void> _onLoadMore(AdminLeadsLoadMore event, Emitter<AdminLeadsState> emit) async {
    final cur = state;
    if (cur is! AdminLeadsLoaded || !cur.hasMore) return;
    final result = await getAdminLeads(
      statusId: cur.filterStatusId,
      assignedTo: cur.filterOperatorId,
      page: cur.page + 1,
    );
    result.fold(
      (f) => null,
      (more) => emit(cur.copyWith(
        leads: [...cur.leads, ...more],
        page: cur.page + 1,
        hasMore: more.length >= 20,
      )),
    );
  }

  Future<void> _onFilter(AdminLeadsFilterChanged event, Emitter<AdminLeadsState> emit) async {
    add(AdminLeadsLoadRequested(statusId: event.statusId, assignedTo: event.assignedTo));
  }

  Future<void> _onAssign(AdminLeadsAssignRequested event, Emitter<AdminLeadsState> emit) async {
    final cur = state;
    if (cur is! AdminLeadsLoaded) return;
    emit(AdminLeadsAssigning(cur.leads));
    final result = await assignLeads(leadIds: event.leadIds, operatorId: event.operatorId);
    result.fold(
      (f) => emit(AdminLeadsLoaded(leads: cur.leads, hasMore: cur.hasMore, assignError: f.message)),
      (count) {
        emit(AdminLeadsAssigned(count));
        add(AdminLeadsLoadRequested(
          statusId: cur.filterStatusId, assignedTo: cur.filterOperatorId,
        ));
      },
    );
  }

  void _onToggle(AdminLeadSelectionToggled event, Emitter<AdminLeadsState> emit) {
    final cur = state;
    if (cur is! AdminLeadsLoaded) return;
    final selected = Set<int>.from(cur.selectedIds);
    if (selected.contains(event.leadId)) {
      selected.remove(event.leadId);
    } else {
      selected.add(event.leadId);
    }
    emit(cur.copyWith(selectedIds: selected));
  }

  void _onClearSelection(AdminLeadSelectionCleared event, Emitter<AdminLeadsState> emit) {
    final cur = state;
    if (cur is! AdminLeadsLoaded) return;
    emit(cur.copyWith(selectedIds: {}));
  }

  Future<void> _onBulkCreate(
    AdminLeadsBulkCreateRequested event,
    Emitter<AdminLeadsState> emit,
  ) async {
    emit(AdminLeadsBulkCreating());
    final result = await bulkCreateLeads(event.leads.map((l) => l.toJson()).toList());
    result.fold(
      (f) => emit(AdminLeadsError(f.message)),
      (count) {
        emit(AdminLeadsBulkCreated(count));
        add(const AdminLeadsLoadRequested());
      },
    );
  }
}
