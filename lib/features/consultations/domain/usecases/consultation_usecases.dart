import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failure.dart';
import '../entities/consultation_entity.dart';
import '../repositories/consultation_repository.dart';

class GetConsultationsParams extends Equatable {
  final int? status;
  final String? searchQuery;
  final int limit;
  final int offset;

  const GetConsultationsParams({
    this.status,
    this.searchQuery,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [status, searchQuery, limit, offset];
}

@lazySingleton
class GetConsultationsUseCase {
  final ConsultationRepository repository;
  GetConsultationsUseCase(this.repository);

  Future<Either<Failure, List<ConsultationEntity>>> call(
    GetConsultationsParams params,
  ) async {
    return await repository.getConsultations(
      status: params.status,
      searchQuery: params.searchQuery,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

@lazySingleton
class GetConsultationDetailUseCase {
  final ConsultationRepository repository;
  GetConsultationDetailUseCase(this.repository);

  Future<Either<Failure, ConsultationEntity>> call(String id) async {
    return await repository.getConsultationDetail(id);
  }
}

@lazySingleton
class ChangeStatusUseCase {
  final ConsultationRepository repository;
  ChangeStatusUseCase(this.repository);

  Future<Either<Failure, ConsultationEntity>> call(String id) async {
    return await repository.changeStatus(id);
  }
}

@lazySingleton
class UpdateNoteUseCase {
  final ConsultationRepository repository;
  UpdateNoteUseCase(this.repository);

  Future<Either<Failure, ConsultationEntity>> call(
    String id,
    String note,
  ) async {
    return await repository.updateNote(id, note);
  }
}
