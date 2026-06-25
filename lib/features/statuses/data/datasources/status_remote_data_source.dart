import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../models/status_model.dart';

abstract class StatusRemoteDataSource {
  Future<List<StatusModel>> getStatuses({String? category});
  Future<StatusModel> createStatus({
    required String name,
    required String category,
    String color = '#6b7280',
    int order = 99,
    bool isDefault = false,
  });
  Future<StatusModel> updateStatus({
    required int id,
    String? name,
    String? color,
    int? order,
    bool? isDefault,
  });
  Future<void> deleteStatus(int id);
}

class StatusRemoteDataSourceImpl implements StatusRemoteDataSource {
  final ApiClient apiClient;
  StatusRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<StatusModel>> getStatuses({String? category}) async {
    try {
      final res = await apiClient.get(
        ApiConstants.statuses,
        queryParameters: category != null ? {'category': category} : null,
      );
      final data = res.data;
      final list = data is Map ? (data['results'] as List? ?? []) : (data as List? ?? []);
      return list.map((e) => StatusModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw dioFailure(e, 'Statuslarni yuklashda xatolik');
    }
  }

  @override
  Future<StatusModel> createStatus({
    required String name,
    required String category,
    String color = '#6b7280',
    int order = 99,
    bool isDefault = false,
  }) async {
    try {
      final res = await apiClient.post(ApiConstants.adminStatuses, data: {
        'name': name,
        'category': category,
        'color': color,
        'order': order,
        'is_default': isDefault,
      });
      return StatusModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioFailure(e, 'Status yaratishda xatolik');
    }
  }

  @override
  Future<StatusModel> updateStatus({
    required int id,
    String? name,
    String? color,
    int? order,
    bool? isDefault,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (color != null) data['color'] = color;
      if (order != null) data['order'] = order;
      if (isDefault != null) data['is_default'] = isDefault;
      final res = await apiClient.patch(ApiConstants.adminStatusDetail(id), data: data);
      return StatusModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioFailure(e, 'Status yangilashda xatolik');
    }
  }

  @override
  Future<void> deleteStatus(int id) async {
    try {
      await apiClient.delete(ApiConstants.adminStatusDetail(id));
    } on DioException catch (e) {
      throw dioFailure(e, 'Status o\'chirishda xatolik');
    }
  }
}
