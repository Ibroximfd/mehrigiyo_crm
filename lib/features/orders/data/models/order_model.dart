import '../../domain/entities/order_entity.dart';
import 'order_item_model.dart';

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.orderNumber,
    required super.userPhone,
    required super.status,
    required super.statusDisplay,
    required super.paymentMethod,
    required super.paymentProvider,
    required super.totalAmount,
    required super.itemCount,
    required super.isPaid,
    required super.source,
    required super.deliveryAddress,
    required super.createdAt,
    super.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final statusDisplay = json['status_display'];
    String displayText = '';
    if (statusDisplay is Map) {
      displayText = statusDisplay['uz'] ?? statusDisplay['en'] ?? '';
    } else if (statusDisplay is String) {
      displayText = statusDisplay;
    } else {
      displayText = _statusLabel(json['status'] ?? '');
    }

    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((e) => OrderItemModel.fromJson(e.cast<String, dynamic>()))
              .toList()
        : <OrderItemModel>[];

    return OrderModel(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number'] ?? '',
      userPhone: json['user_phone'] ?? '',
      status: json['status'] ?? '',
      statusDisplay: displayText,
      paymentMethod: json['payment_method'] ?? '',
      paymentProvider: json['payment_provider'] ?? '',
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      itemCount: json['item_count'] ?? 0,
      isPaid: json['is_paid'] ?? false,
      source: json['source'] ?? 'mehrigiyo',
      deliveryAddress: json['delivery_address'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      items: items,
    );
  }

  static String _statusLabel(String status) {
    const labels = {
      'pending': 'Kutilmoqda',
      'confirming': "Naqd to'lov kutilmoqda",
      'paid': "To'langan",
      'confirmed': 'Tasdiqlangan',
      'preparing': 'Tayyorlanmoqda',
      'shipping': 'Yetkazilmoqda',
      'delivered': 'Yetkazildi',
      'cancelled': 'Bekor qilindi',
    };
    return labels[status] ?? status;
  }
}
