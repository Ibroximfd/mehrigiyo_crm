import 'dart:typed_data';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/chat_models.dart';
import '../../data/services/chat_ws_service.dart';
import '../../domain/entities/chat_entities.dart';
import '../../domain/usecases/chat_usecases.dart';

part 'chat_room_event.dart';
part 'chat_room_state.dart';

class ChatRoomBloc extends Bloc<ChatRoomEvent, ChatRoomState> {
  final GetChatMessagesUseCase getMessages;
  final SendChatMessageUseCase sendMessage;
  final SendMediaMessageUseCase sendMediaMessage;
  final SendRecommendationUseCase sendRecommendation;
  final SearchProductsUseCase searchProducts;
  final ChatWsService wsService;
  final MarkChatAsReadUseCase markAsRead;

  // IDs of messages we sent via API — suppress their WS echo
  final Set<int> _suppressedWsIds = {};

  ChatRoomBloc({
    required this.getMessages,
    required this.sendMessage,
    required this.sendMediaMessage,
    required this.sendRecommendation,
    required this.searchProducts,
    required this.wsService,
    required this.markAsRead,
  }) : super(ChatRoomInitial()) {
    on<ChatRoomLoadRequested>(_onLoad);
    on<ChatRoomLoadMoreRequested>(_onLoadMore);
    on<ChatRoomMessageSent>(_onSendMessage);
    on<ChatRoomMediaSent>(_onSendMedia);
    on<ChatRoomRecommendationSent>(_onSendRecommendation);
    on<ChatRoomProductsSearched>(_onSearchProducts);
    on<ChatRoomProductsLoadMore>(_onLoadMoreProducts);
    on<ChatRoomReplySet>(_onReplySet);
    on<ChatRoomReplyCanceled>(_onReplyCanceled);
    on<ChatRoomWsConnectRequested>(_onWsConnect, transformer: droppable());
    on<_ChatRoomWsMessageReceived>(_onWsMessage);
  }

  Future<void> _onLoad(ChatRoomLoadRequested event, Emitter<ChatRoomState> emit) async {
    emit(ChatRoomLoading());
    // No beforeId on first load → server returns newest 50 in ASC order
    final result = await getMessages(event.roomId);
    result.fold(
      (f) => emit(ChatRoomError(f.message)),
      (page) {
        emit(ChatRoomLoaded(
          roomId: event.roomId,
          messages: page.messages,
          hasOlderMessages: page.hasMore,
          oldestMessageId: page.oldestId,
        ));
        _connectWs(event.roomId);
        markAsRead(event.roomId).then((_) {}).catchError((_) {});
      },
    );
  }

  Future<void> _onLoadMore(ChatRoomLoadMoreRequested event, Emitter<ChatRoomState> emit) async {
    final cur = state;
    if (cur is! ChatRoomLoaded) return;
    if (!cur.hasOlderMessages || cur.isLoadingMore) return;

    emit(cur.copyWith(isLoadingMore: true));

    // Cursor pagination: ?before=oldestMessageId → older 50 messages
    final result = await getMessages(cur.roomId, beforeId: cur.oldestMessageId);
    result.fold(
      (f) => emit(cur.copyWith(isLoadingMore: false)),
      (page) {
        // Prepend older messages before existing list (tepaga qo'shish)
        final merged = [...page.messages, ...cur.messages];
        emit(cur.copyWith(
          messages: merged,
          hasOlderMessages: page.hasMore,
          oldestMessageId: page.oldestId,
          isLoadingMore: false,
        ));
      },
    );
  }

  Future<void> _connectWs(int roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    if (token.isNotEmpty) {
      wsService.connect(roomId, token);
      add(const ChatRoomWsConnectRequested());
    }
  }

