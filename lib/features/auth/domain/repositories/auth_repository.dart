import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String username,
    required String password,
  });
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, bool>> checkAuthStatus();
  Future<Either<Failure, UserEntity>> getProfile();
}
