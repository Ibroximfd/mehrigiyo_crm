import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failure.dart';
import '../entities/dashboard_entity.dart';
import '../repositories/dashboard_repository.dart';

@lazySingleton
class GetDashboardStatsUseCase {
  final DashboardRepository repository;

  GetDashboardStatsUseCase(this.repository);

  Future<Either<Failure, DashboardEntity>> call() async {
    return await repository.getDashboardStats();
  }
}
