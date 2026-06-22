import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../models/statistics_model.dart';

abstract class StatisticsRemoteDataSource {
  Future<SellerStatisticsModel> getMyStatistics({String period = 'all'});
  Future<AdminStatisticsModel> getAdminStatistics({String period = 'all'});
  Future<OperatorRankingListModel> getOperatorsRanking({
    String period = 'all',
    int page = 1,
  });
  Future<SellerStatisticsModel> getOperatorStats({
    required int operatorId,
    String period = 'all',
  });
}

class StatisticsRemoteDataSourceImpl implements StatisticsRemoteDataSource {
  final ApiClient _api;
  const StatisticsRemoteDataSourceImpl(this._api);

  @override
  Future<SellerStatisticsModel> getMyStatistics({String period = 'all'}) async {
    try {
      final res = await _api.get(
        ApiConstants.myStatistics,
        queryParameters: {'period': period},
      );
      return SellerStatisticsModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioFailure(e, 'Statistikani yuklashda xatolik');
    }
  }

  @override
  Future<AdminStatisticsModel> getAdminStatistics({String period = 'all'}) async {
    try {
      final res = await _api.get(
        ApiConstants.adminStatistics,
        queryParameters: {'period': period},
      );
      return AdminStatisticsModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioFailure(e, 'Admin statistikasini yuklashda xatolik');
    }
  }

  @override
  Future<OperatorRankingListModel> getOperatorsRanking({
    String period = 'all',
    int page = 1,
  }) async {
    try {
      final res = await _api.get(
        ApiConstants.adminOperatorsRanking,
        queryParameters: {'period': period, 'page': page},
      );
      final data = res.data;
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        return OperatorRankingListModel.fromJson(data);
      }
      return OperatorRankingListModel.fromJson({
        'count': (data as List).length,
        'results': data,
        'next': null,
      });
    } on DioException catch (e) {
      throw dioFailure(e, 'Reyting yuklashda xatolik');
    }
  }

  @override
  Future<SellerStatisticsModel> getOperatorStats({
    required int operatorId,
    String period = 'all',
  }) async {
    try {
      final res = await _api.get(
        ApiConstants.adminOperatorStats(operatorId),
        queryParameters: {'period': period},
      );
      return SellerStatisticsModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioFailure(e, 'Operator statistikasini yuklashda xatolik');
    }
  }
}
