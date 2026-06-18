import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/failure.dart';
import '../models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<List<OrderModel>> getOrders({String? status, String? search});
}

@LazySingleton(as: OrderRemoteDataSource)
class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final ApiClient apiClient;
  OrderRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<OrderModel>> getOrders({String? status, String? search}) async {
    try {
      final params = <String, dynamic>{};
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final response = await apiClient.get(
        ApiConstants.orders,
        queryParameters: params,
      );

      final orders = response.data['orders'] as List? ?? [];
      return orders
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerFailure(
        e.response?.data?['detail'] ?? 'Orderlarni yuklashda xatolik',
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw const ServerFailure('Orderlarni yuklashda xatolik');
    }
  }
}