  Future<void> _onSendMessage(
    ChatRoomMessageSent event,
    Emitter<ChatRoomState> emit,
  ) async {
    final cur = state;
    if (cur is! ChatRoomLoaded) return;

    final replyTo = cur.replyToMessage;

    // Optimistic message
    final optimistic = ChatMessageEntity(
      id: -DateTime.now().millisecondsSinceEpoch,
      messageType: 'text',
      text: event.text,
      isMine: true,
      replyTo: replyTo != null
          ? ChatMessageReply(
              id: replyTo.id,
              text: replyTo.text,
              messageType: replyTo.messageType,
              isMine: replyTo.isMine,
            )
          : null,
      createdAt: DateTime.now().toIso8601String(),
    );
    // Clear reply immediately on send; optimistic message IS the indicator (no spinner)
    emit(cur.copyWith(
      messages: [...cur.messages, optimistic],
      isSending: false,
      replyToMessage: null,
    ));

    final result = await sendMessage(
      roomId: cur.roomId,
      text: event.text,
      replyToId: replyTo?.id,
    );
    result.fold(
      (f) {
        final filtered = cur.messages.where((m) => m.id != optimistic.id).toList();
        emit(cur.copyWith(messages: filtered, isSending: false, sendError: f.message));
      },
      (msg) {
        // Suppress the WS echo for this sent message
        _suppressedWsIds.add(msg.id);
        // Remove BOTH the optimistic AND any WS-echo duplicate, then add the
        // authoritative API response once.
        final latest = state is ChatRoomLoaded ? state as ChatRoomLoaded : cur;
        final deduped = latest.messages
            .where((m) => m.id != optimistic.id && m.id != msg.id)
            .toList()
          ..add(msg);
        emit(latest.copyWith(messages: deduped, isSending: false));
      },
    );
  }

  Future<void> _onSendMedia(
    ChatRoomMediaSent event,
    Emitter<ChatRoomState> emit,
  ) async {
    final cur = state;
    if (cur is! ChatRoomLoaded) return;

    final replyTo = cur.replyToMessage;
    final optimistic = ChatMessageEntity(
      id: -DateTime.now().millisecondsSinceEpoch,
      messageType: event.messageType,
      text: '',
      isMine: true,
      attachments: [
        ChatAttachment(url: '', fileType: event.messageType, fileName: event.fileName),
      ],
      replyTo: replyTo != null
          ? ChatMessageReply(
              id: replyTo.id,
              text: replyTo.text,
              messageType: replyTo.messageType,
              isMine: replyTo.isMine,
            )
          : null,
      createdAt: DateTime.now().toIso8601String(),
    );

    emit(cur.copyWith(
      messages: [...cur.messages, optimistic],
      isSending: true,
      replyToMessage: null,
    ));

    final result = await sendMediaMessage(
      roomId: cur.roomId,
      bytes: event.bytes,
      fileName: event.fileName,
      mimeType: event.mimeType,
      messageType: event.messageType,
      replyToId: replyTo?.id,
    );

    result.fold(
      (f) {
        final latest = state is ChatRoomLoaded ? state as ChatRoomLoaded : cur;
        final filtered = latest.messages.where((m) => m.id != optimistic.id).toList();
        emit(latest.copyWith(messages: filtered, isSending: false, sendError: f.message));
      },
      (msg) {
        _suppressedWsIds.add(msg.id);
        final latest = state is ChatRoomLoaded ? state as ChatRoomLoaded : cur;
        final deduped = latest.messages
            .where((m) => m.id != optimistic.id && m.id != msg.id)
            .toList()
          ..add(msg);
        emit(latest.copyWith(messages: deduped, isSending: false));
      },
    );
  }

  void _onReplySet(ChatRoomReplySet event, Emitter<ChatRoomState> emit) {
    final cur = state;
    if (cur is! ChatRoomLoaded) return;
    emit(cur.copyWith(replyToMessage: event.message));
  }

  void _onReplyCanceled(ChatRoomReplyCanceled event, Emitter<ChatRoomState> emit) {
    final cur = state;
    if (cur is! ChatRoomLoaded) return;
    emit(cur.copyWith(replyToMessage: null));
  }

  Future<void> _onSendRecommendation(
    ChatRoomRecommendationSent event,
    Emitter<ChatRoomState> emit,
  ) async {
    final cur = state;
    if (cur is! ChatRoomLoaded) return;

    emit(cur.copyWith(isSending: true));
    final result = await sendRecommendation(
      roomId: cur.roomId,
      productIds: event.productIds,
      leadId: event.leadId,
    );
    result.fold(
      (f) => emit(cur.copyWith(isSending: false, sendError: f.message)),
      (msg) => emit(cur.copyWith(messages: [...cur.messages, msg], isSending: false)),
    );
  }

