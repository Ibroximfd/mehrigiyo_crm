import 'package:equatable/equatable.dart';

sealed class ConsultationsEvent extends Equatable {
  const ConsultationsEvent();

  @override
  List<Object?> get props => [];
}

/// Fresh load — resets offset and replaces the list.
class LoadConsultations extends ConsultationsEvent {
  final int? status;
  final String? searchQuery;
  final bool isRefresh;

  const LoadConsultations({
    this.status,
    this.searchQuery,
    this.isRefresh = false,
  });

  @override
  List<Object?> get props => [status, searchQuery, isRefresh];
}

/// Appends the next page to the existing list.
class LoadMoreConsultations extends ConsultationsEvent {
  const LoadMoreConsultations();
}
