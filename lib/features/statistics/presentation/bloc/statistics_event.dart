part of 'statistics_bloc.dart';

// ─── Seller Events ─────────────────────────────────────────────────────────────
sealed class SellerStatisticsEvent extends Equatable {
  const SellerStatisticsEvent();
  @override
  List<Object?> get props => [];
}

class SellerStatisticsLoadRequested extends SellerStatisticsEvent {
  const SellerStatisticsLoadRequested();
}

class SellerStatisticsPeriodChanged extends SellerStatisticsEvent {
  final String period;
  const SellerStatisticsPeriodChanged(this.period);
  @override
  List<Object?> get props => [period];
}

// ─── Admin Events ──────────────────────────────────────────────────────────────
sealed class AdminStatisticsEvent extends Equatable {
  const AdminStatisticsEvent();
  @override
  List<Object?> get props => [];
}

class AdminStatisticsLoadRequested extends AdminStatisticsEvent {
  const AdminStatisticsLoadRequested();
}

class AdminStatisticsPeriodChanged extends AdminStatisticsEvent {
  final String period;
  const AdminStatisticsPeriodChanged(this.period);
  @override
  List<Object?> get props => [period];
}

class AdminStatisticsRankingLoadMore extends AdminStatisticsEvent {
  const AdminStatisticsRankingLoadMore();
}

class AdminOperatorStatsRequested extends AdminStatisticsEvent {
  final int operatorId;
  final String operatorName;
  const AdminOperatorStatsRequested({
    required this.operatorId,
    required this.operatorName,
  });
  @override
  List<Object?> get props => [operatorId, operatorName];
}
