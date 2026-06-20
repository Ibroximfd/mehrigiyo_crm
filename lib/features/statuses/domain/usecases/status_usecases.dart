import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/status_entity.dart';
import '../repositories/status_repository.dart';

class GetStatusesUseCase {
  final StatusRepository repository;
  GetStatusesUseCase(this.repository);

  Future<Either<Failure, List<StatusEntity>>> call({String? category}) =>
      repository.getStatuses(category: category);
}

class CreateStatusUseCase {
  final StatusRepository repository;
  CreateStatusUseCase(this.repository);

  Future<Either<Failure, StatusEntity>> call({
    required String name,
    required String category,
    String color = '#6b7280',
    int order = 99,
    bool isDefault = false,
  }) =>
      repository.createStatus(
        name: name,
        category: category,
        color: color,
        order: order,
        isDefault: isDefault,
      );
}

class UpdateStatusUseCase {
  final StatusRepository repository;
  UpdateStatusUseCase(this.repository);

  Future<Either<Failure, StatusEntity>> call({
    required int id,
    String? name,
    String? color,
    int? order,
    bool? isDefault,
  }) =>
      repository.updateStatus(
        id: id,
        name: name,
        color: color,
        order: order,
        isDefault: isDefault,
      );
}

class DeleteStatusUseCase {
  final StatusRepository repository;
  DeleteStatusUseCase(this.repository);

  Future<Either<Failure, void>> call(int id) => repository.deleteStatus(id);
}
