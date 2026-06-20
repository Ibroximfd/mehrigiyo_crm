part of 'statuses_bloc.dart';

abstract class StatusesEvent extends Equatable {
  const StatusesEvent();
  @override
  List<Object?> get props => [];
}

class StatusesLoadRequested extends StatusesEvent {
  final String? category;
  const StatusesLoadRequested({this.category});
  @override
  List<Object?> get props => [category];
}

class StatusCreateRequested extends StatusesEvent {
  final String name;
  final String category;
  final String color;
  final int order;
  final bool isDefault;

  const StatusCreateRequested({
    required this.name,
    required this.category,
    this.color = '#6b7280',
    this.order = 99,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [name, category, color, order, isDefault];
}

class StatusDeleteRequested extends StatusesEvent {
  final int id;
  const StatusDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}
