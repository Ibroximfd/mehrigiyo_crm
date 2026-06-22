part of 'statistics_bloc.dart';

// ─── Seller States ─────────────────────────────────────────────────────────────
sealed class SellerStatisticsState extends Equatable {
  const SellerStatisticsState();
  @override
  List<Object?> get props => [];
}

class SellerStatisticsInitial extends SellerStatisticsState {}

class SellerStatisticsLoading extends SellerStatisticsState {
  final String period;
  const SellerStatisticsLoading({required this.period});
  @override
  List<Object?> get props => [period];
}

class SellerStatisticsLoaded extends SellerStatisticsState {
  final SellerStatisticsEntity data;
  final String period;
  const SellerStatisticsLoaded({required this.data, required this.period});
  @override
  List<Object?> get props => [data, period];
}

class SellerStatisticsError extends SellerStatisticsState {
  final String message;
  final String period;
  const SellerStatisticsError(this.message, {required this.period});
  @override
  List<Object?> get props => [message, period];
}

// ─── Admin States ──────────────────────────────────────────────────────────────
sealed class AdminStatisticsState extends Equatable {
  const AdminStatisticsState();
  @override
  List<Object?> get props => [];
}

class AdminStatisticsInitial extends AdminStatisticsState {}

class AdminStatisticsLoading extends AdminStatisticsState {
  final String period;
  const AdminStatisticsLoading({required this.period});
  @override
  List<Object?> get props => [period];
}

class AdminStatisticsLoaded extends AdminStatisticsState {
  final AdminStatisticsEntity stats;
  final OperatorRankingListEntity ranking;
  final String period;
  final int rankingPage;
  final SellerStatisticsEntity? selectedOperatorStats;
  final int? selectedOperatorId;
  final String? selectedOperatorName;
  final bool isLoadingOperatorStats;

  const AdminStatisticsLoaded({
    required this.stats,
    required this.ranking,
    required this.period,
    required this.rankingPage,
    this.selectedOperatorStats,
    this.selectedOperatorId,
    this.selectedOperatorName,
    this.isLoadingOperatorStats = false,
  });

  AdminStatisticsLoaded copyWith({
    AdminStatisticsEntity? stats,
    OperatorRankingListEntity? ranking,
    String? period,
    int? rankingPage,
    SellerStatisticsEntity? selectedOperatorStats,
    int? selectedOperatorId,
    String? selectedOperatorName,
    bool? isLoadingOperatorStats,
  }) =>
      AdminStatisticsLoaded(
        stats: stats ?? this.stats,
        ranking: ranking ?? this.ranking,
        period: period ?? this.period,
        rankingPage: rankingPage ?? this.rankingPage,
        selectedOperatorStats: selectedOperatorStats ?? this.selectedOperatorStats,
        selectedOperatorId: selectedOperatorId ?? this.selectedOperatorId,
        selectedOperatorName: selectedOperatorName ?? this.selectedOperatorName,
        isLoadingOperatorStats: isLoadingOperatorStats ?? this.isLoadingOperatorStats,
      );

  @override
  List<Object?> get props => [
        stats,
        ranking,
        period,
        rankingPage,
        selectedOperatorStats,
        selectedOperatorId,
        selectedOperatorName,
        isLoadingOperatorStats,
      ];
}

class AdminStatisticsError extends AdminStatisticsState {
  final String message;
  final String period;
  const AdminStatisticsError(this.message, {required this.period});
  @override
  List<Object?> get props => [message, period];
}
