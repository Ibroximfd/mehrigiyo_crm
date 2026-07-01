import 'dart:async';
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
import '../bloc/audio/audio_bloc.dart';
import '../bloc/chat_list_bloc.dart';
import '../bloc/chat_room_bloc.dart';
import '../widgets/chat_avatar.dart';
import '../widgets/create_room_dialog.dart';
import 'chat_room_page.dart';

/// Breakpoint above which the chat switches to a two-panel (master-detail)
/// Telegram-desktop layout; below it the list is full-screen and taps push.
const double _kWideBreakpoint = 900;

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  GoRouter? _router;
  String? _lastLocation;

  // Selected room for the right-hand panel (wide layout only).
  ChatRoomEntity? _selectedRoom;

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

  bool _isWide(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= _kWideBreakpoint;

  void _openRoom(BuildContext ctx, ChatRoomEntity room) {
    // Zero out unread immediately — context is guaranteed valid here.
    ctx.read<ChatListBloc>().add(ChatListRoomRead(room.id));
    if (_isWide(ctx)) {
      setState(() => _selectedRoom = room);
    } else {
      ctx.push(
        RouteNames.sellerChatRoom(room.id),
        extra: {
          'name': room.participantName,
          'phone': room.participantPhone,
          'avatarUrl': room.avatarUrl,
          'leadId': room.leadId,
        },
      );
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
      backgroundColor: Colors.white,
      body: BlocListener<ChatListBloc, ChatListState>(
        listenWhen: (_, s) => s is ChatRoomCreated || s is ChatListCreateError,
        listener: (ctx, state) {
          if (state is ChatRoomCreated) {
            _openRoom(ctx, state.room);
          } else if (state is ChatListCreateError) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ));
          }
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final wide = constraints.maxWidth >= _kWideBreakpoint;
              final panel = ChatListPanel(
                selectedRoomId: wide ? _selectedRoom?.id : null,
                onSelect: (room) => _openRoom(ctx, room),
                onNewChat: () => _showCreateDialog(ctx),
                onNewOrder: () => _showCreateOrderDialog(ctx),
                onRefresh: () =>
                    ctx.read<ChatListBloc>().add(const ChatListLoadRequested()),
              );

              if (!wide) return panel;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 400, child: panel),
                  const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE7EDEA)),
                  Expanded(
                    child: _selectedRoom == null
                        ? const _NoRoomSelected()
                        : _EmbeddedRoom(
                            key: ValueKey(_selectedRoom!.id),
                            room: _selectedRoom!,
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Right-hand panel host: gives the selected room its own bloc scope and renders
/// [ChatRoomPage] in embedded mode (no back button / own Scaffold chrome tweaks).
class _EmbeddedRoom extends StatelessWidget {
  final ChatRoomEntity room;
  const _EmbeddedRoom({required super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ChatRoomBloc>()),
        BlocProvider(create: (_) => AudioBloc()),
      ],
      child: ChatRoomPage(
        roomId: room.id,
        participantName: room.participantName,
        participantPhone: room.participantPhone,
        avatarUrl: room.avatarUrl,
        leadId: room.leadId,
        embedded: true,
      ),
    );
  }
}

class _NoRoomSelected extends StatelessWidget {
  const _NoRoomSelected();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEAF3EE),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Suhbatni tanlang',
          style: TextStyle(fontSize: 13, color: Color(0xFF4D7068)),
        ),
      ),
    );
  }
}

// ─── Left panel (list + search) ───────────────────────────────────────────────

/// Owns the search query + debounce locally so typing rebuilds only this panel,
/// never the embedded room on the right.
class ChatListPanel extends StatefulWidget {
  final int? selectedRoomId;
  final ValueChanged<ChatRoomEntity> onSelect;
  final VoidCallback onNewChat;
  final VoidCallback onNewOrder;
  final VoidCallback onRefresh;

