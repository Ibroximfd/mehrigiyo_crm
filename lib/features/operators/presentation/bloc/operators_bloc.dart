import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/operator_entity.dart';
import '../../domain/usecases/operator_usecases.dart';

part 'operators_event.dart';
part 'operators_state.dart';

class OperatorsBloc extends Bloc<OperatorsEvent, OperatorsState> {
  final GetOperatorsUseCase getOperators;
  final CreateOperatorUseCase createOperator;
  final UpdateOperatorUseCase updateOperator;

  OperatorsBloc({
    required this.getOperators,
    required this.createOperator,
    required this.updateOperator,
  }) : super(OperatorsInitial()) {
    on<OperatorsLoadRequested>(_onLoad);
    on<OperatorsLoadMore>(_onLoadMore);
    on<OperatorCreateRequested>(_onCreate);
    on<OperatorUpdateRequested>(_onUpdate);
  }

  Future<void> _onLoad(
    OperatorsLoadRequested event,
    Emitter<OperatorsState> emit,
  ) async {
    emit(OperatorsLoading());
    final result = await getOperators(page: 1);
    result.fold(
      (failure) => emit(OperatorsError(failure.message)),
      (ops) => emit(OperatorsLoaded(operators: ops, page: 1, hasMore: ops.length >= 20)),
    );
  }

  Future<void> _onLoadMore(
    OperatorsLoadMore event,
    Emitter<OperatorsState> emit,
  ) async {
    final current = state;
    if (current is! OperatorsLoaded || !current.hasMore) return;
    final nextPage = current.page + 1;
    final result = await getOperators(page: nextPage);
    result.fold(
      (failure) => null,
      (ops) => emit(current.copyWith(
        operators: [...current.operators, ...ops],
        page: nextPage,
        hasMore: ops.length >= 20,
      )),
    );
  }

  Future<void> _onCreate(
    OperatorCreateRequested event,
    Emitter<OperatorsState> emit,
  ) async {
    final prev = state;
    emit(OperatorCreating());
    final result = await createOperator(
      fullName: event.fullName,
      username: event.username,
      password: event.password,
      commissionPercent: event.commissionPercent,
    );
    result.fold(
      (failure) => emit(OperatorCreateError(failure.message)),
      (op) {
        emit(OperatorCreated(op));
        // Restore list and prepend new operator
        if (prev is OperatorsLoaded) {
          emit(prev.copyWith(operators: [op, ...prev.operators]));
        } else {
          add(const OperatorsLoadRequested());
        }
      },
    );
  }

  Future<void> _onUpdate(
    OperatorUpdateRequested event,
    Emitter<OperatorsState> emit,
  ) async {
    final prev = state;
    emit(OperatorUpdating());
    final result = await updateOperator(
      id: event.id,
      fullName: event.fullName,
      username: event.username,
      password: event.password,
      commissionPercent: event.commissionPercent,
    );
    result.fold(
      (failure) => emit(OperatorUpdateError(failure.message)),
      (op) {
        emit(OperatorUpdated(op));
        // Replace the edited operator in the list, in place.
        if (prev is OperatorsLoaded) {
          emit(prev.copyWith(
            operators: prev.operators
                .map((o) => o.id == op.id ? op : o)
                .toList(),
          ));
        } else {
          add(const OperatorsLoadRequested());
        }
      },
    );
  }
}
