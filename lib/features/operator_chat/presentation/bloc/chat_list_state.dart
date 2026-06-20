part of 'chat_list_bloc.dart';

abstract class ChatListState extends Equatable {
  const ChatListState();
  @override
  List<Object?> get props => [];
}

class ChatListInitial extends ChatListState {}

class ChatListLoading extends ChatListState {}

class ChatListLoaded extends ChatListState {
  final List<ChatRoomEntity> rooms;
  const ChatListLoaded(this.rooms);
  @override
  List<Object?> get props => [rooms];
}

class ChatListError extends ChatListState {
  final String message;
  const ChatListError(this.message);
  @override
  List<Object?> get props => [message];
}

class ChatListCreating extends ChatListState {}

class ChatListCreateError extends ChatListState {
  final String message;
  const ChatListCreateError(this.message);
  @override
  List<Object?> get props => [message];
}

class ChatRoomCreated extends ChatListState {
  final ChatRoomEntity room;
  const ChatRoomCreated(this.room);
  @override
  List<Object?> get props => [room];
}
