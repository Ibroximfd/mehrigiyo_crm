import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SharedPreferences prefs;

  AuthRepositoryImpl({required this.remoteDataSource, required this.prefs});

  @override
  Future<Either<Failure, UserEntity>> login({
    required String username,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.login(
        username: username,
        password: password,
      );
      // Clear any previous account's data first so optional fields the new
      // user lacks can't leak in from the prior session (no state merge).
      await _clearUserPrefs();
      await _saveUserToPrefs(user);
      return Right(user);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return const Left(ServerFailure('Kutilmagan xatolik yuz berdi'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
    } finally {
      await _clearUserPrefs();
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> checkAuthStatus() async {
    try {
      final token = prefs.getString('auth_token');
      return Right(token != null && token.isNotEmpty);
    } catch (e) {
      return const Left(
        ServerFailure('Avtorizatsiya holatini tekshirishda xatolik'),
      );
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getProfile() async {
    try {
      final token = prefs.getString('auth_token') ?? '';
      if (token.isEmpty) return const Left(AuthFailure('Token topilmadi'));
      final user = UserModel.fromPrefs({
        'auth_token': token,
        'operator_id': prefs.getString('operator_id'),
        'operator_name': prefs.getString('operator_name'),
        'operator_phone': prefs.getString('operator_phone'),
        'operator_is_admin': prefs.getString('operator_is_admin'),
        'operator_filial_id': prefs.getString('operator_filial_id'),
        'operator_filial_name': prefs.getString('operator_filial_name'),
        'operator_commission': prefs.getString('operator_commission'),
        'operator_refresh': prefs.getString('operator_refresh'),
      });
      return Right(user);
    } catch (e) {
      return const Left(ServerFailure('Profilni yuklashda xatolik'));
    }
  }

  Future<void> _saveUserToPrefs(UserModel user) async {
    await Future.wait([
      prefs.setString('auth_token', user.token),
      prefs.setString('operator_id', user.id),
      prefs.setString('operator_name', user.name),
      if (user.phone != null) prefs.setString('operator_phone', user.phone!),
      prefs.setString('operator_is_admin', user.isAdmin.toString()),
      if (user.filialId != null)
        prefs.setString('operator_filial_id', user.filialId.toString()),
      if (user.filialName != null)
        prefs.setString('operator_filial_name', user.filialName!),
      if (user.commissionPercent != null)
        prefs.setString('operator_commission', user.commissionPercent!),
      if (user.refreshToken != null)
        prefs.setString('operator_refresh', user.refreshToken!),
    ]);
  }

  Future<void> _clearUserPrefs() async {
    await Future.wait([
      prefs.remove('auth_token'),
      prefs.remove('operator_id'),
      prefs.remove('operator_name'),
      prefs.remove('operator_phone'),
      prefs.remove('operator_is_admin'),
      prefs.remove('operator_filial_id'),
      prefs.remove('operator_filial_name'),
      prefs.remove('operator_commission'),
      prefs.remove('operator_refresh'),
    ]);
  }
}
