import '../../domain/entities/chat_entities.dart';

class ChatRoomModel extends ChatRoomEntity {
  const ChatRoomModel({
    required super.id,
    required super.participantName,
    required super.participantPhone,
    super.leadId,
    super.lastMessage,
    super.lastMessageAt,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    final participant = json['participant'] as Map<String, dynamic>?;
    return ChatRoomModel(
      id: json['room_id'] as int? ?? json['id'] as int,
      participantName: participant?['full_name']?.toString() ??
          participant?['name']?.toString() ??
          json['participant_name']?.toString() ??
          '',
      participantPhone: participant?['phone']?.toString() ??
          json['participant_phone']?.toString() ??
          '',
      leadId: json['lead_id'] as int?,
      lastMessage: json['last_message']?.toString(),
      lastMessageAt: json['last_message_at']?.toString() ??
          json['updated_at']?.toString(),
    );
  }
}

class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.messageType,
    required super.text,
    required super.isMine,
    super.recommendation,
    required super.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final recJson = json['recommendation'] as Map<String, dynamic>?;
    return ChatMessageModel(
      id: json['id'] as int,
      messageType: json['message_type']?.toString() ?? 'text',
      text: json['text']?.toString() ?? '',
      isMine: json['is_mine'] as bool? ?? false,
      recommendation: recJson != null ? _parseRecommendation(recJson) : null,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  static ChatRecommendation _parseRecommendation(Map<String, dynamic> json) {
    final productsJson = json['products'] as List? ?? [];
    return ChatRecommendation(
      id: json['id'] as int,
      type: json['type']?.toString() ?? 'operator',
      products: productsJson
          .map((p) => _parseProduct(p as Map<String, dynamic>))
          .toList(),
      expiresAt: json['expires_at']?.toString() ?? '',
      isExpired: json['is_expired'] as bool? ?? false,
    );
  }

  static RecommendedProduct _parseProduct(Map<String, dynamic> json) {
    return RecommendedProduct(
      id: json['id'] as int,
      title: json['title']?.toString() ?? '',
      cost: (json['cost'] as num?)?.toInt() ?? 0,
      discount: (json['discount'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      image: json['image']?.toString() ?? '',
    );
  }
}

class ChatProductModel extends ChatProductEntity {
  const ChatProductModel({
    required super.id,
    required super.title,
    required super.cost,
    required super.discount,
    required super.isActive,
    required super.image,
  });

  factory ChatProductModel.fromJson(Map<String, dynamic> json) {
    return ChatProductModel(
      id: json['id'] as int,
      title: json['title']?.toString() ?? '',
      cost: (json['cost'] as num?)?.toInt() ?? 0,
      discount: (json['discount'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      image: json['image']?.toString() ?? '',
    );
  }
}
