import '../../domain/entities/statistics_entity.dart';

class LeadStatusCountModel extends LeadStatusCountEntity {
  const LeadStatusCountModel({
    required super.status,
    required super.count,
    super.statusId,
    super.category,
  });

  factory LeadStatusCountModel.fromJson(Map<String, dynamic> json) =>
      LeadStatusCountModel(
        // API may send `status_name`; older shape used `status`.
        status: json['status_name']?.toString() ??
            json['status']?.toString() ??
            '',
        count: (json['count'] as num?)?.toInt() ?? 0,
        statusId: (json['status_id'] as num?)?.toInt() ?? 0,
        category: json['category']?.toString() ?? '',
      );
}

class LeadsStatsModel extends LeadsStatsEntity {
  const LeadsStatsModel({
    required super.total,
    required super.byStatus,
    required super.conversion,
    super.postSaleLeads,
  });

  factory LeadsStatsModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['by_status'] as List? ?? [];
    return LeadsStatsModel(
      // API may send `total_leads`/`conversion_percent`; older shape was shorter.
      total: (json['total_leads'] as num?)?.toInt() ??
          (json['total'] as num?)?.toInt() ??
          0,
      byStatus: rawList
          .map((e) => LeadStatusCountModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      conversion: (json['conversion_percent'] as num?)?.toDouble() ??
          (json['conversion'] as num?)?.toDouble() ??
          0.0,
      postSaleLeads: (json['post_sale_leads'] as num?)?.toInt() ?? 0,
    );
  }
}

class OperatorInfoModel extends OperatorInfoEntity {
  const OperatorInfoModel({
    required super.id,
    required super.fullName,
    required super.username,
  });

  factory OperatorInfoModel.fromJson(Map<String, dynamic> json) =>
      OperatorInfoModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        fullName: json['full_name']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
      );
}

class CommissionStatsModel extends CommissionStatsEntity {
  const CommissionStatsModel({
    required super.earned,
    required super.transferred,
    required super.pendingPayout,
  });

  factory CommissionStatsModel.fromJson(Map<String, dynamic> json) =>
      CommissionStatsModel(
        // New API: earned / transferred / pending_payout.
        // Fall back to older keys (total_paid / total_transferred / total_pending).
        earned: (json['earned'] as num?)?.toDouble() ??
            (json['total_paid'] as num?)?.toDouble() ??
            0.0,
        transferred: (json['transferred'] as num?)?.toDouble() ??
            (json['total_transferred'] as num?)?.toDouble() ??
            0.0,
        pendingPayout: (json['pending_payout'] as num?)?.toDouble() ??
            (json['total_pending'] as num?)?.toDouble() ??
            0.0,
      );
}

class PipelineStageModel extends PipelineStageEntity {
  const PipelineStageModel({required super.count, required super.amount});

  factory PipelineStageModel.fromJson(Map<String, dynamic> json) =>
      PipelineStageModel(
        count: (json['count'] as num?)?.toInt() ?? 0,
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      );
}

class OrderPipelineModel extends OrderPipelineEntity {
  const OrderPipelineModel({
    required super.inProgress,
    required super.delivered,
    required super.cancelled,
    required super.totalOrders,
    required super.totalAmount,
  });

  factory OrderPipelineModel.fromJson(Map<String, dynamic> json) {
    PipelineStageModel stage(String key) => PipelineStageModel.fromJson(
        json[key] as Map<String, dynamic>? ?? const {});
    return OrderPipelineModel(
      inProgress: stage('in_progress'),
      delivered: stage('delivered'),
      cancelled: stage('cancelled'),
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
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
    super.orderPipeline,
    super.operator,
  });

  factory SellerStatisticsModel.fromJson(Map<String, dynamic> json) =>
      SellerStatisticsModel(
        commission: CommissionStatsModel.fromJson(
            json['commission'] as Map<String, dynamic>? ?? {}),
        sales: SalesStatsModel.fromJson(
            json['sales'] as Map<String, dynamic>? ?? {}),
        leads: LeadsStatsModel.fromJson(
            json['leads'] as Map<String, dynamic>? ?? {}),
        orderPipeline: json['order_pipeline'] is Map<String, dynamic>
            ? OrderPipelineModel.fromJson(
                json['order_pipeline'] as Map<String, dynamic>)
            : null,
        operator: json['operator'] is Map<String, dynamic>
            ? OperatorInfoModel.fromJson(json['operator'] as Map<String, dynamic>)
            : null,
      );
}

class FilialInfoModel extends FilialInfoEntity {
  const FilialInfoModel({required super.id, required super.name});

  factory FilialInfoModel.fromJson(Map<String, dynamic> json) => FilialInfoModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
      );
}

class AdminStatisticsModel extends AdminStatisticsEntity {
  const AdminStatisticsModel({
    required super.operatorsCount,
    required super.totalSales,
    required super.commission,
    required super.leads,
    super.productsSold,
    super.orderPipeline,
    super.filial,
  });

  factory AdminStatisticsModel.fromJson(Map<String, dynamic> json) {
    // Sales figures live under the `sales` object; fall back to top-level keys
    // for older API shapes.
    final sales = json['sales'] as Map<String, dynamic>? ?? const {};
    return AdminStatisticsModel(
      operatorsCount: (json['operators_count'] as num?)?.toInt() ?? 0,
      totalSales: (sales['total_sales'] as num?)?.toDouble() ??
          (json['total_sales'] as num?)?.toDouble() ??
          0.0,
      productsSold: (sales['products_sold'] as num?)?.toInt() ??
          (json['products_sold'] as num?)?.toInt() ??
          0,
      commission: CommissionStatsModel.fromJson(
          json['commission'] as Map<String, dynamic>? ?? {}),
      leads: LeadsStatsModel.fromJson(
          json['leads'] as Map<String, dynamic>? ?? {}),
      orderPipeline: json['order_pipeline'] is Map<String, dynamic>
          ? OrderPipelineModel.fromJson(
              json['order_pipeline'] as Map<String, dynamic>)
          : null,
      filial: json['filial'] is Map<String, dynamic>
          ? FilialInfoModel.fromJson(json['filial'] as Map<String, dynamic>)
          : null,
    );
  }
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
    super.ordersDelivered,
    super.ordersInProgress,
    super.totalLeads,
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
        ordersDelivered: (json['orders_delivered'] as num?)?.toInt() ?? 0,
        ordersInProgress: (json['orders_in_progress'] as num?)?.toInt() ?? 0,
        totalLeads: (json['total_leads'] as num?)?.toInt() ?? 0,
        conversion: (json['conversion_percent'] as num?)?.toDouble() ??
            (json['conversion'] as num?)?.toDouble() ??
            0.0,
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