  Future<void> _onSearchProducts(
    ChatRoomProductsSearched event,
    Emitter<ChatRoomState> emit,
  ) async {
    final cur = state;
    if (cur is! ChatRoomLoaded) return;
    emit(cur.copyWith(
      productsLoading: true,
      products: [],
      productsPage: 1,
      productsQuery: event.query,
    ));

    final result = await searchProducts(event.query, page: 1);
    result.fold(
      (f) => emit(cur.copyWith(productsLoading: false)),
      (page) => emit(cur.copyWith(
        productsLoading: false,
        products: page.products,
        productsHasMore: page.hasMore,
        productsPage: 1,
        productsQuery: event.query,
      )),
    );
  }

  Future<void> _onLoadMoreProducts(
    ChatRoomProductsLoadMore event,
    Emitter<ChatRoomState> emit,
  ) async {
    final cur = state;
    if (cur is! ChatRoomLoaded || !cur.productsHasMore || cur.productsLoading) return;
    final nextPage = cur.productsPage + 1;
    emit(cur.copyWith(productsLoading: true));

    final result = await searchProducts(cur.productsQuery, page: nextPage);
    result.fold(
      (f) => emit(cur.copyWith(productsLoading: false)),
      (page) => emit(cur.copyWith(
        productsLoading: false,
        products: [...cur.products, ...page.products],
        productsHasMore: page.hasMore,
        productsPage: nextPage,
      )),
    );
  }

  Future<void> _onWsConnect(
    ChatRoomWsConnectRequested event,
    Emitter<ChatRoomState> emit,
  ) async {
    await emit.onEach(
      wsService.events,
      onData: (data) => add(_ChatRoomWsMessageReceived(data)),
    );
  }

  void _onWsMessage(_ChatRoomWsMessageReceived event, Emitter<ChatRoomState> emit) {
    final cur = state;
    if (cur is! ChatRoomLoaded) return;

    final data = event.data;
    final type = data['type']?.toString();

    // Online/offline presence event
    if (type == 'user_status' || type == 'online_status' || type == 'presence') {
      final online = data['is_online'] as bool?
          ?? data['online'] as bool?
          ?? data['status']?.toString() == 'online';
      emit(cur.copyWith(isOnline: online));
      return;
    }

    // Real-time read receipt — mark our sent messages as read
    if (type == 'messages_read' || type == 'message_read' ||
        type == 'read_receipt' || type == 'read') {
      final ids = <int>{};
      final msgIds = data['message_ids'];
      if (msgIds is List) {
        for (final id in msgIds) {
          if (id is int) ids.add(id);
        }
      }
      final msgId = data['message_id'];
      if (msgId is int) ids.add(msgId);
      final lastReadId = data['last_read_id'];
      if (lastReadId is int) {
        for (final m in cur.messages) {
          if (m.isMine && m.id <= lastReadId) ids.add(m.id);
        }
      }
      if (ids.isNotEmpty) {
        final updated = cur.messages.map((m) {
          return (m.isMine && ids.contains(m.id)) ? m.copyWith(isRead: true) : m;
        }).toList();
        emit(cur.copyWith(messages: updated));
      }
      return;
    }

    // Handle both { "type": "new_message", "message": {...} } and direct message format
    final msgData = data['message'] as Map<String, dynamic>? ??
        (data.containsKey('id') ? data : null);
    if (msgData == null) return;

    final msg = ChatMessageModel.fromJson(msgData);

    // Suppress WS echo for messages we just sent via API (API response arrived first)
    if (_suppressedWsIds.contains(msg.id)) {
      _suppressedWsIds.remove(msg.id);
      return;
    }

    // Suppress WS echo when it arrives BEFORE the API response:
    if (msg.isMine && cur.messages.any((m) => m.id < 0)) return;

    // Skip if already in list (e.g., duplicate WS event)
    if (cur.messages.any((m) => m.id == msg.id)) return;

    emit(cur.copyWith(messages: [...cur.messages, msg]));
  }

  @override
  Future<void> close() {
    wsService.disconnect();
    return super.close();
  }
}
