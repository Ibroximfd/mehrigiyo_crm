import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chat_entities.dart';
import '../../domain/usecases/chat_usecases.dart';

part 'chat_list_event.dart';
part 'chat_list_state.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final GetChatRoomsUseCase getRooms;
  final CreateChatRoomUseCase createRoom;

  ChatListBloc({required this.getRooms, required this.createRoom})
      : super(ChatListInitial()) {
    on<ChatListLoadRequested>(_onLoad);
    on<ChatListCreateRoomRequested>(_onCreate);
  }

  Future<void> _onLoad(ChatListLoadRequested event, Emitter<ChatListState> emit) async {
    emit(ChatListLoading());
    final result = await getRooms();
    result.fold(
      (f) => emit(ChatListError(f.message)),
      (rooms) => emit(ChatListLoaded(rooms)),
    );
  }

  Future<void> _onCreate(
    ChatListCreateRoomRequested event,
    Emitter<ChatListState> emit,
  ) async {
    emit(ChatListCreating());
    final result = await createRoom(phone: event.phone, leadId: event.leadId);
    result.fold(
      (f) => emit(ChatListCreateError(f.message)),
      (room) {
        emit(ChatRoomCreated(room));
        add(const ChatListLoadRequested());
      },
    );
  }
}
