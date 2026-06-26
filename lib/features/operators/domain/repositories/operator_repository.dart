import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/operator_entity.dart';

abstract class OperatorRepository {
  Future<Either<Failure, List<OperatorEntity>>> getOperators({int page = 1});
  Future<Either<Failure, OperatorEntity>> createOperator({
    required String fullName,
    required String username,
    required String password,
    double commissionPercent = 10,
  });
  Future<Either<Failure, OperatorEntity>> updateOperator({
    required int id,
    String? fullName,
    String? username,
    String? password,
    String? commissionPercent,
  });
}
