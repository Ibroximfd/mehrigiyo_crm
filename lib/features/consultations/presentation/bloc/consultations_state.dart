import 'package:equatable/equatable.dart';
import '../../domain/entities/consultation_entity.dart';

sealed class ConsultationsState extends Equatable {
  const ConsultationsState();

  @override
  List<Object?> get props => [];
}

class ConsultationsInitial extends ConsultationsState {
  const ConsultationsInitial();
}

class ConsultationsLoading extends ConsultationsState {
  final List<ConsultationEntity> oldConsultations;
  final bool isRefreshing;

  const ConsultationsLoading(
    this.oldConsultations, {
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [oldConsultations, isRefreshing];
}

class ConsultationsLoaded extends ConsultationsState {
  final List<ConsultationEntity> consultations;
  final int? activeStatus;
  final String? activeSearch;
  final bool hasMore;
  final bool isLoadingMore;

  const ConsultationsLoaded({
    required this.consultations,
    this.activeStatus,
    this.activeSearch,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  ConsultationsLoaded copyWith({
    List<ConsultationEntity>? consultations,
    int? activeStatus,
    String? activeSearch,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ConsultationsLoaded(
      consultations: consultations ?? this.consultations,
      activeStatus: activeStatus ?? this.activeStatus,
      activeSearch: activeSearch ?? this.activeSearch,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    consultations,
    activeStatus,
    activeSearch,
    hasMore,
    isLoadingMore,
  ];
}

class ConsultationsError extends ConsultationsState {
  final String message;
  const ConsultationsError(this.message);

  @override
  List<Object?> get props => [message];
}