  const ChatListPanel({
    super.key,
    required this.selectedRoomId,
    required this.onSelect,
    required this.onNewChat,
    required this.onNewOrder,
    required this.onRefresh,
  });

  @override
  State<ChatListPanel> createState() => _ChatListPanelState();
}

class _ChatListPanelState extends State<ChatListPanel> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = value.trim().toLowerCase());
    });
  }

  List<ChatRoomEntity> _filter(List<ChatRoomEntity> rooms) {
    if (_query.isEmpty) return rooms;
    return rooms
        .where((r) =>
            r.participantName.toLowerCase().contains(_query) ||
            r.participantPhone.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PanelHeader(
          onNewChat: widget.onNewChat,
          onNewOrder: widget.onNewOrder,
          onRefresh: widget.onRefresh,
        ),
        _SearchBar(controller: _searchCtrl, onChanged: _onSearchChanged),
        Expanded(
          child: BlocBuilder<ChatListBloc, ChatListState>(
            builder: (ctx, state) {
              if (state is ChatListLoading ||
                  state is ChatListCreating ||
                  state is ChatListInitial) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (state is ChatListError) {
                return _ErrorView(message: state.message);
              }

              final all = state is ChatListLoaded
                  ? state.rooms
                  : const <ChatRoomEntity>[];
              if (all.isEmpty) return const _EmptyView();

              final rooms = _filter(all);
              if (rooms.isEmpty) return const _NoResults();

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ctx
                    .read<ChatListBloc>()
                    .add(const ChatListLoadRequested()),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: rooms.length,
                  itemBuilder: (_, i) => _RoomTile(
                    room: rooms[i],
                    selected: rooms[i].id == widget.selectedRoomId,
                    onTap: () => widget.onSelect(rooms[i]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final VoidCallback onNewChat;
  final VoidCallback onNewOrder;
  final VoidCallback onRefresh;
  const _PanelHeader({
    required this.onNewChat,
    required this.onNewOrder,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Chatlar',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
            ),
          ),
          _RoundIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Yangilash',
            onTap: onRefresh,
          ),
          _RoundIconButton(
            icon: Icons.shopping_cart_outlined,
            tooltip: 'Zakaz qilish',
            onTap: onNewOrder,
          ),
          _RoundIconButton(
            icon: Icons.edit_square,
            tooltip: 'Yangi chat',
            color: AppColors.primary,
            onTap: onNewChat,
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: 22, color: color ?? const Color(0xFF64748B)),
      splashRadius: 22,
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Qidirish',
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 20, color: Color(0xFF94A3B8)),
          filled: true,
          fillColor: const Color(0xFFF0F2F5),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
      ),
    );
  }
}

// ─── Room tile ────────────────────────────────────────────────────────────────

class _RoomTile extends StatelessWidget {
  final ChatRoomEntity room;
  final bool selected;
  final VoidCallback onTap;
  const _RoomTile({
    required this.room,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = room.participantName.isNotEmpty
        ? room.participantName
        : room.participantPhone;
    final hasUnread = room.unreadCount > 0;

    final String subtitle;
    if (room.lastMessage != null && room.lastMessage!.isNotEmpty) {
      subtitle = room.lastMessageIsMine == true
          ? 'Siz: ${room.lastMessage!}'
          : room.lastMessage!;
    } else {
      subtitle = room.participantPhone;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                ChatAvatar(avatarUrl: room.avatarUrl, name: name, radius: 26),
                const SizedBox(width: 12),
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
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 15,
                                color: const Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (room.lastMessageAt != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
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
                          if (hasUnread) _UnreadBadge(count: room.unreadCount),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

class _UnreadBadge extends StatelessWidget {
  final int count;
  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── States ───────────────────────────────────────────────────────────────────

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Hech narsa topilmadi',
        style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
      ),
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
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chatlar yo\'q',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B)),
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
          const Icon(Icons.error_outline_rounded,
              size: 48, color: AppColors.error),
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
