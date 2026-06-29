import 'package:equatable/equatable.dart';

class ChatRoomEntity extends Equatable {
  final int id;
  final String participantName;
  final String participantPhone;
  final String? avatarUrl;
  final int? leadId;
  final String? lastMessage;
  final bool? lastMessageIsMine;
  final String? lastMessageAt;
  final int unreadCount;

  const ChatRoomEntity({
    required this.id,
    required this.participantName,
    required this.participantPhone,
    this.avatarUrl,
    this.leadId,
    this.lastMessage,
    this.lastMessageIsMine,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [
        id, participantName, participantPhone, avatarUrl,
        leadId, lastMessage, lastMessageIsMine, lastMessageAt, unreadCount
      ];

  ChatRoomEntity copyWithUnread(int unreadCount) => copyWith(unreadCount: unreadCount);

  ChatRoomEntity copyWith({
    String? participantName,
    String? participantPhone,
    String? avatarUrl,
    int? leadId,
    String? lastMessage,
    bool? lastMessageIsMine,
    String? lastMessageAt,
    int? unreadCount,
  }) => ChatRoomEntity(
    id: id,
    participantName: participantName ?? this.participantName,
    participantPhone: participantPhone ?? this.participantPhone,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    leadId: leadId ?? this.leadId,
    lastMessage: lastMessage ?? this.lastMessage,
    lastMessageIsMine: lastMessageIsMine ?? this.lastMessageIsMine,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    unreadCount: unreadCount ?? this.unreadCount,
  );
}

class ChatMessageEntity extends Equatable {
  final int id;
  final String messageType;
  final String text;
  final bool isMine;
  final bool isRead;
  final String? senderName;
  final ChatMessageReply? replyTo;
  final List<ChatAttachment> attachments;
  final ChatRecommendation? recommendation;
  final String createdAt;

  const ChatMessageEntity({
    required this.id,
    required this.messageType,
    required this.text,
    required this.isMine,
    this.isRead = false,
    this.senderName,
    this.replyTo,
    this.attachments = const [],
    this.recommendation,
    required this.createdAt,
  });

  bool get isRecommendation => messageType == 'operator_recommendation';
  bool get hasMedia => attachments.isNotEmpty
      || const {'image', 'video', 'audio', 'voice', 'file'}.contains(messageType);

  ChatMessageEntity copyWith({bool? isRead}) => ChatMessageEntity(
    id: id,
    messageType: messageType,
    text: text,
    isMine: isMine,
    isRead: isRead ?? this.isRead,
    senderName: senderName,
    replyTo: replyTo,
    attachments: attachments,
    recommendation: recommendation,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props =>
      [id, messageType, text, isMine, isRead, senderName, replyTo, attachments, recommendation, createdAt];
}

class ChatAttachment extends Equatable {
  final String url;
  final String fileType; // 'image', 'video', 'audio', 'file'
  final String? fileName;

  const ChatAttachment({
    required this.url,
    required this.fileType,
    this.fileName,
  });

  @override
  List<Object?> get props => [url, fileType, fileName];
}

class ChatMessageReply extends Equatable {
  final int id;
  final String text;
  final String messageType;
  final bool isMine;

  const ChatMessageReply({
    required this.id,
    required this.text,
    required this.messageType,
    required this.isMine,
  });

  @override
  List<Object?> get props => [id, text, messageType, isMine];
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

class ChatMessagesPage {
  final List<ChatMessageEntity> messages;
  final bool hasMore;    // yana eskiroq xabarlar bormi
  final int? oldestId;  // keyingi ?before= cursor uchun
  const ChatMessagesPage({
    required this.messages,
    required this.hasMore,
    this.oldestId,
  });
}

class ChatProductsPage {
  final List<ChatProductEntity> products;
  final bool hasMore;
  const ChatProductsPage({required this.products, required this.hasMore});
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
