import '../../domain/entities/order_item_entity.dart';

class OrderItemModel extends OrderItemEntity {
  const OrderItemModel({
    required super.medicineName,
    required super.medicineImage,
    required super.quantity,
    required super.price,
    required super.total,
    super.isGifted,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      medicineName: json['medicine_name']?.toString() ?? '',
      medicineImage: json['medicine_image']?.toString() ?? '',
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toInt()
          : int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      isGifted: json['is_gifted'] == true,
    );
  }
}
