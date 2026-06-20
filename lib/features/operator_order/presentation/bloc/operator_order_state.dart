part of 'operator_order_bloc.dart';

abstract class OperatorOrderState extends Equatable {
  const OperatorOrderState();
  @override
  List<Object?> get props => [];
}

class OperatorOrderInitial extends OperatorOrderState {}

class OperatorOrderCreating extends OperatorOrderState {}

class OperatorOrderCreated extends OperatorOrderState {
  final OperatorOrderEntity order;
  const OperatorOrderCreated(this.order);
  @override
  List<Object?> get props => [order];
}

class OperatorOrderError extends OperatorOrderState {
  final String message;
  const OperatorOrderError(this.message);
  @override
  List<Object?> get props => [message];
}
