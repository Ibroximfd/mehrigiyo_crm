import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

class ApiConstants {
  static String get baseUrl {
    // Production web (deployed on my.imorganic.uz): use relative path
    // Debug web (localhost dev): use full URL
    if (kIsWeb && !kDebugMode) return '/api';
    return 'https://my.imorganic.uz/api';
  }

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
  static String adminOperatorDetail(int id) => '/operator/admin/operators/$id/';

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

  // Operator orders (seller)
  static const String operatorOrderCreate = '/operator/orders/create/';

  // Chat (seller)
  static const String chatCreateRoom = '/operator/chat/create-room/';
  static const String chatRooms = '/chat/rooms/';
  static String chatMessages(int roomId) => '/chat/rooms/$roomId/messages/';
  static const String chatSendMessage = '/chat/messages/';
  static String chatMarkAsRead(int roomId) => '/chat/rooms/$roomId/mark_as_read/';
  static const String chatUnreadTotal = '/chat/rooms/unread_total/';
  static String chatRecommend(int roomId) => '/operator/chat/rooms/$roomId/recommend/';
  static const String shopMedicines = '/shop/medicines/';

  // Statistics
  static const String myStatistics = '/operator/my-statistics/';
  static const String adminStatistics = '/operator/admin/statistics/';
  static const String adminOperatorsRanking = '/operator/admin/operators/ranking/';
  static String adminOperatorStats(int operatorId) =>
      '/operator/admin/operators/$operatorId/stats/';

  /// Normalizes a media URL coming from the backend so it loads on the deployed
  /// HTTPS site. The backend sometimes returns `http://` absolute URLs (when the
  /// reverse proxy doesn't forward the original scheme) or relative paths; both
  /// fail as `<audio>`/`<img>` sources on an HTTPS page (mixed content). We:
  ///   • upgrade `http://` → `https://` (kills mixed-content blocking),
  ///   • turn protocol-relative `//host/..` into `https://host/..`,
  ///   • resolve relative `/media/..` against the current page origin.
  static String resolveMediaUrl(String url) {
    final u = url.trim();
    if (u.isEmpty) return u;
    if (u.startsWith('https://')) return u;
    if (u.startsWith('http://')) return 'https://${u.substring(7)}';
    if (u.startsWith('//')) return 'https:$u';
    // Relative path → resolve against the page origin (same host that serves
    // the app, which is also where media lives in production).
    return Uri.base.resolve(u).toString();
  }
}
