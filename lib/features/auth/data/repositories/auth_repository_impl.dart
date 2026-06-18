import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

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
        phone: username,
        password: password,
      );
      await prefs.setString('auth_token', user.token);
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
      await prefs.remove('auth_token');
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
      final user = await remoteDataSource.getProfile();
      final token = prefs.getString('auth_token') ?? '';
      return Right(
        UserEntity(
          id: user.id,
          name: user.name,
          token: token,
          phone: user.phone,
          role: user.role,
        ),
      );
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return const Left(ServerFailure('Profilni yuklashda xatolik'));
    }
  }
}
