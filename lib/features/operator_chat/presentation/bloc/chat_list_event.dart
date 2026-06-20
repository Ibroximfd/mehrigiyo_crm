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
