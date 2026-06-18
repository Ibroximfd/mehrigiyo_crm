import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import '../../features/orders/data/datasources/order_remote_data_source.dart';

// ─── Events ──────────────────────────────────────────────────────────────────
abstract class BadgeEvent extends Equatable {
  const BadgeEvent();
  @override
  List<Object?> get props => const [];
}

class LoadBadgeCounts extends BadgeEvent {
  const LoadBadgeCounts();
}

class ResetBadgeCounts extends BadgeEvent {
  const ResetBadgeCounts();
}

class DecrementConsultations extends BadgeEvent {
  const DecrementConsultations();
}

// ─── State ───────────────────────────────────────────────────────────────────
class BadgeState extends Equatable {
  final int newConsultations;

  const BadgeState({this.newConsultations = 0});

  BadgeState copyWith({int? newConsultations}) {
    return BadgeState(newConsultations: newConsultations ?? this.newConsultations);
  }

  @override
  List<Object?> get props => [newConsultations];
}

// ─── Bloc ────────────────────────────────────────────────────────────────────
class BadgeBloc extends Bloc<BadgeEvent, BadgeState> {
  final DashboardRemoteDataSource dashboardDataSource;
  final OrderRemoteDataSource ordersDataSource;

  BadgeBloc({
    required this.dashboardDataSource,
    required this.ordersDataSource,
  }) : super(const BadgeState()) {
    on<LoadBadgeCounts>(_onLoad);
    on<ResetBadgeCounts>((_, emit) => emit(const BadgeState()));
    on<DecrementConsultations>((_, emit) {
      final next = state.newConsultations - 1;
      emit(state.copyWith(newConsultations: next < 0 ? 0 : next));
    });
  }

  Future<void> _onLoad(LoadBadgeCounts event, Emitter<BadgeState> emit) async {
    final count = await _fetchNewConsultations();
    emit(BadgeState(newConsultations: count ?? state.newConsultations));
  }

  Future<int?> _fetchNewConsultations() async {
    try {
      final stats = await dashboardDataSource.getStats();
      return stats.newConsultationsCount;
    } catch (_) {
      return null;
    }
  }
}
