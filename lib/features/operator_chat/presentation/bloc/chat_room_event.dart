part of 'chat_room_bloc.dart';

abstract class ChatRoomEvent extends Equatable {
  const ChatRoomEvent();
  @override
  List<Object?> get props => [];
}

class ChatRoomLoadRequested extends ChatRoomEvent {
  final int roomId;
  const ChatRoomLoadRequested(this.roomId);
  @override
  List<Object?> get props => [roomId];
}

class ChatRoomMessageSent extends ChatRoomEvent {
  final String text;
  const ChatRoomMessageSent(this.text);
  @override
  List<Object?> get props => [text];
}

class ChatRoomRecommendationSent extends ChatRoomEvent {
  final List<int> productIds;
  final int? leadId;
  const ChatRoomRecommendationSent({required this.productIds, this.leadId});
  @override
  List<Object?> get props => [productIds, leadId];
}

class ChatRoomProductsSearched extends ChatRoomEvent {
  final String query;
  const ChatRoomProductsSearched(this.query);
  @override
  List<Object?> get props => [query];
}

class ChatRoomProductsLoadMore extends ChatRoomEvent {
  const ChatRoomProductsLoadMore();
}

class ChatRoomWsConnectRequested extends ChatRoomEvent {
  const ChatRoomWsConnectRequested();
}

// Internal — only dispatched from WS stream handler
class _ChatRoomWsMessageReceived extends ChatRoomEvent {
  final Map<String, dynamic> data;
  const _ChatRoomWsMessageReceived(this.data);
  @override
  List<Object?> get props => [data];
}
