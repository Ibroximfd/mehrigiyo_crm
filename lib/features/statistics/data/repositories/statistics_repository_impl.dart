import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/statistics_entity.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../datasources/statistics_remote_data_source.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  final StatisticsRemoteDataSource _ds;
  const StatisticsRepositoryImpl(this._ds);

  @override
  Future<Either<Failure, SellerStatisticsEntity>> getMyStatistics({
    String period = 'all',
  }) async {
    try {
      final result = await _ds.getMyStatistics(period: period);
      return Right(result);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AdminStatisticsEntity>> getAdminStatistics({
    String period = 'all',
  }) async {
    try {
      final result = await _ds.getAdminStatistics(period: period);
      return Right(result);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OperatorRankingListEntity>> getOperatorsRanking({
    String period = 'all',
    int page = 1,
  }) async {
    try {
      final result = await _ds.getOperatorsRanking(period: period, page: page);
      return Right(result);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SellerStatisticsEntity>> getOperatorStats({
    required int operatorId,
    String period = 'all',
  }) async {
    try {
      final result = await _ds.getOperatorStats(operatorId: operatorId, period: period);
      return Right(result);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
