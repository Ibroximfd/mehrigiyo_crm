import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';
import '../router/app_router.dart';
import '../router/route_names.dart';

@injectable
class DioInterceptor extends Interceptor {
  final SharedPreferences _prefs;

  DioInterceptor(this._prefs);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Always read the token fresh from storage. Caching it in memory caused a
    // stale token to be sent after account switches (operator → admin), which
    // the backend rejected with "You don't have permission".
    final token = _prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      options.headers.remove('Authorization');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await _prefs.remove('auth_token');
      appRouter.go(RouteNames.login);
    }
    handler.next(err);
  }
}
