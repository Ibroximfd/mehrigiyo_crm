import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/consultation_entity.dart';

abstract class ConsultationRepository {
  Future<Either<Failure, List<ConsultationEntity>>> getConsultations({
    int? status,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  });

  Future<Either<Failure, ConsultationEntity>> getConsultationDetail(String id);
  Future<Either<Failure, ConsultationEntity>> changeStatus(String id);
  Future<Either<Failure, ConsultationEntity>> updateNote(
    String id,
    String note,
  );
}
