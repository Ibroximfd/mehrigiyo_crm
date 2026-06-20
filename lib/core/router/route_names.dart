abstract final class RouteNames {
  // Existing
  static const login = '/login';
  static const dashboard = '/';
  static const consultations = '/consultations';

  // Operator Admin panel
  static const adminRoot = '/op/admin';
  static const adminOperators = '/op/admin/operators';
  static const adminLeads = '/op/admin/leads';
  static const adminStatuses = '/op/admin/statuses';
  static const adminConsultations = '/op/admin/consultations';

  // Operator Seller panel
  static const sellerRoot = '/op/seller';
  static const sellerKanban = '/op/seller/kanban';
  static const sellerLeads = '/op/seller/leads';
  static const sellerConsultations = '/op/seller/consultations';
  static const _sellerLeadDetailBase = '/op/seller/leads';
  static String sellerLeadDetail(int id) => '$_sellerLeadDetailBase/$id';
  static const sellerLeadDetailParam = '/op/seller/leads/:id';
}
