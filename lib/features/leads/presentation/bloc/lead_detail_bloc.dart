import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/lead_entity.dart';
import '../../domain/usecases/lead_usecases.dart';
import '../../../statuses/domain/entities/status_entity.dart';
import '../../../statuses/domain/usecases/status_usecases.dart';

part 'lead_detail_event.dart';
part 'lead_detail_state.dart';

class LeadDetailBloc extends Bloc<LeadDetailEvent, LeadDetailState> {
  final GetLeadDetailUseCase getDetail;
  final ChangeLeadStatusUseCase changeStatus;
  final GetLeadHistoryUseCase getHistory;
  final GetStatusesUseCase getStatuses;

  LeadDetailBloc({
    required this.getDetail,
    required this.changeStatus,
    required this.getHistory,
    required this.getStatuses,
  }) : super(LeadDetailInitial()) {
    on<LeadDetailLoadRequested>(_onLoad);
    on<LeadStatusChangeRequested>(_onStatusChange);
  }

  Future<void> _onLoad(
    LeadDetailLoadRequested event,
    Emitter<LeadDetailState> emit,
  ) async {
    emit(LeadDetailLoading());
    final detailResult = await getDetail(event.leadId);
    await detailResult.fold((f) async => emit(LeadDetailError(f.message)), (
      lead,
    ) async {
      final histResult = await getHistory(event.leadId);
      final history = histResult.fold((_) => <LeadStatusHistory>[], (h) => h);
      final statusResult = await getStatuses();
      final statuses = statusResult.fold((_) => <StatusEntity>[], (s) => s);
      emit(LeadDetailLoaded(lead: lead, history: history, statuses: statuses));
    });
  }

  Future<void> _onStatusChange(
    LeadStatusChangeRequested event,
    Emitter<LeadDetailState> emit,
  ) async {
    final cur = state;
    if (cur is! LeadDetailLoaded) return;
    emit(
      LeadDetailChangingStatus(
        lead: cur.lead,
        history: cur.history,
        statuses: cur.statuses,
      ),
    );
    final result = await changeStatus(
      leadId: cur.lead.id,
      statusId: event.statusId,
    );
    await result.fold((f) async {
      // The change may have persisted server-side even though the response
      // surfaced an error (e.g. backend saves the status, then fails while
      // serializing the reply). Re-fetch and confirm the real state before
      // alarming the user.
      final check = await getDetail(cur.lead.id);
      await check.fold(
        (_) async => emit(
          LeadDetailLoaded(
            lead: cur.lead,
            history: cur.history,
            statuses: cur.statuses,
            statusError: f.message,
          ),
        ),
        (lead) async {
          if (lead.statusId == event.statusId) {
            // Actually succeeded — no error, just refresh history.
            await _emitWithHistory(emit, lead, cur);
          } else {
            emit(
              LeadDetailLoaded(
                lead: lead,
                history: cur.history,
                statuses: cur.statuses,
                statusError: f.message,
              ),
            );
          }
        },
      );
    }, (updated) async => _emitWithHistory(emit, updated, cur));
  }

  /// Emits a loaded state for [lead], refreshing history so the new transition
  /// shows up immediately; falls back to the previous history on failure.
  Future<void> _emitWithHistory(
    Emitter<LeadDetailState> emit,
    LeadEntity lead,
    LeadDetailLoaded cur,
  ) async {
    final histResult = await getHistory(lead.id);
    final history = histResult.fold((_) => cur.history, (h) => h);
    emit(
      LeadDetailLoaded(lead: lead, history: history, statuses: cur.statuses),
    );
  }
}
