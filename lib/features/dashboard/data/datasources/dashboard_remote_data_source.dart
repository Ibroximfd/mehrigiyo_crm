import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/failure.dart';
import '../models/dashboard_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardModel> getStats();
}

@LazySingleton(as: DashboardRemoteDataSource)
class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final ApiClient apiClient;

  DashboardRemoteDataSourceImpl(this.apiClient);

  @override
  Future<DashboardModel> getStats() async {
    try {
      final response = await apiClient.get(ApiConstants.supportStatistics);
      return DashboardModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerFailure(
        e.response?.data?['detail'] ??
            'Statistika ma\'lumotlarini olishda xatolik yuz berdi',
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw const ServerFailure(
        'Statistika ma\'lumotlarini olishda xatolik yuz berdi',
      );
    }
  }
}
