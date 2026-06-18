import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';
import '../router/app_router.dart';
import '../router/route_names.dart';

@injectable
class DioInterceptor extends Interceptor {
  final SharedPreferences _prefs;

  // Memory cache — avoids repeated SharedPreferences reads per request
  String? _cachedToken;

  DioInterceptor(this._prefs);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _cachedToken ??= _prefs.getString('auth_token');
    final token = _cachedToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      _cachedToken = null;
      await _prefs.remove('auth_token');
      appRouter.go(RouteNames.login);
    }
    handler.next(err);
  }

  // Called by AuthBloc on login to sync the cache immediately
  void setToken(String token) => _cachedToken = token;

  // Called by AuthBloc on logout to clear cache immediately
  void clearToken() => _cachedToken = null;
}
