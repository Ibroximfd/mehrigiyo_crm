part of 'operator_order_bloc.dart';

abstract class OperatorOrderEvent extends Equatable {
  const OperatorOrderEvent();
  @override
  List<Object?> get props => [];
}

class OperatorOrderCreateManual extends OperatorOrderEvent {
  final String phone;
  final List<OrderItemInput> items;
  final int? leadId;
  final int? deliveryAddressId;
  final String? customerNotes;

  const OperatorOrderCreateManual({
    required this.phone,
    required this.items,
    this.leadId,
    this.deliveryAddressId,
    this.customerNotes,
  });

  @override
  List<Object?> get props => [phone, items, leadId, deliveryAddressId, customerNotes];
}

class OperatorOrderCreateFromRecommendation extends OperatorOrderEvent {
  final String phone;
  final int operatorRecommendationId;
  final int? deliveryAddressId;
  final String? customerNotes;

  const OperatorOrderCreateFromRecommendation({
    required this.phone,
    required this.operatorRecommendationId,
    this.deliveryAddressId,
    this.customerNotes,
  });

  @override
  List<Object?> get props => [phone, operatorRecommendationId, deliveryAddressId, customerNotes];
}
