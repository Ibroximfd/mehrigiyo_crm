import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/statistics_entity.dart';

abstract class StatisticsRepository {
  Future<Either<Failure, SellerStatisticsEntity>> getMyStatistics({
    String period = 'all',
  });

  Future<Either<Failure, AdminStatisticsEntity>> getAdminStatistics({
    String period = 'all',
  });

  Future<Either<Failure, OperatorRankingListEntity>> getOperatorsRanking({
    String period = 'all',
    int page = 1,
  });

  Future<Either<Failure, SellerStatisticsEntity>> getOperatorStats({
    required int operatorId,
    String period = 'all',
  });
}
