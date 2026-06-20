import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/di_setup.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../operator_chat/domain/usecases/chat_usecases.dart';
import '../../../operator_order/presentation/bloc/operator_order_bloc.dart';
import '../../../operator_order/presentation/widgets/create_operator_order_dialog.dart';
import '../bloc/chat_room_bloc.dart';
import '../widgets/message_bubble.dart';
import '../widgets/recommend_products_sheet.dart';

class ChatRoomPage extends StatefulWidget {
  final int roomId;
  final String? participantName;
  final String? participantPhone;
  final int? leadId;

  const ChatRoomPage({
    super.key,
    required this.roomId,
    this.participantName,
    this.participantPhone,
    this.leadId,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _scrollCtrl = ScrollController();
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    context.read<ChatRoomBloc>().add(ChatRoomLoadRequested(widget.roomId));
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    context.read<ChatRoomBloc>().add(ChatRoomMessageSent(text));
    _scrollToBottom();
  }

  void _openCreateOrder(BuildContext ctx, int recommendationId) {
    showDialog(
      context: ctx,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<OperatorOrderBloc>()),
          RepositoryProvider.value(value: getIt<SearchProductsUseCase>()),
          RepositoryProvider.value(value: getIt<HasMoreProductsUseCase>()),
        ],
        child: CreateOperatorOrderDialog(
          phone: widget.participantPhone ?? '',
          recommendationId: recommendationId,
          leadId: widget.leadId,
        ),
      ),
    );
  }

  void _openRecommend(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: ctx.read<ChatRoomBloc>(),
        child: RecommendProductsSheet(leadId: widget.leadId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF7),
      appBar: AppBar(
        backgroundColor: AppColors.sidebarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.accent.withValues(alpha: 0.25),
              child: Text(
                widget.participantName?.isNotEmpty == true
                    ? widget.participantName![0].toUpperCase()
                    : 'M',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.participantName ?? 'Mijoz',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Online',
                    style: TextStyle(fontSize: 11, color: AppColors.accent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: BlocConsumer<ChatRoomBloc, ChatRoomState>(
        listenWhen: (p, s) {
          if (p is ChatRoomLoaded && s is ChatRoomLoaded) {
            return s.messages.length > p.messages.length || s.sendError != null;
          }
          return false;
        },
        listener: (ctx, state) {
          if (state is ChatRoomLoaded) {
            if (state.sendError != null) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(state.sendError!),
                backgroundColor: AppColors.error,
              ));
            } else {
              _scrollToBottom();
            }
          }
        },
        builder: (ctx, state) {
          if (state is ChatRoomLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ChatRoomError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                  const SizedBox(height: 8),
                  Text(state.message, style: const TextStyle(color: Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ctx
                        .read<ChatRoomBloc>()
                        .add(ChatRoomLoadRequested(widget.roomId)),
                    child: const Text('Qayta urinish'),
                  ),
                ],
              ),
            );
          }
          if (state is! ChatRoomLoaded) return const SizedBox();

          return Column(
            children: [
              // Messages
              Expanded(
                child: state.messages.isEmpty
                    ? const _EmptyChat()
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: state.messages.length,
                        itemBuilder: (_, i) {
                          final msg = state.messages[i];
                          return MessageBubble(
                            message: msg,
                            onCreateOrder: msg.isRecommendation && msg.recommendation != null
                                ? () => _openCreateOrder(ctx, msg.recommendation!.id)
                                : null,
                          );
                        },
                      ),
              ),
              // Input area
              _InputBar(
                textCtrl: _textCtrl,
                focusNode: _focusNode,
                isSending: state.isSending,
                onSend: _sendMessage,
                onRecommend: () => _openRecommend(ctx),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController textCtrl;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onRecommend;

  const _InputBar({
    required this.textCtrl,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
    required this.onRecommend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Recommend button
          IconButton(
            onPressed: isSending ? null : onRecommend,
            icon: const Icon(Icons.recommend_rounded),
            tooltip: 'Mahsulot tavsiya qilish',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          // Text input
          Expanded(
            child: TextField(
              controller: textCtrl,
              focusNode: focusNode,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Xabar yozing...',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            child: isSending
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    onPressed: onSend,
                    icon: const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_outlined, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          const Text(
            'Hali xabarlar yo\'q',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mijozga xabar yozing yoki\nmahsulot tavsiya qiling',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
