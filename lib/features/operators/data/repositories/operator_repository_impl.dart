import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/operator_entity.dart';
import '../../domain/repositories/operator_repository.dart';
import '../datasources/operator_remote_data_source.dart';

class OperatorRepositoryImpl implements OperatorRepository {
  final OperatorRemoteDataSource remoteDataSource;
  OperatorRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<OperatorEntity>>> getOperators({int page = 1}) async {
    try {
      final result = await remoteDataSource.getOperators(page: page);
      return Right(result);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return const Left(ServerFailure('Operatorlarni yuklashda xatolik'));
    }
  }

  @override
  Future<Either<Failure, OperatorEntity>> createOperator({
    required String fullName,
    required String username,
    required String password,
    double commissionPercent = 10,
  }) async {
    try {
      final result = await remoteDataSource.createOperator(
        fullName: fullName,
        username: username,
        password: password,
        commissionPercent: commissionPercent,
      );
      return Right(result);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return const Left(ServerFailure('Operator yaratishda xatolik'));
    }
  }
}
