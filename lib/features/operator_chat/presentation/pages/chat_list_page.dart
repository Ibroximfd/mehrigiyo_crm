import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/chat_list_bloc.dart';
import '../widgets/create_room_dialog.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: BlocConsumer<ChatListBloc, ChatListState>(
        listenWhen: (_, s) => s is ChatRoomCreated || s is ChatListCreateError,
        listener: (ctx, state) {
          if (state is ChatRoomCreated) {
            ctx.push(
            RouteNames.sellerChatRoom(state.room.id),
            extra: {
              'name': state.room.participantName,
              'phone': state.room.participantPhone,
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
                ),
                Expanded(child: _Body(state: state)),
              ],
            ),
          );
        },
      ),
    );
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
}

class _Header extends StatelessWidget {
  final VoidCallback onNewChat;
  const _Header({required this.onNewChat});

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
      return const Center(child: CircularProgressIndicator());
    }
    if (state is ChatListError) {
      return _ErrorView(message: (state as ChatListError).message);
    }

    final loadedRooms =
        state is ChatListLoaded ? (state as ChatListLoaded).rooms : const [];

    if (loadedRooms.isEmpty) {
      return const _EmptyView();
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ChatListBloc>().add(const ChatListLoadRequested());
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: loadedRooms.length,
        separatorBuilder: (_, i) => const Divider(height: 1, indent: 72),
        itemBuilder: (_, i) => _RoomTile(room: loadedRooms[i]),
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final dynamic room;
  const _RoomTile({required this.room});

  @override
  Widget build(BuildContext context) {
    final name = room.participantName as String;
    final phone = room.participantPhone as String;
    final lastMsg = room.lastMessage as String?;
    final time = room.lastMessageAt as String?;
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primaryLight,
        child: Text(
          letter,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      title: Text(
        name.isNotEmpty ? name : phone,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        lastMsg ?? phone,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
      ),
      trailing: time != null
          ? Text(
              _fmtDate(time),
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            )
          : null,
      onTap: () => context.push(
        RouteNames.sellerChatRoom(room.id as int),
        extra: {
          'name': room.participantName as String,
          'phone': room.participantPhone as String,
          'leadId': room.leadId,
        },
      ),
    );
  }

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m';
      }
      return '${dt.day}.${dt.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
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
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chatlar yo\'q',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
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
