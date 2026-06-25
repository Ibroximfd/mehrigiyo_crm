part of 'chat_list_bloc.dart';

abstract class ChatListEvent extends Equatable {
  const ChatListEvent();
  @override
  List<Object?> get props => [];
}

class ChatListLoadRequested extends ChatListEvent {
  const ChatListLoadRequested();
}

class ChatListCreateRoomRequested extends ChatListEvent {
  final String phone;
  final int? leadId;
  const ChatListCreateRoomRequested({required this.phone, this.leadId});
  @override
  List<Object?> get props => [phone, leadId];
}

class ChatListRoomRead extends ChatListEvent {
  final int roomId;
  const ChatListRoomRead(this.roomId);
  @override
  List<Object?> get props => [roomId];
}

class ChatListWsConnectRequested extends ChatListEvent {
  final List<int> roomIds;
  const ChatListWsConnectRequested(this.roomIds);
  @override
  List<Object?> get props => [roomIds];
}

class _ChatListWsMessageReceived extends ChatListEvent {
  final Map<String, dynamic> data;
  const _ChatListWsMessageReceived(this.data);
  @override
  List<Object?> get props => [data];
}
