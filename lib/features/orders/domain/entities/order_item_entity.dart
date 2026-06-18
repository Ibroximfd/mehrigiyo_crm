class OrderItemEntity {
  final String medicineName;
  final String medicineImage;
  final int quantity;
  final double price;
  final double total;
  final bool isGifted;

  const OrderItemEntity({
    required this.medicineName,
    required this.medicineImage,
    required this.quantity,
    required this.price,
    required this.total,
    this.isGifted = false,
  });
}
