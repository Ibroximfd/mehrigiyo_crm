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
  final SendRecommendationUseCase sendRecommendation;
  final SearchProductsUseCase searchProducts;
  final HasMoreProductsUseCase hasMoreProducts;
  final ChatWsService wsService;

  ChatRoomBloc({
    required this.getMessages,
    required this.sendMessage,
    required this.sendRecommendation,
    required this.searchProducts,
    required this.hasMoreProducts,
    required this.wsService,
  }) : super(ChatRoomInitial()) {
    on<ChatRoomLoadRequested>(_onLoad);
    on<ChatRoomMessageSent>(_onSendMessage);
    on<ChatRoomRecommendationSent>(_onSendRecommendation);
    on<ChatRoomProductsSearched>(_onSearchProducts);
    on<ChatRoomProductsLoadMore>(_onLoadMoreProducts);
    on<ChatRoomWsConnectRequested>(_onWsConnect, transformer: droppable());
    on<_ChatRoomWsMessageReceived>(_onWsMessage);
  }

  Future<void> _onLoad(ChatRoomLoadRequested event, Emitter<ChatRoomState> emit) async {
    emit(ChatRoomLoading());
    final result = await getMessages(event.roomId);
    result.fold(
      (f) => emit(ChatRoomError(f.message)),
      (messages) {
        emit(ChatRoomLoaded(roomId: event.roomId, messages: messages));
        _connectWs(event.roomId);
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

    // Optimistic message
    final optimistic = ChatMessageEntity(
      id: -DateTime.now().millisecondsSinceEpoch,
      messageType: 'text',
      text: event.text,
      isMine: true,
      createdAt: DateTime.now().toIso8601String(),
    );
    emit(cur.copyWith(messages: [...cur.messages, optimistic], isSending: true));

    final result = await sendMessage(roomId: cur.roomId, text: event.text);
    result.fold(
      (f) {
        // Remove optimistic on failure
        final filtered = cur.messages.where((m) => m.id != optimistic.id).toList();
        emit(cur.copyWith(messages: filtered, isSending: false, sendError: f.message));
      },
      (msg) {
        final updated = cur.messages
            .where((m) => m.id != optimistic.id)
            .toList()
          ..add(msg);
        emit(cur.copyWith(messages: updated, isSending: false));
      },
    );
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
    emit(cur.copyWith(productsLoading: true, products: [], productsPage: 1, productsQuery: event.query));
    final result = await searchProducts(event.query, page: 1);
    result.fold(
      (_) => emit(cur.copyWith(productsLoading: false)),
      (list) async {
        final moreResult = await hasMoreProducts(event.query, 1);
        final hasMore = moreResult.fold((_) => false, (v) => v);
        emit(cur.copyWith(
          productsLoading: false,
          products: list,
          productsHasMore: hasMore,
          productsPage: 1,
          productsQuery: event.query,
        ));
      },
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
      (_) => emit(cur.copyWith(productsLoading: false)),
      (more) async {
        final moreResult = await hasMoreProducts(cur.productsQuery, nextPage);
        final hasMore = moreResult.fold((_) => false, (v) => v);
        emit(cur.copyWith(
          productsLoading: false,
          products: [...cur.products, ...more],
          productsHasMore: hasMore,
          productsPage: nextPage,
        ));
      },
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
    // Handle both { "type": "new_message", "message": {...} } and direct message format
    final msgData = data['message'] as Map<String, dynamic>? ??
        (data.containsKey('id') ? data : null);
    if (msgData == null) return;

    final msg = ChatMessageModel.fromJson(msgData);
    // Skip if already in list (e.g., echo from own send)
    if (cur.messages.any((m) => m.id == msg.id)) return;

    emit(cur.copyWith(messages: [...cur.messages, msg]));
  }

  @override
  Future<void> close() {
    wsService.disconnect();
    return super.close();
  }
}
