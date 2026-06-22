import 'package:equatable/equatable.dart';

class LeadStatusCountEntity extends Equatable {
  final String status;
  final int count;
  const LeadStatusCountEntity({required this.status, required this.count});
  @override
  List<Object?> get props => [status, count];
}

class LeadsStatsEntity extends Equatable {
  final int total;
  final List<LeadStatusCountEntity> byStatus;
  final double conversion;
  const LeadsStatsEntity({
    required this.total,
    required this.byStatus,
    required this.conversion,
  });
  @override
  List<Object?> get props => [total, byStatus, conversion];
}

class CommissionStatsEntity extends Equatable {
  final double totalPaid;
  final double totalPending;
  final double totalTransferred;
  final double totalCancelled;
  final int countPaid;
  final int countPending;
  const CommissionStatsEntity({
    required this.totalPaid,
    required this.totalPending,
    required this.totalTransferred,
    required this.totalCancelled,
    required this.countPaid,
    required this.countPending,
  });
  @override
  List<Object?> get props => [
        totalPaid,
        totalPending,
        totalTransferred,
        totalCancelled,
        countPaid,
        countPending,
      ];
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
  const SellerStatisticsEntity({
    required this.commission,
    required this.sales,
    required this.leads,
  });
  @override
  List<Object?> get props => [commission, sales, leads];
}

class AdminCommissionEntity extends Equatable {
  final double totalPaid;
  final double totalPending;
  final double totalTransferred;
  const AdminCommissionEntity({
    required this.totalPaid,
    required this.totalPending,
    required this.totalTransferred,
  });
  @override
  List<Object?> get props => [totalPaid, totalPending, totalTransferred];
}

class AdminStatisticsEntity extends Equatable {
  final int operatorsCount;
  final double totalSales;
  final AdminCommissionEntity commission;
  final LeadsStatsEntity leads;
  const AdminStatisticsEntity({
    required this.operatorsCount,
    required this.totalSales,
    required this.commission,
    required this.leads,
  });
  @override
  List<Object?> get props => [operatorsCount, totalSales, commission, leads];
}

class OperatorRankingEntity extends Equatable {
  final int operatorId;
  final String fullName;
  final String username;
  final double totalSales;
  final double totalCommissionPaid;
  final int productsSold;
  final double conversion;
  const OperatorRankingEntity({
    required this.operatorId,
    required this.fullName,
    required this.username,
    required this.totalSales,
    required this.totalCommissionPaid,
    required this.productsSold,
    required this.conversion,
  });
  @override
  List<Object?> get props => [
        operatorId,
        fullName,
        username,
        totalSales,
        totalCommissionPaid,
        productsSold,
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
