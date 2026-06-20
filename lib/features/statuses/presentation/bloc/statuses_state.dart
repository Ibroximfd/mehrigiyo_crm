part of 'statuses_bloc.dart';

abstract class StatusesState extends Equatable {
  const StatusesState();
  @override
  List<Object?> get props => [];
}

class StatusesInitial extends StatusesState {}

class StatusesLoading extends StatusesState {}

class StatusesLoaded extends StatusesState {
  final List<StatusEntity> statuses;
  const StatusesLoaded(this.statuses);
  @override
  List<Object?> get props => [statuses];
}

class StatusesError extends StatusesState {
  final String message;
  const StatusesError(this.message);
  @override
  List<Object?> get props => [message];
}

class StatusMutating extends StatusesState {
  final List<StatusEntity> statuses;
  const StatusMutating(this.statuses);
  @override
  List<Object?> get props => [statuses];
}

class StatusMutateError extends StatusesState {
  final List<StatusEntity> statuses;
  final String message;
  const StatusMutateError(this.statuses, this.message);
  @override
  List<Object?> get props => [statuses, message];
}
