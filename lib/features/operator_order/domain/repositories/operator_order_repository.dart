import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/operator_order_entity.dart';

abstract class OperatorOrderRepository {
  /// Method 1: manual — items ro'yxati bilan
  Future<Either<Failure, OperatorOrderEntity>> createManualOrder({
    required String phone,
    required List<OrderItemInput> items,
    int? leadId,
    int? deliveryAddressId,
    String? customerNotes,
  });

  /// Method 2: chatdagi tavsiyadan avtomatik
  Future<Either<Failure, OperatorOrderEntity>> createOrderFromRecommendation({
    required String phone,
    required int operatorRecommendationId,
    int? deliveryAddressId,
    String? customerNotes,
  });
}
