import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/lead_entity.dart';

abstract class LeadRepository {
  // Seller
  Future<Either<Failure, List<LeadEntity>>> getMyLeads({int? statusId, String? category, int page = 1});
  Future<Either<Failure, LeadEntity>> createLead({
    required String fullName,
    required String phone,
    String source = 'manual',
    String? region,
    String? note,
    int? statusId,
  });
  Future<Either<Failure, LeadEntity>> getLeadDetail(int id);
  Future<Either<Failure, LeadEntity>> changeLeadStatus({required int leadId, required int statusId});
  Future<Either<Failure, List<LeadStatusHistory>>> getLeadHistory(int id);

  // Admin
  Future<Either<Failure, List<LeadEntity>>> getAdminLeads({
    int? statusId,
    int? assignedTo,
    String? source,
    int page = 1,
  });
  Future<Either<Failure, int>> assignLeads({
    required List<int> leadIds,
    required int operatorId,
  });
}
