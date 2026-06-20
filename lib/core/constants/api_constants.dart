import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  static String get baseUrl => kIsWeb ? '/api' : 'https://my.imorganic.uz/api';

  // Support auth (existing)
  static const String supportLogin = '/support/operator/login/';
  static const String supportLogout = '/support/operator/logout/';
  static const String supportProfile = '/support/operator/current/';
  static const String supportStatistics = '/support/statistics/';

  // Support features (existing)
  static const String freeConsultations = '/support/free/';
  static const String orders = '/support/orders/';

  // ─── Operator Sales System ─────────────────────────────────────────────────
  static const String operatorLogin = '/operator/login/';

  // Operator management (admin only)
  static const String adminOperatorsList = '/operator/admin/operators/';
  static const String adminOperatorsCreate = '/operator/admin/operators/create/';

  // Statuses
  static const String statuses = '/operator/statuses/';
  static const String adminStatuses = '/operator/admin/statuses/';
  static String adminStatusDetail(int id) => '/operator/admin/statuses/$id/';

  // Leads (seller)
  static const String myLeads = '/operator/my-leads/';
  static const String leadsCreate = '/operator/leads/create/';
  static String leadDetail(int id) => '/operator/leads/$id/';
  static String leadChangeStatus(int id) => '/operator/leads/$id/status/';
  static String leadHistory(int id) => '/operator/leads/$id/history/';

  // Leads (admin)
  static const String adminLeads = '/operator/admin/leads/';
  static const String adminLeadsAssign = '/operator/admin/leads/assign/';
  static const String adminLeadsBulkCreate = '/operator/admin/leads/bulk-create/';

  static String resolveMediaUrl(String url) {
    if (url.isEmpty) return url;
    if (!kIsWeb) return url;
    const host = 'https://my.imorganic.uz';
    if (url.startsWith('$host/media/')) return url.substring(host.length);
    return url;
  }
}
