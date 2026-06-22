import '../../domain/entities/statistics_entity.dart';

class LeadStatusCountModel extends LeadStatusCountEntity {
  const LeadStatusCountModel({required super.status, required super.count});

  factory LeadStatusCountModel.fromJson(Map<String, dynamic> json) =>
      LeadStatusCountModel(
        status: json['status']?.toString() ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

class LeadsStatsModel extends LeadsStatsEntity {
  const LeadsStatsModel({
    required super.total,
    required super.byStatus,
    required super.conversion,
  });

  factory LeadsStatsModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['by_status'] as List? ?? [];
    return LeadsStatsModel(
      total: (json['total'] as num?)?.toInt() ?? 0,
      byStatus: rawList
          .map((e) => LeadStatusCountModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      conversion: (json['conversion'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CommissionStatsModel extends CommissionStatsEntity {
  const CommissionStatsModel({
    required super.totalPaid,
    required super.totalPending,
    required super.totalTransferred,
    required super.totalCancelled,
    required super.countPaid,
    required super.countPending,
  });

  factory CommissionStatsModel.fromJson(Map<String, dynamic> json) =>
      CommissionStatsModel(
        totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
        totalPending: (json['total_pending'] as num?)?.toDouble() ?? 0.0,
        totalTransferred: (json['total_transferred'] as num?)?.toDouble() ?? 0.0,
        totalCancelled: (json['total_cancelled'] as num?)?.toDouble() ?? 0.0,
        countPaid: (json['count_paid'] as num?)?.toInt() ?? 0,
        countPending: (json['count_pending'] as num?)?.toInt() ?? 0,
      );
}

class SalesStatsModel extends SalesStatsEntity {
  const SalesStatsModel({required super.productsSold, required super.totalSales});

  factory SalesStatsModel.fromJson(Map<String, dynamic> json) => SalesStatsModel(
        productsSold: (json['products_sold'] as num?)?.toInt() ?? 0,
        totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
      );
}

class SellerStatisticsModel extends SellerStatisticsEntity {
  const SellerStatisticsModel({
    required super.commission,
    required super.sales,
    required super.leads,
  });

  factory SellerStatisticsModel.fromJson(Map<String, dynamic> json) =>
      SellerStatisticsModel(
        commission: CommissionStatsModel.fromJson(
            json['commission'] as Map<String, dynamic>? ?? {}),
        sales: SalesStatsModel.fromJson(
            json['sales'] as Map<String, dynamic>? ?? {}),
        leads: LeadsStatsModel.fromJson(
            json['leads'] as Map<String, dynamic>? ?? {}),
      );
}

class AdminCommissionModel extends AdminCommissionEntity {
  const AdminCommissionModel({
    required super.totalPaid,
    required super.totalPending,
    required super.totalTransferred,
  });

  factory AdminCommissionModel.fromJson(Map<String, dynamic> json) =>
      AdminCommissionModel(
        totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
        totalPending: (json['total_pending'] as num?)?.toDouble() ?? 0.0,
        totalTransferred: (json['total_transferred'] as num?)?.toDouble() ?? 0.0,
      );
}

class AdminStatisticsModel extends AdminStatisticsEntity {
  const AdminStatisticsModel({
    required super.operatorsCount,
    required super.totalSales,
    required super.commission,
    required super.leads,
  });

  factory AdminStatisticsModel.fromJson(Map<String, dynamic> json) =>
      AdminStatisticsModel(
        operatorsCount: (json['operators_count'] as num?)?.toInt() ?? 0,
        totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
        commission: AdminCommissionModel.fromJson(
            json['commission'] as Map<String, dynamic>? ?? {}),
        leads: LeadsStatsModel.fromJson(
            json['leads'] as Map<String, dynamic>? ?? {}),
      );
}

class OperatorRankingModel extends OperatorRankingEntity {
  const OperatorRankingModel({
    required super.operatorId,
    required super.fullName,
    required super.username,
    required super.totalSales,
    required super.totalCommissionPaid,
    required super.productsSold,
    required super.conversion,
  });

  factory OperatorRankingModel.fromJson(Map<String, dynamic> json) =>
      OperatorRankingModel(
        operatorId: (json['operator_id'] as num?)?.toInt() ?? 0,
        fullName: json['full_name']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
        totalCommissionPaid:
            (json['total_commission_paid'] as num?)?.toDouble() ?? 0.0,
        productsSold: (json['products_sold'] as num?)?.toInt() ?? 0,
        conversion: (json['conversion'] as num?)?.toDouble() ?? 0.0,
      );
}

class OperatorRankingListModel extends OperatorRankingListEntity {
  const OperatorRankingListModel({
    required super.count,
    required super.results,
    required super.hasMore,
  });

  factory OperatorRankingListModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['results'] as List? ?? [];
    final results = rawList
        .map((e) => OperatorRankingModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return OperatorRankingListModel(
      count: (json['count'] as num?)?.toInt() ?? 0,
      results: results,
      hasMore: json['next'] != null,
    );
  }
}
