import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/status_entity.dart';
import '../../domain/repositories/status_repository.dart';
import '../datasources/status_remote_data_source.dart';

class StatusRepositoryImpl implements StatusRepository {
  final StatusRemoteDataSource remoteDataSource;
  StatusRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<StatusEntity>>> getStatuses({String? category}) async {
    try {
      return Right(await remoteDataSource.getStatuses(category: category));
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Statuslarni yuklashda xatolik'));
    }
  }

  @override
  Future<Either<Failure, StatusEntity>> createStatus({
    required String name,
    required String category,
    String color = '#6b7280',
    int order = 99,
    bool isDefault = false,
  }) async {
    try {
      return Right(await remoteDataSource.createStatus(
        name: name, category: category, color: color, order: order, isDefault: isDefault,
      ));
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Status yaratishda xatolik'));
    }
  }

  @override
  Future<Either<Failure, StatusEntity>> updateStatus({
    required int id,
    String? name,
    String? color,
    int? order,
    bool? isDefault,
  }) async {
    try {
      return Right(await remoteDataSource.updateStatus(
        id: id, name: name, color: color, order: order, isDefault: isDefault,
      ));
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Status yangilashda xatolik'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteStatus(int id) async {
    try {
      await remoteDataSource.deleteStatus(id);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Status o\'chirishda xatolik'));
    }
  }
}
