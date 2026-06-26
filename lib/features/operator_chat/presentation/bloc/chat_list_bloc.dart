import 'dart:async';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/chat_notification_ws_service.dart';
import '../../domain/entities/chat_entities.dart';
import '../../domain/usecases/chat_usecases.dart';

part 'chat_list_event.dart';
part 'chat_list_state.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final GetChatRoomsUseCase getRooms;
  final CreateChatRoomUseCase createRoom;
  final MarkChatAsReadUseCase markAsRead;
  final ChatListWsService wsService;

  /// Single long-lived subscription to the merged room stream. Living in the
  /// constructor (not inside an event handler) keeps real-time updates flowing
  /// even after reset/reconnect — used by the global unread badge in the nav.
  late final StreamSubscription<Map<String, dynamic>> _wsSub;

  ChatListBloc({
    required this.getRooms,
    required this.createRoom,
    required this.markAsRead,
    required this.wsService,
  }) : super(ChatListInitial()) {
    on<ChatListLoadRequested>(_onLoad);
    on<ChatListCreateRoomRequested>(_onCreate);
    on<ChatListRoomRead>(_onRoomRead);
    on<ChatListWsConnectRequested>(_onWsConnect, transformer: droppable());
    on<_ChatListWsMessageReceived>(_onWsMessage);
    on<ChatListReset>(_onReset);
    _wsSub = wsService.events.listen(
      (data) => add(_ChatListWsMessageReceived(data)),
    );
  }

  Future<void> _onLoad(ChatListLoadRequested event, Emitter<ChatListState> emit) async {
    emit(ChatListLoading());
    final result = await getRooms();
    result.fold(
      (f) => emit(ChatListError(f.message)),
      (rooms) {
        final sorted = _sorted(rooms);
        emit(ChatListLoaded(sorted));
        // Connect WS for every room so we get live updates without manual refresh
        add(ChatListWsConnectRequested(sorted.map((r) => r.id).toList()));
      },
    );
  }

  Future<void> _onWsConnect(
    ChatListWsConnectRequested event,
    Emitter<ChatListState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    if (token.isEmpty) return;
    // The stream itself is consumed by [_wsSub] for the bloc's whole lifetime;
    // here we only (re)open the per-room sockets.
    wsService.connectAll(event.roomIds, token);
  }

  void _onReset(ChatListReset event, Emitter<ChatListState> emit) {
    wsService.disconnect();
    emit(ChatListInitial());
  }

  void _onWsMessage(_ChatListWsMessageReceived event, Emitter<ChatListState> emit) {
    final cur = state;
    if (cur is! ChatListLoaded) return;

    final data = event.data;
    final roomId = data['_room_id'] as int?;
    if (roomId == null) return;

    final rooms = List<ChatRoomEntity>.of(cur.rooms);
    final idx = rooms.indexWhere((r) => r.id == roomId);
    if (idx < 0) return;

    // Extract message payload — supports both formats the per-room WS sends:
    // Format A: { "type": "new_message", "message": { id, text, is_mine, ... } }
    // Format B: { "id": ..., "text": ..., "is_mine": ..., ... }
    final msgRaw = data['message'];
    Map<String, dynamic>? msgData;
    if (msgRaw is Map<String, dynamic>) {
      msgData = msgRaw;
    } else if (data.containsKey('id')) {
      msgData = Map<String, dynamic>.from(data)..remove('_room_id');
    }

    if (msgData == null) return;

    final isMine = msgData['is_mine'] as bool? ?? false;
    final text = msgData['text']?.toString() ?? '';
    final createdAt = msgData['created_at']?.toString()
        ?? msgData['timestamp']?.toString();

    // Only increment unread for messages from the client (not operator's own echo)
    final newUnread = isMine ? rooms[idx].unreadCount : rooms[idx].unreadCount + 1;

    rooms[idx] = rooms[idx].copyWith(
      lastMessage: text.isNotEmpty ? text : rooms[idx].lastMessage,
      lastMessageIsMine: isMine,
      lastMessageAt: createdAt ?? rooms[idx].lastMessageAt,
      unreadCount: newUnread,
    );

    emit(ChatListLoaded(_sorted(rooms)));
  }

  void _onRoomRead(ChatListRoomRead event, Emitter<ChatListState> emit) {
    final cur = state;
    if (cur is! ChatListLoaded) return;
    final rooms = cur.rooms.map((r) {
      return r.id == event.roomId ? r.copyWithUnread(0) : r;
    }).toList();
    emit(ChatListLoaded(rooms));
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

  List<ChatRoomEntity> _sorted(List<ChatRoomEntity> rooms) {
    return List.of(rooms)
      ..sort((a, b) {
        final aAt = a.lastMessageAt;
        final bAt = b.lastMessageAt;
        if (aAt == null && bAt == null) return 0;
        if (aAt == null) return 1;
        if (bAt == null) return -1;
        try {
          return DateTime.parse(bAt).compareTo(DateTime.parse(aAt));
        } catch (_) {
          return 0;
        }
      });
  }

  @override
  Future<void> close() {
    _wsSub.cancel();
    wsService.disconnect();
    return super.close();
  }
}
