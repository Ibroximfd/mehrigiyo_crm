import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import '../../domain/usecases/consultation_usecases.dart';
import '../../domain/entities/consultation_entity.dart';
import 'consultations_event.dart';
import 'consultations_state.dart';

const int _kPageSize = 20;

@injectable
class ConsultationsBloc extends Bloc<ConsultationsEvent, ConsultationsState> {
  final GetConsultationsUseCase _getConsultations;

  int _offset = 0;
  int? _activeStatus;
  String? _activeSearch;
  List<ConsultationEntity> _items = [];

  ConsultationsBloc({required GetConsultationsUseCase getConsultationsUseCase})
    : _getConsultations = getConsultationsUseCase,
      super(const ConsultationsInitial()) {
    // restartable: new filter/search cancels the previous in-flight handler
    on<LoadConsultations>(_onLoad, transformer: restartable());
    // droppable: silently ignore if load-more is already running
    on<LoadMoreConsultations>(_onLoadMore, transformer: droppable());
  }

  Future<void> _onLoad(
    LoadConsultations event,
    Emitter<ConsultationsState> emit,
  ) async {
    _offset = 0;
    _activeStatus = event.status;
    _activeSearch = event.searchQuery;

    emit(ConsultationsLoading(_items, isRefreshing: _items.isNotEmpty));

    final result = await _getConsultations(
      GetConsultationsParams(
        status: _activeStatus,
        searchQuery: _activeSearch,
        limit: _kPageSize,
        offset: 0,
      ),
    );

    if (emit.isDone) return; // handler was cancelled by restartable()

    result.fold(
      (failure) => emit(ConsultationsError(failure.message)),
      (list) {
        _items = list;
        _offset = list.length;
        emit(ConsultationsLoaded(
          consultations: _items,
          activeStatus: _activeStatus,
          activeSearch: _activeSearch,
          hasMore: list.length >= _kPageSize,
        ));
      },
    );
  }

  Future<void> _onLoadMore(
    LoadMoreConsultations event,
    Emitter<ConsultationsState> emit,
  ) async {
    final current = state;
    if (current is! ConsultationsLoaded || !current.hasMore) return;

    emit(current.copyWith(isLoadingMore: true));

    final result = await _getConsultations(
      GetConsultationsParams(
        status: _activeStatus,
        searchQuery: _activeSearch,
        limit: _kPageSize,
        offset: _offset,
      ),
    );

    result.fold(
      (failure) => emit(current.copyWith(isLoadingMore: false)),
      (newItems) {
        _items = [..._items, ...newItems];
        _offset = _items.length;
        emit(ConsultationsLoaded(
          consultations: _items,
          activeStatus: _activeStatus,
          activeSearch: _activeSearch,
          hasMore: newItems.length >= _kPageSize,
        ));
      },
    );
  }
}
