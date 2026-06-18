import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/consultation_entity.dart';
import '../../domain/repositories/consultation_repository.dart';
import '../datasources/consultation_remote_data_source.dart';

@LazySingleton(as: ConsultationRepository)
class ConsultationRepositoryImpl implements ConsultationRepository {
  final ConsultationRemoteDataSource remoteDataSource;

  ConsultationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ConsultationEntity>>> getConsultations({
    int? status,
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  }) async {
    // Retry up to 2 times on connection failures (network drop, DNS, etc.)
    for (var attempt = 0; attempt <= 2; attempt++) {
      try {
        final results = await remoteDataSource.getConsultations(
          status: status,
          searchQuery: searchQuery,
          limit: limit,
          offset: offset,
        );
        return Right(results);
      } on ConnectionFailure catch (e) {
        if (attempt == 2) return Left(e);
        await Future.delayed(const Duration(seconds: 1));
      } on Failure catch (e) {
        return Left(e);
      } catch (e) {
        return const Left(ServerFailure('Kutilmagan xatolik'));
      }
    }
    return const Left(ConnectionFailure('Ulanish amalga oshmadi'));
  }

  @override
  Future<Either<Failure, ConsultationEntity>> getConsultationDetail(
    String id,
  ) async {
    try {
      final result = await remoteDataSource.getConsultationDetail(id);
      return Right(result);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return const Left(ServerFailure('Kutilmagan xatolik'));
    }
  }

  @override
  Future<Either<Failure, ConsultationEntity>> changeStatus(String id) async {
    try {
      final result = await remoteDataSource.changeStatus(id);
      return Right(result);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return const Left(ServerFailure('Kutilmagan xatolik'));
    }
  }

  @override
  Future<Either<Failure, ConsultationEntity>> updateNote(
    String id,
    String note,
  ) async {
    try {
      final result = await remoteDataSource.updateNote(id, note);
      return Right(result);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return const Left(ServerFailure('Kutilmagan xatolik'));
    }
  }
}
