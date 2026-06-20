import '../../domain/entities/operator_order_entity.dart';

class OperatorOrderModel extends OperatorOrderEntity {
  const OperatorOrderModel({
    required super.orderNumber,
    required super.status,
    required super.totalAmount,
    required super.items,
  });

  factory OperatorOrderModel.fromJson(Map<String, dynamic> json) {
    final orderData = json['order'] as Map<String, dynamic>? ?? json;
    final itemsJson = orderData['items'] as List? ?? [];
    return OperatorOrderModel(
      orderNumber: orderData['order_number']?.toString() ?? '',
      status: orderData['status']?.toString() ?? 'confirming',
      totalAmount: (orderData['total_amount'] as num?)?.toDouble() ?? 0,
      items: itemsJson
          .map((e) => _parseItem(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static OperatorOrderItem _parseItem(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return OperatorOrderItem(
      productId: (product?['id'] ?? json['product_id']) as int? ?? 0,
      productTitle: product?['title']?.toString() ?? json['product_title']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] ?? json['total_price'] as num?)?.toDouble() ?? 0,
    );
  }
}
