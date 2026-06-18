import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  static String get baseUrl => kIsWeb ? '/api' : 'https://my.imorganic.uz/api';

  // Auth
  static const String supportLogin = '/support/operator/login/';
  static const String supportLogout = '/support/operator/logout/';
  static const String supportProfile = '/support/operator/current/';
  static const String supportStatistics = '/support/statistics/';

  // Consultations (arizalar)
  static const String freeConsultations = '/support/free/';

  // Orders
  static const String orders = '/support/orders/';

  static String resolveMediaUrl(String url) {
    if (url.isEmpty) return url;
    if (!kIsWeb) return url;
    const host = 'https://my.imorganic.uz';
    if (url.startsWith('$host/media/')) return url.substring(host.length);
    return url;
  }
}
