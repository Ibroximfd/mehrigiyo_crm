import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/lead_entity.dart';
import '../../domain/usecases/lead_usecases.dart';

part 'leads_event.dart';
part 'leads_state.dart';

class LeadsBloc extends Bloc<LeadsEvent, LeadsState> {
  final GetMyLeadsUseCase getMyLeads;
  final CreateLeadUseCase createLead;

  LeadsBloc({required this.getMyLeads, required this.createLead})
      : super(LeadsInitial()) {
    on<LeadsLoadRequested>(_onLoad);
    on<LeadsLoadMore>(_onLoadMore);
    on<LeadCreateRequested>(_onCreate);
  }

  List<LeadEntity> get _currentLeads =>
      state is LeadsLoaded
          ? (state as LeadsLoaded).leads
          : state is LeadCreating
              ? (state as LeadCreating).leads
              : state is LeadCreated
                  ? (state as LeadCreated).leads
                  : state is LeadCreateError
                      ? (state as LeadCreateError).leads
                      : [];

  Future<void> _onLoad(LeadsLoadRequested event, Emitter<LeadsState> emit) async {
    emit(LeadsLoading());
    final result = await getMyLeads(
      statusIds: event.statusId == null ? null : [event.statusId!],
      category: event.category,
    );
    result.fold(
      (f) => emit(LeadsError(f.message)),
      (leads) => emit(LeadsLoaded(leads: leads, hasMore: leads.length >= 20, filterStatusId: event.statusId)),
    );
  }

  Future<void> _onLoadMore(LeadsLoadMore event, Emitter<LeadsState> emit) async {
    final cur = state;
    if (cur is! LeadsLoaded || !cur.hasMore) return;
    final nextPage = cur.page + 1;
    final result = await getMyLeads(
      statusIds: cur.filterStatusId == null ? null : [cur.filterStatusId!],
      page: nextPage,
    );
    result.fold(
      (f) => null,
      (more) => emit(cur.copyWith(
        leads: [...cur.leads, ...more],
        page: nextPage,
        hasMore: more.length >= 20,
      )),
    );
  }

  Future<void> _onCreate(LeadCreateRequested event, Emitter<LeadsState> emit) async {
    final prevLeads = _currentLeads;
    emit(LeadCreating(prevLeads));
    final result = await createLead(
      fullName: event.fullName, phone: event.phone, source: event.source,
      region: event.region, note: event.note, statusId: event.statusId,
    );
    result.fold(
      (f) => emit(LeadCreateError(message: f.message, leads: prevLeads)),
      (lead) => emit(LeadCreated(
        lead: lead,
        leads: [lead, ...prevLeads],
      )),
    );
  }
}
