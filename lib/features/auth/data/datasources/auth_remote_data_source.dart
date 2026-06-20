import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../../../../core/error/failure.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String username, required String password});
  Future<UserModel> getProfile();
  Future<void> logout();
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await apiClient.post(
        ApiConstants.operatorLogin,
        data: {'username': username, 'password': password},
      );
      return UserModel.fromOperatorLoginJson(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError || e.response == null) {
        throw const AuthFailure(
          'Tarmoq xatosi. Internet yoki server bilan bog\'lanishni tekshiring.',
        );
      }
      throw AuthFailure(_extractError(e.response?.data));
    } catch (e) {
      if (e is Failure) rethrow;
      throw const ServerFailure('Server xatosi yuz berdi');
    }
  }

  String _extractError(dynamic data) {
    if (data is Map) {
      for (final key in const [
        'message', 'detail', 'error', 'non_field_errors', 'username', 'password',
      ]) {
        final value = data[key];
        if (value is String && value.isNotEmpty) return value;
        if (value is List && value.isNotEmpty) return value.first.toString();
      }
      if (data.isNotEmpty) return data.toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return 'Login yoki parol xato';
  }

  @override
  Future<UserModel> getProfile() async {
    throw const ServerFailure('Profile caching ishlatiladi');
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.post(ApiConstants.supportLogout);
    } catch (_) {}
  }
}
