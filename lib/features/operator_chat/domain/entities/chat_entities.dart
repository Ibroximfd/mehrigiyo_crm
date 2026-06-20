import 'package:equatable/equatable.dart';

class ChatRoomEntity extends Equatable {
  final int id;
  final String participantName;
  final String participantPhone;
  final int? leadId;
  final String? lastMessage;
  final String? lastMessageAt;

  const ChatRoomEntity({
    required this.id,
    required this.participantName,
    required this.participantPhone,
    this.leadId,
    this.lastMessage,
    this.lastMessageAt,
  });

  @override
  List<Object?> get props => [id, participantName, participantPhone, leadId, lastMessage, lastMessageAt];
}

class ChatMessageEntity extends Equatable {
  final int id;
  final String messageType;
  final String text;
  final bool isMine;
  final ChatRecommendation? recommendation;
  final String createdAt;

  const ChatMessageEntity({
    required this.id,
    required this.messageType,
    required this.text,
    required this.isMine,
    this.recommendation,
    required this.createdAt,
  });

  bool get isRecommendation => messageType == 'operator_recommendation';

  @override
  List<Object?> get props => [id, messageType, text, isMine, recommendation, createdAt];
}

class ChatRecommendation extends Equatable {
  final int id;
  final String type;
  final List<RecommendedProduct> products;
  final String expiresAt;
  final bool isExpired;

  const ChatRecommendation({
    required this.id,
    required this.type,
    required this.products,
    required this.expiresAt,
    required this.isExpired,
  });

  @override
  List<Object?> get props => [id, type, products, expiresAt, isExpired];
}

class RecommendedProduct extends Equatable {
  final int id;
  final String title;
  final int cost;
  final int discount;
  final bool isActive;
  final String image;

  const RecommendedProduct({
    required this.id,
    required this.title,
    required this.cost,
    required this.discount,
    required this.isActive,
    required this.image,
  });

  int get finalPrice => discount > 0 ? (cost * (100 - discount) ~/ 100) : cost;

  @override
  List<Object?> get props => [id, title, cost, discount, isActive, image];
}

class ChatProductEntity extends Equatable {
  final int id;
  final String title;
  final int cost;
  final int discount;
  final bool isActive;
  final String image;

  const ChatProductEntity({
    required this.id,
    required this.title,
    required this.cost,
    required this.discount,
    required this.isActive,
    required this.image,
  });

  int get finalPrice => discount > 0 ? (cost * (100 - discount) ~/ 100) : cost;

  @override
  List<Object?> get props => [id, title, cost, discount, isActive, image];
}
