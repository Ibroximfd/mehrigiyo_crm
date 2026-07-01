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
      final status = e.response?.statusCode;
      if (status == 401) {
        return const AuthFailure('Sessiya tugadi');
      }
      // 413 comes from nginx (not Django) as HTML → give a clear, specific msg.
      if (status == 413) {
        return const ServerFailure(
            'Fayl hajmi juda katta (serverda ruxsat berilgan hajmdan oshib ketdi)');
      }
      final data = e.response?.data;
      // Prefer a JSON error field from the backend.
      if (data is Map) {
        final detail = (data['detail'] ?? data['message'])?.toString();
        if (detail != null && detail.isNotEmpty) return ServerFailure(detail);
      }
      // Non-JSON body (e.g. nginx/proxy error page) → surface the status code so
      // the real cause is visible instead of a generic message.
      return ServerFailure(status != null ? '$fallback ($status)' : fallback);
  }
}
