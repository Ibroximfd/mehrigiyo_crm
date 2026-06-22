import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/statistics_entity.dart';
import '../repositories/statistics_repository.dart';

class GetMyStatisticsUseCase {
  final StatisticsRepository _repo;
  const GetMyStatisticsUseCase(this._repo);

  Future<Either<Failure, SellerStatisticsEntity>> call({String period = 'all'}) =>
      _repo.getMyStatistics(period: period);
}

class GetAdminStatisticsUseCase {
  final StatisticsRepository _repo;
  const GetAdminStatisticsUseCase(this._repo);

  Future<Either<Failure, AdminStatisticsEntity>> call({String period = 'all'}) =>
      _repo.getAdminStatistics(period: period);
}

class GetOperatorsRankingUseCase {
  final StatisticsRepository _repo;
  const GetOperatorsRankingUseCase(this._repo);

  Future<Either<Failure, OperatorRankingListEntity>> call({
    String period = 'all',
    int page = 1,
  }) =>
      _repo.getOperatorsRanking(period: period, page: page);
}

class GetOperatorStatsUseCase {
  final StatisticsRepository _repo;
  const GetOperatorStatsUseCase(this._repo);

  Future<Either<Failure, SellerStatisticsEntity>> call({
    required int operatorId,
    String period = 'all',
  }) =>
      _repo.getOperatorStats(operatorId: operatorId, period: period);
}
