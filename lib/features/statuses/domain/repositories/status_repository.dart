import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/status_entity.dart';

abstract class StatusRepository {
  Future<Either<Failure, List<StatusEntity>>> getStatuses({String? category});
  Future<Either<Failure, StatusEntity>> createStatus({
    required String name,
    required String category,
    String color = '#6b7280',
    int order = 99,
    bool isDefault = false,
  });
  Future<Either<Failure, StatusEntity>> updateStatus({
    required int id,
    String? name,
    String? color,
    int? order,
    bool? isDefault,
  });
  Future<Either<Failure, void>> deleteStatus(int id);
}
