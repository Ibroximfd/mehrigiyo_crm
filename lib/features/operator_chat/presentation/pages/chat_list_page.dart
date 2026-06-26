import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/di_setup.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../operator_order/presentation/bloc/operator_order_bloc.dart';
import '../../../operator_order/presentation/widgets/create_operator_order_dialog.dart';
import '../../domain/usecases/chat_usecases.dart';
import '../../domain/entities/chat_entities.dart';
import '../bloc/chat_list_bloc.dart';
import '../widgets/create_room_dialog.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  GoRouter? _router;
  String? _lastLocation;

  @override
  void initState() {
    super.initState();
    // The global bloc is normally loaded on login; guard covers the case where
    // the page is opened before that ever happened (e.g. deep link / refresh).
    final bloc = context.read<ChatListBloc>();
    if (bloc.state is ChatListInitial) {
      bloc.add(const ChatListLoadRequested());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router?.routerDelegate.removeListener(_onRouteChange);
    _router = GoRouter.of(context);
    _router!.routerDelegate.addListener(_onRouteChange);
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouteChange);
    super.dispose();
  }

  void _onRouteChange() {
    final loc = _router?.routerDelegate.currentConfiguration.uri.path ?? '';
    final prev = _lastLocation ?? '';
    _lastLocation = loc;
    // Reload when returning from a chat room (path with numeric id) to chat list
    final wasChatRoom = RegExp(r'/chat/\d+').hasMatch(prev);
    final isChatRoom = RegExp(r'/chat/\d+').hasMatch(loc);
    if (wasChatRoom && !isChatRoom && mounted) {
      context.read<ChatListBloc>().add(const ChatListLoadRequested());
    }
  }

  void _showCreateDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => BlocProvider.value(
        value: ctx.read<ChatListBloc>(),
        child: const CreateRoomDialog(),
      ),
    );
  }

  void _showCreateOrderDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<OperatorOrderBloc>()),
          RepositoryProvider.value(value: getIt<SearchProductsUseCase>()),
        ],
        child: const CreateOperatorOrderDialog(editablePhone: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: BlocConsumer<ChatListBloc, ChatListState>(
        listenWhen: (_, s) => s is ChatRoomCreated || s is ChatListCreateError,
        listener: (ctx, state) {
          if (state is ChatRoomCreated) {
            ctx.read<ChatListBloc>().add(ChatListRoomRead(state.room.id));
            ctx.push(
              RouteNames.sellerChatRoom(state.room.id),
              extra: {
                'name': state.room.participantName,
                'phone': state.room.participantPhone,
                'avatarUrl': state.room.avatarUrl,
                'leadId': state.room.leadId,
              },
            );
          } else if (state is ChatListCreateError) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ));
          }
        },
        builder: (ctx, state) {
          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  onNewChat: () => _showCreateDialog(ctx),
                  onNewOrder: () => _showCreateOrderDialog(ctx),
                  onRefresh: () =>
                      ctx.read<ChatListBloc>().add(const ChatListLoadRequested()),
                ),
                Expanded(child: _Body(state: state)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onNewChat;
  final VoidCallback onNewOrder;
  final VoidCallback onRefresh;
  const _Header({
    required this.onNewChat,
    required this.onNewOrder,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      color: Colors.white,
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chatlar',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Mijozlar bilan muloqot',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            tooltip: 'Yangilash',
          ),
          const SizedBox(width: 4),
          OutlinedButton.icon(
            onPressed: onNewOrder,
            icon: const Icon(Icons.shopping_cart_outlined, size: 18),
            label: const Text('Zakaz qilish'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: onNewChat,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Yangi chat'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final ChatListState state;
  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state is ChatListLoading || state is ChatListCreating || state is ChatListInitial) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (state is ChatListError) {
      return _ErrorView(message: (state as ChatListError).message);
    }

    final rooms = state is ChatListLoaded
        ? (state as ChatListLoaded).rooms.cast<ChatRoomEntity>()
        : <ChatRoomEntity>[];

    if (rooms.isEmpty) return const _EmptyView();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async =>
          context.read<ChatListBloc>().add(const ChatListLoadRequested()),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: rooms.length,
        separatorBuilder: (_, i) => const Divider(height: 1, indent: 76),
        itemBuilder: (_, i) => _RoomTile(room: rooms[i]),
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final ChatRoomEntity room;
  const _RoomTile({required this.room});

  @override
  Widget build(BuildContext context) {
    final name = room.participantName.isNotEmpty
        ? room.participantName
        : room.participantPhone;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final hasUnread = room.unreadCount > 0;

    // Last message preview
    String subtitle;
    if (room.lastMessage != null && room.lastMessage!.isNotEmpty) {
      subtitle = room.lastMessageIsMine == true
          ? 'Siz: ${room.lastMessage!}'
          : room.lastMessage!;
    } else {
      subtitle = room.participantPhone;
    }

    return InkWell(
      onTap: () {
        // Zero out unread immediately — before navigation, context is guaranteed valid here
        context.read<ChatListBloc>().add(ChatListRoomRead(room.id));
        context.push(
          RouteNames.sellerChatRoom(room.id),
          extra: {
            'name': room.participantName,
            'phone': room.participantPhone,
            'avatarUrl': room.avatarUrl,
            'leadId': room.leadId,
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar
            _Avatar(
              avatarUrl: room.avatarUrl,
              initial: initial,
              hasUnread: hasUnread,
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontWeight:
                                hasUnread ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 15,
                            color: const Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (room.lastMessageAt != null)
                        Text(
                          _fmtDate(room.lastMessageAt!),
                          style: TextStyle(
                            fontSize: 11,
                            color: hasUnread
                                ? AppColors.primary
                                : const Color(0xFF94A3B8),
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUnread
                                ? const Color(0xFF374151)
                                : const Color(0xFF94A3B8),
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            room.unreadCount > 99
                                ? '99+'
                                : '${room.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day}.${dt.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String initial;
  final bool hasUnread;
  const _Avatar({this.avatarUrl, required this.initial, required this.hasUnread});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.primaryLight,
          backgroundImage:
              avatarUrl != null && avatarUrl!.isNotEmpty ? NetworkImage(avatarUrl!) : null,
          // Web blocks cross-origin canvas decode (CORS) → swallow the failure
          // so it doesn't spam the console; the initial letter stays as fallback.
          onBackgroundImageError:
              avatarUrl != null && avatarUrl!.isNotEmpty ? (_, _) {} : null,
          child: avatarUrl == null || avatarUrl!.isEmpty
              ? Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                )
              : null,
        ),
        if (hasUnread)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryLight, shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chatlar yo\'q',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mijoz bilan chat boshlash uchun\n"Yangi chat" tugmasini bosing',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () =>
                context.read<ChatListBloc>().add(const ChatListLoadRequested()),
            child: const Text('Qayta urinish'),
          ),
        ],
      ),
    );
  }
}
