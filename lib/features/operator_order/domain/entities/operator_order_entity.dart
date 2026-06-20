import 'package:equatable/equatable.dart';

class OperatorOrderEntity extends Equatable {
  final String orderNumber;
  final String status;
  final double totalAmount;
  final List<OperatorOrderItem> items;

  const OperatorOrderEntity({
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.items,
  });

  @override
  List<Object?> get props => [orderNumber, status, totalAmount, items];
}

class OperatorOrderItem extends Equatable {
  final int productId;
  final String productTitle;
  final int quantity;
  final double price;

  const OperatorOrderItem({
    required this.productId,
    required this.productTitle,
    required this.quantity,
    required this.price,
  });

  @override
  List<Object?> get props => [productId, productTitle, quantity, price];
}

// ── Request models (not entities, but co-located for simplicity) ─────────────

class OrderItemInput {
  final int productId;
  final int quantity;
  final int? operatorRecommendationId;

  const OrderItemInput({
    required this.productId,
    required this.quantity,
    this.operatorRecommendationId,
  });

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'quantity': quantity,
        if (operatorRecommendationId != null)
          'operator_recommendation_id': operatorRecommendationId,
      };
}
