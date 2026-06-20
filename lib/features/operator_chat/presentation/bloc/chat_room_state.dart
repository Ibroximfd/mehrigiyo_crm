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
  final List<ChatProductEntity> products;
  final bool productsLoading;
  final bool productsHasMore;
  final int productsPage;
  final String productsQuery;

  const ChatRoomLoaded({
    required this.roomId,
    required this.messages,
    this.isSending = false,
    this.sendError,
    this.products = const [],
    this.productsLoading = false,
    this.productsHasMore = false,
    this.productsPage = 1,
    this.productsQuery = '',
  });

  ChatRoomLoaded copyWith({
    List<ChatMessageEntity>? messages,
    bool? isSending,
    String? sendError,
    List<ChatProductEntity>? products,
    bool? productsLoading,
    bool? productsHasMore,
    int? productsPage,
    String? productsQuery,
  }) =>
      ChatRoomLoaded(
        roomId: roomId,
        messages: messages ?? this.messages,
        isSending: isSending ?? this.isSending,
        sendError: sendError,
        products: products ?? this.products,
        productsLoading: productsLoading ?? this.productsLoading,
        productsHasMore: productsHasMore ?? this.productsHasMore,
        productsPage: productsPage ?? this.productsPage,
        productsQuery: productsQuery ?? this.productsQuery,
      );

  @override
  List<Object?> get props =>
      [roomId, messages, isSending, sendError, products, productsLoading, productsHasMore, productsPage, productsQuery];
}
