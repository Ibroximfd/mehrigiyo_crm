import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/lead_entity.dart';
import '../../domain/usecases/lead_usecases.dart';

part 'lead_detail_event.dart';
part 'lead_detail_state.dart';

class LeadDetailBloc extends Bloc<LeadDetailEvent, LeadDetailState> {
  final GetLeadDetailUseCase getDetail;
  final ChangeLeadStatusUseCase changeStatus;
  final GetLeadHistoryUseCase getHistory;

  LeadDetailBloc({
    required this.getDetail,
    required this.changeStatus,
    required this.getHistory,
  }) : super(LeadDetailInitial()) {
    on<LeadDetailLoadRequested>(_onLoad);
    on<LeadStatusChangeRequested>(_onStatusChange);
  }

  Future<void> _onLoad(LeadDetailLoadRequested event, Emitter<LeadDetailState> emit) async {
    emit(LeadDetailLoading());
    final detailResult = await getDetail(event.leadId);
    await detailResult.fold(
      (f) async => emit(LeadDetailError(f.message)),
      (lead) async {
        final histResult = await getHistory(event.leadId);
        final history = histResult.fold((_) => <LeadStatusHistory>[], (h) => h);
        emit(LeadDetailLoaded(lead: lead, history: history));
      },
    );
  }

  Future<void> _onStatusChange(LeadStatusChangeRequested event, Emitter<LeadDetailState> emit) async {
    final cur = state;
    if (cur is! LeadDetailLoaded) return;
    emit(LeadDetailChangingStatus(lead: cur.lead, history: cur.history));
    final result = await changeStatus(leadId: cur.lead.id, statusId: event.statusId);
    result.fold(
      (f) => emit(LeadDetailLoaded(lead: cur.lead, history: cur.history, statusError: f.message)),
      (updated) => emit(LeadDetailLoaded(lead: updated, history: cur.history)),
    );
  }
}
