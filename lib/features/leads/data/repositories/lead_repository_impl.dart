import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/lead_entity.dart';
import '../../domain/repositories/lead_repository.dart';
import '../datasources/lead_remote_data_source.dart';

class LeadRepositoryImpl implements LeadRepository {
  final LeadRemoteDataSource remoteDataSource;
  LeadRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<LeadEntity>>> getMyLeads({
    List<int>? statusIds, String? category, int page = 1,
  }) async {
    try {
      return Right(await remoteDataSource.getMyLeads(statusIds: statusIds, category: category, page: page));
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Leadlarni yuklashda xatolik'));
    }
  }

  @override
  Future<Either<Failure, LeadEntity>> createLead({
    required String fullName, required String phone,
    String source = 'manual', String? region, String? note, int? statusId,
  }) async {
    try {
      return Right(await remoteDataSource.createLead(
        fullName: fullName, phone: phone, source: source,
        region: region, note: note, statusId: statusId,
      ));
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Lead yaratishda xatolik'));
    }
  }

  @override
  Future<Either<Failure, LeadEntity>> getLeadDetail(int id) async {
    try {
      return Right(await remoteDataSource.getLeadDetail(id));
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Lead ma\'lumotlarini yuklashda xatolik'));
    }
  }

  @override
  Future<Either<Failure, LeadEntity>> changeLeadStatus({
    required int leadId, required int statusId,
  }) async {
    try {
      return Right(await remoteDataSource.changeLeadStatus(leadId: leadId, statusId: statusId));
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Status o\'zgartirishda xatolik'));
    }
  }

  @override
  Future<Either<Failure, List<LeadStatusHistory>>> getLeadHistory(int id) async {
    try {
      return Right(await remoteDataSource.getLeadHistory(id));
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Tarixni yuklashda xatolik'));
    }
  }

  @override
  Future<Either<Failure, List<LeadEntity>>> getAdminLeads({
    int? statusId, int? assignedTo, String? source, bool unassigned = false, int page = 1,
  }) async {
    try {
      return Right(await remoteDataSource.getAdminLeads(
        statusId: statusId, assignedTo: assignedTo, source: source, unassigned: unassigned, page: page,
      ));
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Leadlarni yuklashda xatolik'));
    }
  }

  @override
  Future<Either<Failure, int>> assignLeads({
    required List<int> leadIds, required int operatorId,
  }) async {
    try {
      return Right(await remoteDataSource.assignLeads(leadIds: leadIds, operatorId: operatorId));
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Leadlarni biriktirishda xatolik'));
    }
  }

  @override
  Future<Either<Failure, int>> bulkCreateLeads(List<Map<String, dynamic>> leads) async {
    try {
      return Right(await remoteDataSource.bulkCreateLeads(leads));
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Leadlarni yaratishda xatolik'));
    }
  }
}
