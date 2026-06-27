import 'package:equatable/equatable.dart';

class LeadStatusCountEntity extends Equatable {
  final String status;
  final int count;
  final int statusId;
  final String category;
  const LeadStatusCountEntity({
    required this.status,
    required this.count,
    this.statusId = 0,
    this.category = '',
  });
  @override
  List<Object?> get props => [status, count, statusId, category];
}

class LeadsStatsEntity extends Equatable {
  final int total;
  final List<LeadStatusCountEntity> byStatus;
  final double conversion;
  final int postSaleLeads;
  const LeadsStatsEntity({
    required this.total,
    required this.byStatus,
    required this.conversion,
    this.postSaleLeads = 0,
  });
  @override
  List<Object?> get props => [total, byStatus, conversion, postSaleLeads];
}

class OperatorInfoEntity extends Equatable {
  final int id;
  final String fullName;
  final String username;
  const OperatorInfoEntity({
    required this.id,
    required this.fullName,
    required this.username,
  });
  @override
  List<Object?> get props => [id, fullName, username];
}

class CommissionStatsEntity extends Equatable {
  /// Jami topgan komissiya (hisoblangan + o'tkazilgan).
  final double earned;

  /// Allaqachon to'lab berilgan qism.
  final double transferred;

  /// Topgan, lekin hali olinmagan (to'lov kutilmoqda).
  final double pendingPayout;

  const CommissionStatsEntity({
    required this.earned,
    required this.transferred,
    required this.pendingPayout,
  });
  @override
  List<Object?> get props => [earned, transferred, pendingPayout];
}

/// One stage of the order pipeline — soni (count) va summasi (amount).
class PipelineStageEntity extends Equatable {
  final int count;
  final double amount;
  const PipelineStageEntity({required this.count, required this.amount});
  @override
  List<Object?> get props => [count, amount];
}

/// Buyurtma bosqichlari (operator yaratgan + tavsiyasi bo'yicha sotilganlar).
class OrderPipelineEntity extends Equatable {
  final PipelineStageEntity inProgress;
  final PipelineStageEntity delivered;
  final PipelineStageEntity cancelled;
  final int totalOrders;
  final double totalAmount;
  const OrderPipelineEntity({
    required this.inProgress,
    required this.delivered,
    required this.cancelled,
    required this.totalOrders,
    required this.totalAmount,
  });
  @override
  List<Object?> get props =>
      [inProgress, delivered, cancelled, totalOrders, totalAmount];
}

class SalesStatsEntity extends Equatable {
  final int productsSold;
  final double totalSales;
  const SalesStatsEntity({required this.productsSold, required this.totalSales});
  @override
  List<Object?> get props => [productsSold, totalSales];
}

class SellerStatisticsEntity extends Equatable {
  final CommissionStatsEntity commission;
  final SalesStatsEntity sales;
  final LeadsStatsEntity leads;
  final OrderPipelineEntity? orderPipeline;
  final OperatorInfoEntity? operator;
  const SellerStatisticsEntity({
    required this.commission,
    required this.sales,
    required this.leads,
    this.orderPipeline,
    this.operator,
  });
  @override
  List<Object?> get props =>
      [commission, sales, leads, orderPipeline, operator];
}

class FilialInfoEntity extends Equatable {
  final int id;
  final String name;
  const FilialInfoEntity({required this.id, required this.name});
  @override
  List<Object?> get props => [id, name];
}

class AdminStatisticsEntity extends Equatable {
  final int operatorsCount;
  final double totalSales;
  final int productsSold;
  final CommissionStatsEntity commission;
  final LeadsStatsEntity leads;
  final OrderPipelineEntity? orderPipeline;
  final FilialInfoEntity? filial;
  const AdminStatisticsEntity({
    required this.operatorsCount,
    required this.totalSales,
    required this.commission,
    required this.leads,
    this.productsSold = 0,
    this.orderPipeline,
    this.filial,
  });
  @override
  List<Object?> get props => [
        operatorsCount,
        totalSales,
        productsSold,
        commission,
        leads,
        orderPipeline,
        filial,
      ];
}

class OperatorRankingEntity extends Equatable {
  final int operatorId;
  final String fullName;
  final String username;
  final double totalSales;
  final double totalCommissionPaid;
  final int productsSold;
  final int ordersDelivered;
  final int ordersInProgress;
  final int totalLeads;
  final double conversion;
  const OperatorRankingEntity({
    required this.operatorId,
    required this.fullName,
    required this.username,
    required this.totalSales,
    required this.totalCommissionPaid,
    required this.productsSold,
    required this.conversion,
    this.ordersDelivered = 0,
    this.ordersInProgress = 0,
    this.totalLeads = 0,
  });
  @override
  List<Object?> get props => [
        operatorId,
        fullName,
        username,
        totalSales,
        totalCommissionPaid,
        productsSold,
        ordersDelivered,
        ordersInProgress,
        totalLeads,
        conversion,
      ];
}

class OperatorRankingListEntity extends Equatable {
  final int count;
  final List<OperatorRankingEntity> results;
  final bool hasMore;
  const OperatorRankingListEntity({
    required this.count,
    required this.results,
    required this.hasMore,
  });
  @override
  List<Object?> get props => [count, results, hasMore];
}
