import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../models/operator_order_model.dart';

abstract class OperatorOrderDataSource {
  Future<OperatorOrderModel> createManualOrder({
    required String phone,
    required List<Map<String, dynamic>> items,
    int? leadId,
    int? deliveryAddressId,
    String? customerNotes,
  });

  Future<OperatorOrderModel> createOrderFromRecommendation({
    required String phone,
    required int operatorRecommendationId,
    int? deliveryAddressId,
    String? customerNotes,
  });
}

class OperatorOrderDataSourceImpl implements OperatorOrderDataSource {
  final ApiClient apiClient;
  OperatorOrderDataSourceImpl(this.apiClient);

  @override
  Future<OperatorOrderModel> createManualOrder({
    required String phone,
    required List<Map<String, dynamic>> items,
    int? leadId,
    int? deliveryAddressId,
    String? customerNotes,
  }) async {
    try {
      final body = <String, dynamic>{
        'phone': phone,
        'items': items,
      };
      if (leadId != null) body['lead_id'] = leadId;
      if (deliveryAddressId != null) body['delivery_address_id'] = deliveryAddressId;
      if (customerNotes != null && customerNotes.isNotEmpty) {
        body['customer_notes'] = customerNotes;
      }
      final res = await apiClient.post(ApiConstants.operatorOrderCreate, data: body);
      return OperatorOrderModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<OperatorOrderModel> createOrderFromRecommendation({
    required String phone,
    required int operatorRecommendationId,
    int? deliveryAddressId,
    String? customerNotes,
  }) async {
    try {
      final body = <String, dynamic>{
        'phone': phone,
        'operator_recommendation_id': operatorRecommendationId,
      };
      if (deliveryAddressId != null) body['delivery_address_id'] = deliveryAddressId;
      if (customerNotes != null && customerNotes.isNotEmpty) {
        body['customer_notes'] = customerNotes;
      }
      final res = await apiClient.post(ApiConstants.operatorOrderCreate, data: body);
      return OperatorOrderModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Failure _mapError(DioException e) {
    if (e.response?.statusCode == 404) {
      return const ServerFailure('Bu raqam bilan mijoz ilovada ro\'yxatdan o\'tmagan');
    }
    if (e.response?.statusCode == 400) {
      final data = e.response?.data;
      if (data is Map) {
        final msgs = <String>[];
        data.forEach((key, value) {
          if (value is List) {
            msgs.addAll(value.map((v) => v.toString()));
          } else {
            msgs.add(value.toString());
          }
        });
        if (msgs.isNotEmpty) return ServerFailure(msgs.join('\n'));
      }
    }
    return dioFailure(e, 'Buyurtma yaratishda xatolik');
  }
}
