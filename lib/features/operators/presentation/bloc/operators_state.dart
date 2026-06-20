part of 'operators_bloc.dart';

abstract class OperatorsState extends Equatable {
  const OperatorsState();
  @override
  List<Object?> get props => [];
}

class OperatorsInitial extends OperatorsState {}

class OperatorsLoading extends OperatorsState {}

class OperatorsLoaded extends OperatorsState {
  final List<OperatorEntity> operators;
  final bool hasMore;
  final int page;

  const OperatorsLoaded({
    required this.operators,
    this.hasMore = false,
    this.page = 1,
  });

  OperatorsLoaded copyWith({
    List<OperatorEntity>? operators,
    bool? hasMore,
    int? page,
  }) =>
      OperatorsLoaded(
        operators: operators ?? this.operators,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
      );

  @override
  List<Object?> get props => [operators, hasMore, page];
}

class OperatorsError extends OperatorsState {
  final String message;
  const OperatorsError(this.message);
  @override
  List<Object?> get props => [message];
}

class OperatorCreating extends OperatorsState {}

class OperatorCreated extends OperatorsState {
  final OperatorEntity operator;
  const OperatorCreated(this.operator);
  @override
  List<Object?> get props => [operator];
}

class OperatorCreateError extends OperatorsState {
  final String message;
  const OperatorCreateError(this.message);
  @override
  List<Object?> get props => [message];
}
