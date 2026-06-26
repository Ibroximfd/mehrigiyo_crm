import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/lead_entity.dart';
import '../repositories/lead_repository.dart';

class GetMyLeadsUseCase {
  final LeadRepository repo;
  GetMyLeadsUseCase(this.repo);

  Future<Either<Failure, List<LeadEntity>>> call({List<int>? statusIds, String? category, int page = 1}) =>
      repo.getMyLeads(statusIds: statusIds, category: category, page: page);
}

class CreateLeadUseCase {
  final LeadRepository repo;
  CreateLeadUseCase(this.repo);

  Future<Either<Failure, LeadEntity>> call({
    required String fullName,
    required String phone,
    String source = 'manual',
    String? region,
    String? note,
    int? statusId,
  }) =>
      repo.createLead(
        fullName: fullName, phone: phone, source: source,
        region: region, note: note, statusId: statusId,
      );
}

class GetLeadDetailUseCase {
  final LeadRepository repo;
  GetLeadDetailUseCase(this.repo);

  Future<Either<Failure, LeadEntity>> call(int id) => repo.getLeadDetail(id);
}

class ChangeLeadStatusUseCase {
  final LeadRepository repo;
  ChangeLeadStatusUseCase(this.repo);

  Future<Either<Failure, LeadEntity>> call({required int leadId, required int statusId}) =>
      repo.changeLeadStatus(leadId: leadId, statusId: statusId);
}

class GetLeadHistoryUseCase {
  final LeadRepository repo;
  GetLeadHistoryUseCase(this.repo);

  Future<Either<Failure, List<LeadStatusHistory>>> call(int id) => repo.getLeadHistory(id);
}

class GetAdminLeadsUseCase {
  final LeadRepository repo;
  GetAdminLeadsUseCase(this.repo);

  Future<Either<Failure, List<LeadEntity>>> call({
    int? statusId, int? assignedTo, String? source, bool unassigned = false, int page = 1,
  }) =>
      repo.getAdminLeads(statusId: statusId, assignedTo: assignedTo, source: source, unassigned: unassigned, page: page);
}

class AssignLeadsUseCase {
  final LeadRepository repo;
  AssignLeadsUseCase(this.repo);

  Future<Either<Failure, int>> call({required List<int> leadIds, required int operatorId}) =>
      repo.assignLeads(leadIds: leadIds, operatorId: operatorId);
}

class BulkCreateLeadsUseCase {
  final LeadRepository repo;
  BulkCreateLeadsUseCase(this.repo);

  Future<Either<Failure, int>> call(List<Map<String, dynamic>> leads) =>
      repo.bulkCreateLeads(leads);
}
