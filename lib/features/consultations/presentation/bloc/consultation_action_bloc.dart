import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/usecases/consultation_usecases.dart';
import 'consultation_action_event.dart';
import 'consultation_action_state.dart';

@injectable
class ConsultationActionBloc
    extends Bloc<ConsultationActionEvent, ConsultationActionState> {
  final ChangeStatusUseCase changeStatusUseCase;
  final UpdateNoteUseCase updateNoteUseCase;

  ConsultationActionBloc({
    required this.changeStatusUseCase,
    required this.updateNoteUseCase,
  }) : super(ConsultationActionInitial()) {
    on<ChangeConsultationStatusEvent>(_onChangeStatus);
    on<UpdateConsultationNoteEvent>(_onUpdateNote);
  }

  Future<void> _onChangeStatus(
    ChangeConsultationStatusEvent event,
    Emitter<ConsultationActionState> emit,
  ) async {
    emit(ConsultationActionLoading());
    final result = await changeStatusUseCase(event.id);
    result.fold(
      (failure) => emit(ConsultationActionError(failure.message)),
      (updated) => emit(
        ConsultationActionSuccess(
          updated: updated,
          message: 'Status o\'zgardi: ${updated.statusDisplay}',
        ),
      ),
    );
  }

  Future<void> _onUpdateNote(
    UpdateConsultationNoteEvent event,
    Emitter<ConsultationActionState> emit,
  ) async {
    emit(ConsultationActionLoading());
    final result = await updateNoteUseCase(event.id, event.note);
    result.fold(
      (failure) => emit(ConsultationActionError(failure.message)),
      (updated) => emit(
        ConsultationActionSuccess(
          updated: updated,
          message: 'Izoh muvaffaqiyatli saqlandi',
        ),
      ),
    );
  }
}
