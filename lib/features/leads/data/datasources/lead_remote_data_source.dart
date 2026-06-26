import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../models/lead_model.dart';

abstract class LeadRemoteDataSource {
  Future<List<LeadModel>> getMyLeads({int? statusId, String? category, int page = 1});
  Future<LeadModel> createLead({
    required String fullName, required String phone,
    String source = 'manual', String? region, String? note, int? statusId,
  });
  Future<LeadModel> getLeadDetail(int id);
  Future<LeadModel> changeLeadStatus({required int leadId, required int statusId});
  Future<List<LeadStatusHistoryModel>> getLeadHistory(int id);
  Future<List<LeadModel>> getAdminLeads({int? statusId, int? assignedTo, String? source, int page = 1});
  Future<int> assignLeads({required List<int> leadIds, required int operatorId});
  Future<int> bulkCreateLeads(List<Map<String, dynamic>> leads);
}

class LeadRemoteDataSourceImpl implements LeadRemoteDataSource {
  final ApiClient apiClient;
  LeadRemoteDataSourceImpl(this.apiClient);

  List<LeadModel> _parseList(dynamic data) {
    final list = data is Map ? (data['results'] as List? ?? []) : (data as List? ?? []);
    return list.map((e) => LeadModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<LeadModel>> getMyLeads({int? statusId, String? category, int page = 1}) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (statusId != null) params['status'] = statusId;
      if (category != null) params['category'] = category;
      final res = await apiClient.get(ApiConstants.myLeads, queryParameters: params);
      return _parseList(res.data);
    } on DioException catch (e) {
      throw dioFailure(e, 'Leadlarni yuklashda xatolik');
    }
  }

  @override
  Future<LeadModel> createLead({
    required String fullName, required String phone,
    String source = 'manual', String? region, String? note, int? statusId,
  }) async {
    try {
      final data = <String, dynamic>{
        'full_name': fullName, 'phone': phone, 'source': source,
      };
      if (region != null && region.isNotEmpty) data['region'] = region;
      if (note != null && note.isNotEmpty) data['note'] = note;
      if (statusId != null) data['status_id'] = statusId;
      final res = await apiClient.post(ApiConstants.leadsCreate, data: data);
      return LeadModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioFailure(e, 'Lead yaratishda xatolik');
    }
  }

  @override
  Future<LeadModel> getLeadDetail(int id) async {
    try {
      final res = await apiClient.get(ApiConstants.leadDetail(id));
      return LeadModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioFailure(e, 'Lead ma\'lumotlarini yuklashda xatolik');
    }
  }

  @override
  Future<LeadModel> changeLeadStatus({required int leadId, required int statusId}) async {
    try {
      final res = await apiClient.patch(
        ApiConstants.leadChangeStatus(leadId),
        data: {'status_id': statusId},
      );
      // Reaching here means HTTP 2xx (Dio throws DioException otherwise), so the
      // change is ALREADY persisted on the server. From this point on we must
      // never throw a non-Dio error — the change-status endpoint returns a body
      // that isn't a full lead object (no top-level `id`), so LeadModel.fromJson
      // would throw a TypeError and wrongly surface as a failure.
      final parsed = _tryParseLead(res.data);
      if (parsed != null) return parsed;

      // Body wasn't a usable lead — fetch the fresh lead. If even that fails,
      // synthesise a minimal success: the move is persisted and the caller only
      // needs to know it succeeded (the optimistic UI state already has the data).
      try {
        return await getLeadDetail(leadId);
      } catch (_) {
        return LeadModel(
          id: leadId,
          fullName: '',
          phone: '',
          statusId: statusId,
          source: 'manual',
          createdAt: '',
          updatedAt: '',
        );
      }
    } on DioException catch (e) {
      throw dioFailure(e, 'Status o\'zgartirishda xatolik');
    }
  }

  /// Parses a lead from a response body without ever throwing. Returns null when
  /// the body isn't a full lead object (e.g. it lacks an `id`), so the caller
  /// can fall back. Guards against both wrong-type bodies and parse errors.
  LeadModel? _tryParseLead(dynamic data) {
    try {
      Map<String, dynamic>? map;
      if (data is Map<String, dynamic>) {
        map = data;
      } else if (data is String && data.trim().isNotEmpty) {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) map = decoded;
      }
      if (map != null && map['id'] != null) return LeadModel.fromJson(map);
    } catch (_) {
      // fall through — caller will fetch or synthesise
    }
    return null;
  }

  @override
  Future<List<LeadStatusHistoryModel>> getLeadHistory(int id) async {
    try {
      final res = await apiClient.get(ApiConstants.leadHistory(id));
      final list = res.data as List;
      return list.map((e) => LeadStatusHistoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw dioFailure(e, 'Tarixni yuklashda xatolik');
    }
  }

  @override
  Future<List<LeadModel>> getAdminLeads({int? statusId, int? assignedTo, String? source, int page = 1}) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (statusId != null) params['status'] = statusId;
      if (assignedTo != null) params['assigned_to'] = assignedTo;
      if (source != null) params['source'] = source;
      final res = await apiClient.get(ApiConstants.adminLeads, queryParameters: params);
      return _parseList(res.data);
    } on DioException catch (e) {
      throw dioFailure(e, 'Leadlarni yuklashda xatolik');
    }
  }

  @override
  Future<int> assignLeads({required List<int> leadIds, required int operatorId}) async {
    try {
      final res = await apiClient.post(ApiConstants.adminLeadsAssign, data: {
        'lead_ids': leadIds,
        'operator_id': operatorId,
      });
      return (res.data['assigned'] as int?) ?? leadIds.length;
    } on DioException catch (e) {
      throw dioFailure(e, 'Leadlarni biriktirishda xatolik');
    }
  }

  @override
  Future<int> bulkCreateLeads(List<Map<String, dynamic>> leads) async {
    try {
      final res = await apiClient.post(ApiConstants.adminLeadsBulkCreate, data: leads);
      return (res.data['created'] as int?) ?? leads.length;
    } on DioException catch (e) {
      throw dioFailure(e, 'Leadlarni yaratishda xatolik');
    }
  }
}
