import 'order_item_entity.dart';

class OrderEntity {
  final String id;
  final String orderNumber;
  final String userPhone;
  final String status;
  final String statusDisplay;
  final String paymentMethod;
  final String paymentProvider;
  final double totalAmount;
  final int itemCount;
  final bool isPaid;
  final String source;
  final String deliveryAddress;
  final DateTime createdAt;
  final List<OrderItemEntity> items;

  const OrderEntity({
    required this.id,
    required this.orderNumber,
    required this.userPhone,
    required this.status,
    required this.statusDisplay,
    required this.paymentMethod,
    required this.paymentProvider,
    required this.totalAmount,
    required this.itemCount,
    required this.isPaid,
    required this.source,
    required this.deliveryAddress,
    required this.createdAt,
    this.items = const [],
  });
}
