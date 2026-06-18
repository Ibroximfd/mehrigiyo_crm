import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/failure.dart';
import '../models/consultation_model.dart';

abstract class ConsultationRemoteDataSource {
  Future<List<ConsultationModel>> getConsultations({
    int? status,
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  });
  Future<ConsultationModel> getConsultationDetail(String id);
  Future<ConsultationModel> changeStatus(String id);
  Future<ConsultationModel> updateNote(String id, String note);
}

@LazySingleton(as: ConsultationRemoteDataSource)
class ConsultationRemoteDataSourceImpl implements ConsultationRemoteDataSource {
  final ApiClient apiClient;

  ConsultationRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<ConsultationModel>> getConsultations({
    int? status,
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final params = <String, dynamic>{'limit': limit, 'offset': offset};
      if (status != null) params['status'] = status;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        params['search'] = searchQuery;
      }
      final response = await apiClient.get(
        ApiConstants.freeConsultations,
        queryParameters: params,
      );
      final results = response.data['results'] as List? ?? [];
      return results
          .map((e) => ConsultationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw dioFailure(e, 'Arizalarni yuklashda xatolik');
    } catch (e) {
      if (e is Failure) rethrow;
      throw const ServerFailure('Arizalarni yuklashda xatolik');
    }
  }

  @override
  Future<ConsultationModel> getConsultationDetail(String id) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.freeConsultations}$id/',
      );
      return ConsultationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioFailure(e, 'Arizani yuklashda xatolik');
    } catch (e) {
      if (e is Failure) rethrow;
      throw const ServerFailure('Arizani yuklashda xatolik');
    }
  }

  @override
  Future<ConsultationModel> changeStatus(String id) async {
    try {
      final response = await apiClient.post(
        '${ApiConstants.freeConsultations}$id/next-status/',
      );
      return ConsultationModel.fromJson(
        response.data['consultation'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw dioFailure(e, 'Statusni o\'zgartirishda xatolik');
    } catch (e) {
      if (e is Failure) rethrow;
      throw const ServerFailure('Statusni o\'zgartirishda xatolik');
    }
  }

  @override
  Future<ConsultationModel> updateNote(String id, String note) async {
    try {
      final response = await apiClient.put(
        '${ApiConstants.freeConsultations}$id/update-note/',
        data: {'operator_note': note},
      );
      final consultation =
          response.data['consultation'] as Map<String, dynamic>?;
      final updatedNote = consultation?['operator_note'] as String? ?? note;
      final detail = await getConsultationDetail(id);
      return ConsultationModel(
        id: detail.id,
        clientName: detail.clientName,
        phone: detail.phone,
        issueDescription: detail.issueDescription,
        status: detail.status,
        statusDisplay: detail.statusDisplay,
        createdAt: detail.createdAt,
        updatedAt: detail.updatedAt,
        operatorNote: updatedNote,
        operatorId: detail.operatorId,
        operatorName: detail.operatorName,
      );
    } on DioException catch (e) {
      throw dioFailure(e, 'Izohni saqlashda xatolik');
    } catch (e) {
      if (e is Failure) rethrow;
      throw const ServerFailure('Izohni saqlashda xatolik');
    }
  }
}
