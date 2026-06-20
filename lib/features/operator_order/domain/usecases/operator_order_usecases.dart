import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/operator_order_entity.dart';
import '../repositories/operator_order_repository.dart';

class CreateManualOrderUseCase {
  final OperatorOrderRepository repo;
  CreateManualOrderUseCase(this.repo);

  Future<Either<Failure, OperatorOrderEntity>> call({
    required String phone,
    required List<OrderItemInput> items,
    int? leadId,
    int? deliveryAddressId,
    String? customerNotes,
  }) =>
      repo.createManualOrder(
        phone: phone,
        items: items,
        leadId: leadId,
        deliveryAddressId: deliveryAddressId,
        customerNotes: customerNotes,
      );
}

class CreateOrderFromRecommendationUseCase {
  final OperatorOrderRepository repo;
  CreateOrderFromRecommendationUseCase(this.repo);

  Future<Either<Failure, OperatorOrderEntity>> call({
    required String phone,
    required int operatorRecommendationId,
    int? deliveryAddressId,
    String? customerNotes,
  }) =>
      repo.createOrderFromRecommendation(
        phone: phone,
        operatorRecommendationId: operatorRecommendationId,
        deliveryAddressId: deliveryAddressId,
        customerNotes: customerNotes,
      );
}
