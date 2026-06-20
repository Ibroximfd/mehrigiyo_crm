part of 'operators_bloc.dart';

abstract class OperatorsEvent extends Equatable {
  const OperatorsEvent();
  @override
  List<Object?> get props => [];
}

class OperatorsLoadRequested extends OperatorsEvent {
  const OperatorsLoadRequested();
}

class OperatorsLoadMore extends OperatorsEvent {
  const OperatorsLoadMore();
}

class OperatorCreateRequested extends OperatorsEvent {
  final String fullName;
  final String username;
  final String password;
  final double commissionPercent;

  const OperatorCreateRequested({
    required this.fullName,
    required this.username,
    required this.password,
    this.commissionPercent = 10,
  });

  @override
  List<Object?> get props => [fullName, username, password, commissionPercent];
}
