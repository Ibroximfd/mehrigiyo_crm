import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/statistics_entity.dart';
import '../../domain/usecases/statistics_usecases.dart';

part 'statistics_event.dart';
part 'statistics_state.dart';

class SellerStatisticsBloc
    extends Bloc<SellerStatisticsEvent, SellerStatisticsState> {
  final GetMyStatisticsUseCase _getMyStats;

  SellerStatisticsBloc({required this._getMyStats})
      : super(SellerStatisticsInitial()) {
    on<SellerStatisticsLoadRequested>(_onLoad);
    on<SellerStatisticsPeriodChanged>(_onPeriodChanged);
  }

  Future<void> _onLoad(
    SellerStatisticsLoadRequested event,
    Emitter<SellerStatisticsState> emit,
  ) async {
    final period = state is SellerStatisticsLoaded
        ? (state as SellerStatisticsLoaded).period
        : 'today';
    emit(SellerStatisticsLoading(period: period));
    final result = await _getMyStats(period: period);
    result.fold(
      (f) => emit(SellerStatisticsError(f.message, period: period)),
      (data) => emit(SellerStatisticsLoaded(data: data, period: period)),
    );
  }

  Future<void> _onPeriodChanged(
    SellerStatisticsPeriodChanged event,
    Emitter<SellerStatisticsState> emit,
  ) async {
    emit(SellerStatisticsLoading(period: event.period));
    final result = await _getMyStats(period: event.period);
    result.fold(
      (f) => emit(SellerStatisticsError(f.message, period: event.period)),
      (data) => emit(SellerStatisticsLoaded(data: data, period: event.period)),
    );
  }
}

class AdminStatisticsBloc
    extends Bloc<AdminStatisticsEvent, AdminStatisticsState> {
  final GetAdminStatisticsUseCase _getAdminStats;
  final GetOperatorsRankingUseCase _getRanking;
  final GetOperatorStatsUseCase _getOperatorStats;

  AdminStatisticsBloc({
    required this._getAdminStats,
    required this._getRanking,
    required this._getOperatorStats,
  })  : super(AdminStatisticsInitial()) {
    on<AdminStatisticsLoadRequested>(_onLoad);
    on<AdminStatisticsPeriodChanged>(_onPeriodChanged);
    on<AdminStatisticsRankingLoadMore>(_onLoadMore);
    on<AdminOperatorStatsRequested>(_onOperatorStats);
  }

  String get _currentPeriod => switch (state) {
        AdminStatisticsLoaded s => s.period,
        AdminStatisticsLoading s => s.period,
        AdminStatisticsError s => s.period,
        _ => 'all',
      };

  Future<void> _onLoad(
    AdminStatisticsLoadRequested event,
    Emitter<AdminStatisticsState> emit,
  ) async {
    final period = _currentPeriod;
    emit(AdminStatisticsLoading(period: period));
    final statsResult = await _getAdminStats(period: period);
    final rankingResult = await _getRanking(period: period, page: 1);

    AdminStatisticsEntity? stats;
    OperatorRankingListEntity? ranking;
    String? error;

    statsResult.fold((f) => error = f.message, (d) => stats = d);
    rankingResult.fold((f) => error ??= f.message, (d) => ranking = d);

    if (stats != null && ranking != null) {
      emit(AdminStatisticsLoaded(
        stats: stats!,
        ranking: ranking!,
        period: period,
        rankingPage: 1,
      ));
    } else {
      emit(AdminStatisticsError(error!, period: period));
    }
  }

  Future<void> _onPeriodChanged(
    AdminStatisticsPeriodChanged event,
    Emitter<AdminStatisticsState> emit,
  ) async {
    emit(AdminStatisticsLoading(period: event.period));
    final statsResult = await _getAdminStats(period: event.period);
    final rankingResult = await _getRanking(period: event.period, page: 1);

    AdminStatisticsEntity? stats;
    OperatorRankingListEntity? ranking;
    String? error;

    statsResult.fold((f) => error = f.message, (d) => stats = d);
    rankingResult.fold((f) => error ??= f.message, (d) => ranking = d);

    if (stats != null && ranking != null) {
      emit(AdminStatisticsLoaded(
        stats: stats!,
        ranking: ranking!,
        period: event.period,
        rankingPage: 1,
      ));
    } else {
      emit(AdminStatisticsError(error!, period: event.period));
    }
  }

  Future<void> _onLoadMore(
    AdminStatisticsRankingLoadMore event,
    Emitter<AdminStatisticsState> emit,
  ) async {
    final current = state;
    if (current is! AdminStatisticsLoaded || !current.ranking.hasMore) return;
    final nextPage = current.rankingPage + 1;
    final result = await _getRanking(period: current.period, page: nextPage);
    result.fold(
      (_) => null,
      (more) => emit(current.copyWith(
        ranking: OperatorRankingListEntity(
          count: more.count,
          results: [...current.ranking.results, ...more.results],
          hasMore: more.hasMore,
        ),
        rankingPage: nextPage,
      )),
    );
  }

  Future<void> _onOperatorStats(
    AdminOperatorStatsRequested event,
    Emitter<AdminStatisticsState> emit,
  ) async {
    final current = state;
    if (current is! AdminStatisticsLoaded) return;
    emit(current.copyWith(selectedOperatorStats: null, isLoadingOperatorStats: true));
    final result = await _getOperatorStats(
      operatorId: event.operatorId,
      period: current.period,
    );
    result.fold(
      (f) => emit(current.copyWith(isLoadingOperatorStats: false)),
      (data) => emit(current.copyWith(
        selectedOperatorStats: data,
        selectedOperatorId: event.operatorId,
        selectedOperatorName: event.operatorName,
        isLoadingOperatorStats: false,
      )),
    );
  }
}
