import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../models/operator_model.dart';

abstract class OperatorRemoteDataSource {
  Future<List<OperatorModel>> getOperators({int page = 1});
  Future<OperatorModel> createOperator({
    required String fullName,
    required String username,
    required String password,
    double commissionPercent = 10,
  });
}

class OperatorRemoteDataSourceImpl implements OperatorRemoteDataSource {
  final ApiClient apiClient;
  OperatorRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<OperatorModel>> getOperators({int page = 1}) async {
    try {
      final res = await apiClient.get(
        ApiConstants.adminOperatorsList,
        queryParameters: {'page': page},
      );
      final data = res.data;
      final results = data is Map ? (data['results'] as List? ?? []) : (data as List);
      return results.map((e) => OperatorModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw dioFailure(e, 'Operatorlarni yuklashda xatolik');
    }
  }

  @override
  Future<OperatorModel> createOperator({
    required String fullName,
    required String username,
    required String password,
    double commissionPercent = 10,
  }) async {
    try {
      final res = await apiClient.post(
        ApiConstants.adminOperatorsCreate,
        data: {
          'full_name': fullName,
          'username': username,
          'password': password,
          'commission_percent': commissionPercent,
        },
      );
      final data = res.data;
      final op = data is Map && data.containsKey('operator')
          ? data['operator'] as Map<String, dynamic>
          : data as Map<String, dynamic>;
      return OperatorModel.fromJson(op);
    } on DioException catch (e) {
      throw dioFailure(e, 'Operator yaratishda xatolik');
    }
  }
}
