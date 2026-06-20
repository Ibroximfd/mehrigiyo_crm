import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/operator_entity.dart';
import '../repositories/operator_repository.dart';

class GetOperatorsUseCase {
  final OperatorRepository repository;
  GetOperatorsUseCase(this.repository);

  Future<Either<Failure, List<OperatorEntity>>> call({int page = 1}) =>
      repository.getOperators(page: page);
}

class CreateOperatorUseCase {
  final OperatorRepository repository;
  CreateOperatorUseCase(this.repository);

  Future<Either<Failure, OperatorEntity>> call({
    required String fullName,
    required String username,
    required String password,
    double commissionPercent = 10,
  }) =>
      repository.createOperator(
        fullName: fullName,
        username: username,
        password: password,
        commissionPercent: commissionPercent,
      );
}
