part of 'chat_room_bloc.dart';

abstract class ChatRoomState extends Equatable {
  const ChatRoomState();
  @override
  List<Object?> get props => [];
}

class ChatRoomInitial extends ChatRoomState {}

class ChatRoomLoading extends ChatRoomState {}

class ChatRoomError extends ChatRoomState {
  final String message;
  const ChatRoomError(this.message);
  @override
  List<Object?> get props => [message];
}

class ChatRoomLoaded extends ChatRoomState {
  final int roomId;
  final List<ChatMessageEntity> messages;
  final bool isSending;
  final String? sendError;
  final ChatMessageEntity? replyToMessage;
  final List<ChatProductEntity> products;
  final bool productsLoading;
  final bool productsHasMore;
  final int productsPage;
  final String productsQuery;
  final bool hasOlderMessages;
  final bool isLoadingMore;
  final int? oldestMessageId;
  final bool isOnline;

  const ChatRoomLoaded({
    required this.roomId,
    required this.messages,
    this.isSending = false,
    this.sendError,
    this.replyToMessage,
    this.products = const [],
    this.productsLoading = false,
    this.productsHasMore = false,
    this.productsPage = 1,
    this.productsQuery = '',
    this.hasOlderMessages = false,
    this.isLoadingMore = false,
    this.oldestMessageId,
    this.isOnline = false,
  });

  ChatRoomLoaded copyWith({
    List<ChatMessageEntity>? messages,
    bool? isSending,
    String? sendError,
    Object? replyToMessage = _sentinel,
    List<ChatProductEntity>? products,
    bool? productsLoading,
    bool? productsHasMore,
    int? productsPage,
    String? productsQuery,
    bool? hasOlderMessages,
    bool? isLoadingMore,
    Object? oldestMessageId = _sentinel,
    bool? isOnline,
  }) =>
      ChatRoomLoaded(
        roomId: roomId,
        messages: messages ?? this.messages,
        isSending: isSending ?? this.isSending,
        sendError: sendError,
        replyToMessage: replyToMessage == _sentinel
            ? this.replyToMessage
            : replyToMessage as ChatMessageEntity?,
        products: products ?? this.products,
        productsLoading: productsLoading ?? this.productsLoading,
        productsHasMore: productsHasMore ?? this.productsHasMore,
        productsPage: productsPage ?? this.productsPage,
        productsQuery: productsQuery ?? this.productsQuery,
        hasOlderMessages: hasOlderMessages ?? this.hasOlderMessages,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        oldestMessageId: oldestMessageId == _sentinel
            ? this.oldestMessageId
            : oldestMessageId as int?,
        isOnline: isOnline ?? this.isOnline,
      );

  @override
  List<Object?> get props => [
        roomId, messages, isSending, sendError, replyToMessage,
        products, productsLoading, productsHasMore, productsPage, productsQuery,
        hasOlderMessages, isLoadingMore, oldestMessageId, isOnline,
      ];
}

const _sentinel = Object();
