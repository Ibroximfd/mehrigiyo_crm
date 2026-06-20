import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/operator_order_entity.dart';
import '../../domain/usecases/operator_order_usecases.dart';

part 'operator_order_event.dart';
part 'operator_order_state.dart';

class OperatorOrderBloc extends Bloc<OperatorOrderEvent, OperatorOrderState> {
  final CreateManualOrderUseCase createManual;
  final CreateOrderFromRecommendationUseCase createFromRecommendation;

  OperatorOrderBloc({
    required this.createManual,
    required this.createFromRecommendation,
  }) : super(OperatorOrderInitial()) {
    on<OperatorOrderCreateManual>(_onManual);
    on<OperatorOrderCreateFromRecommendation>(_onFromRecommendation);
  }

  Future<void> _onManual(
    OperatorOrderCreateManual event,
    Emitter<OperatorOrderState> emit,
  ) async {
    emit(OperatorOrderCreating());
    final result = await createManual(
      phone: event.phone,
      items: event.items,
      leadId: event.leadId,
      deliveryAddressId: event.deliveryAddressId,
      customerNotes: event.customerNotes,
    );
    result.fold(
      (f) => emit(OperatorOrderError(f.message)),
      (order) => emit(OperatorOrderCreated(order)),
    );
  }

  Future<void> _onFromRecommendation(
    OperatorOrderCreateFromRecommendation event,
    Emitter<OperatorOrderState> emit,
  ) async {
    emit(OperatorOrderCreating());
    final result = await createFromRecommendation(
      phone: event.phone,
      operatorRecommendationId: event.operatorRecommendationId,
      deliveryAddressId: event.deliveryAddressId,
      customerNotes: event.customerNotes,
    );
    result.fold(
      (f) => emit(OperatorOrderError(f.message)),
      (order) => emit(OperatorOrderCreated(order)),
    );
  }
}
