import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class ConnectionFailure extends Failure {
  const ConnectionFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

Failure dioFailure(DioException e, String fallback) {
  switch (e.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
      return const ConnectionFailure('Internet aloqasi yo\'q');
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return const ConnectionFailure('Server javob bermadi, qayta urining');
    case DioExceptionType.cancel:
      return const ConnectionFailure('So\'rov bekor qilindi');
    default:
      if (e.response?.statusCode == 401) {
        return const AuthFailure('Sessiya tugadi');
      }
      final data = e.response?.data;
      final msg = data is Map
          ? (data['detail'] ?? data['message'] ?? fallback).toString()
          : fallback;
      return ServerFailure(msg);
  }
}
