import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/status_entity.dart';
import '../../domain/usecases/status_usecases.dart';

part 'statuses_event.dart';
part 'statuses_state.dart';

class StatusesBloc extends Bloc<StatusesEvent, StatusesState> {
  final GetStatusesUseCase getStatuses;
  final CreateStatusUseCase createStatus;
  final DeleteStatusUseCase deleteStatus;

  StatusesBloc({
    required this.getStatuses,
    required this.createStatus,
    required this.deleteStatus,
  }) : super(StatusesInitial()) {
    on<StatusesLoadRequested>(_onLoad);
    on<StatusCreateRequested>(_onCreate);
    on<StatusDeleteRequested>(_onDelete);
  }

  List<StatusEntity> get _currentList =>
      state is StatusesLoaded ? (state as StatusesLoaded).statuses :
      state is StatusMutating ? (state as StatusMutating).statuses :
      state is StatusMutateError ? (state as StatusMutateError).statuses : [];

  Future<void> _onLoad(StatusesLoadRequested event, Emitter<StatusesState> emit) async {
    emit(StatusesLoading());
    final result = await getStatuses(category: event.category);
    result.fold(
      (f) => emit(StatusesError(f.message)),
      (list) => emit(StatusesLoaded(list)),
    );
  }

  Future<void> _onCreate(StatusCreateRequested event, Emitter<StatusesState> emit) async {
    final prev = _currentList;
    emit(StatusMutating(prev));
    final result = await createStatus(
      name: event.name,
      category: event.category,
      color: event.color,
      order: event.order,
      isDefault: event.isDefault,
    );
    result.fold(
      (f) => emit(StatusMutateError(prev, f.message)),
      (s) => emit(StatusesLoaded([...prev, s]..sort((a, b) => a.order.compareTo(b.order)))),
    );
  }

  Future<void> _onDelete(StatusDeleteRequested event, Emitter<StatusesState> emit) async {
    final prev = _currentList;
    emit(StatusMutating(prev));
    final result = await deleteStatus(event.id);
    result.fold(
      (f) => emit(StatusMutateError(prev, f.message)),
      (_) => emit(StatusesLoaded(prev.where((s) => s.id != event.id).toList())),
    );
  }
}
