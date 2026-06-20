import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/operator_order_entity.dart';
import '../../domain/repositories/operator_order_repository.dart';
import '../datasources/operator_order_data_source.dart';

class OperatorOrderRepositoryImpl implements OperatorOrderRepository {
  final OperatorOrderDataSource dataSource;
  OperatorOrderRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, OperatorOrderEntity>> createManualOrder({
    required String phone,
    required List<OrderItemInput> items,
    int? leadId,
    int? deliveryAddressId,
    String? customerNotes,
  }) async {
    try {
      final result = await dataSource.createManualOrder(
        phone: phone,
        items: items.map((i) => i.toJson()).toList(),
        leadId: leadId,
        deliveryAddressId: deliveryAddressId,
        customerNotes: customerNotes,
      );
      return Right(result);
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Buyurtma yaratishda xatolik'));
    }
  }

  @override
  Future<Either<Failure, OperatorOrderEntity>> createOrderFromRecommendation({
    required String phone,
    required int operatorRecommendationId,
    int? deliveryAddressId,
    String? customerNotes,
  }) async {
    try {
      final result = await dataSource.createOrderFromRecommendation(
        phone: phone,
        operatorRecommendationId: operatorRecommendationId,
        deliveryAddressId: deliveryAddressId,
        customerNotes: customerNotes,
      );
      return Right(result);
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Buyurtma yaratishda xatolik'));
    }
  }
}
