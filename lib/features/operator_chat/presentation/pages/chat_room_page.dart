import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:web/web.dart' as web;
import '../../../../core/di/di_setup.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bitrix_call_button.dart';
import '../../../operator_chat/domain/usecases/chat_usecases.dart';
import '../../../operator_order/presentation/bloc/operator_order_bloc.dart';
import '../../../operator_order/presentation/widgets/create_operator_order_dialog.dart';
import '../../domain/entities/chat_entities.dart';
import '../bloc/chat_room_bloc.dart';
import '../widgets/message_bubble.dart';
import '../widgets/recommend_products_sheet.dart';

// ─── Web voice recorder (uses browser MediaRecorder API directly — no plugin) ──

class _WebVoiceRecorder {
  web.MediaRecorder? _recorder;
  final _chunks = <web.Blob>[];
  web.MediaStream? _stream;

  Future<bool> start() async {
    try {
      _stream = await web.window.navigator.mediaDevices
          .getUserMedia(web.MediaStreamConstraints(audio: true.toJS))
          .toDart;
      _chunks.clear();
      _recorder = web.MediaRecorder(_stream!);
      _recorder!.addEventListener('dataavailable', ((web.Event e) {
        final be = e as web.BlobEvent;
        if (be.data.size > 0) _chunks.add(be.data);
      }).toJS);
      _recorder!.start();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<int>?> stop() async {
    if (_recorder == null) return null;
    final completer = Completer<List<int>?>();

    _recorder!.addEventListener('stop', ((web.Event _) {
      Future(() async {
        try {
          final parts = _chunks.map((b) => b as JSAny).toList().toJS;
          final blob = web.Blob(parts, web.BlobPropertyBag(type: 'audio/webm'));
          final url = web.URL.createObjectURL(blob);
          final bytes = await _fetchBlobBytes(url);
          web.URL.revokeObjectURL(url);
          completer.complete(bytes);
        } catch (_) {
          completer.complete(null);
        }
        _stopTracks();
      });
    }).toJS);

    _recorder!.stop();
    _recorder = null;
    return completer.future;
  }

  void cancel() {
    try {
      _recorder?.stop();
    } catch (_) {}
    _recorder = null;
    _chunks.clear();
    _stopTracks();
  }

  void _stopTracks() {
    try {
      for (final t in (_stream?.getTracks().toDart ?? <web.MediaStreamTrack>[])) {
        t.stop();
      }
    } catch (_) {}
    _stream = null;
  }
}

// Fetches raw bytes from a blob:// URL using the browser's global fetch().
@JS('fetch')
external JSPromise<web.Response> _jsFetch(JSString url);

Future<List<int>?> _fetchBlobBytes(String blobUrl) async {
  try {
    final response = await _jsFetch(blobUrl.toJS).toDart;
    final buffer = await response.arrayBuffer().toDart;
    return buffer.toDart.asUint8List();
  } catch (_) {
    return null;
  }
}

String _extToMime(String ext) {
  switch (ext.toLowerCase()) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'mp4':
      return 'video/mp4';
    case 'mov':
      return 'video/quicktime';
    case 'mp3':
      return 'audio/mpeg';
    case 'wav':
      return 'audio/wav';
    case 'ogg':
      return 'audio/ogg';
    case 'pdf':
      return 'application/pdf';
    default:
      return 'application/octet-stream';
  }
}

String _mimeToType(String mime) {
  if (mime.startsWith('image/')) return 'image';
  if (mime.startsWith('video/')) return 'video';
  if (mime.startsWith('audio/')) return 'audio';
  return 'file';
}

// ─── Page ─────────────────────────────────────────────────────────────────────

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
  final _voiceRecorder = _WebVoiceRecorder();

  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    context.read<ChatRoomBloc>().add(ChatRoomLoadRequested(widget.roomId));
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.hasClients && _scrollCtrl.position.pixels <= 150) {
      final s = context.read<ChatRoomBloc>().state;
      if (s is ChatRoomLoaded && s.hasOlderMessages && !s.isLoadingMore) {
        context.read<ChatRoomBloc>().add(const ChatRoomLoadMoreRequested());
      }
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    _focusNode.dispose();
    _recordingTimer?.cancel();
    _voiceRecorder.cancel();
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

  Future<void> _pickAndSendFile() async {
    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = 'image/*,video/*,audio/*,application/pdf,.doc,.docx,.xls,.xlsx,.txt'
      ..style.display = 'none';
    web.document.body!.append(input);

    final done = Completer<void>();

    input.addEventListener('change', ((web.Event _) {
      _readWebFile(input).then((_) {
        input.remove();
        if (!done.isCompleted) done.complete();
      });
    }).toJS);

    input.addEventListener('cancel', ((web.Event _) {
      input.remove();
      if (!done.isCompleted) done.complete();
    }).toJS);

    input.click();
    await done.future;
  }

  Future<void> _readWebFile(web.HTMLInputElement input) async {
    final files = input.files;
    if (files == null || files.length == 0) return;
    final file = files.item(0)!;

    final reader = web.FileReader();
    final completer = Completer<JSArrayBuffer?>();

    reader.addEventListener('load', ((web.Event _) {
      completer.complete(reader.result as JSArrayBuffer?);
    }).toJS);
    reader.addEventListener('error', ((web.Event _) {
      completer.complete(null);
    }).toJS);
    reader.readAsArrayBuffer(file);

    final buffer = await completer.future;
    if (buffer == null || !mounted) return;

    final bytes = buffer.toDart.asUint8List();
    if (bytes.isEmpty) return;

    final mimeType = file.type.isNotEmpty
        ? file.type
        : _extToMime(file.name.split('.').last);
    final messageType = _mimeToType(mimeType);

    context.read<ChatRoomBloc>().add(ChatRoomMediaSent(
          bytes: bytes,
          fileName: file.name,
          mimeType: mimeType,
          messageType: messageType,
        ));
    _scrollToBottom();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final started = await _voiceRecorder.start();
    if (!started) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mikrofonga ruxsat berilmadi yoki ulanmagan'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordingSeconds++);
    });
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    setState(() => _isRecording = false);

    final bytes = await _voiceRecorder.stop();
    if (bytes == null || bytes.isEmpty || !mounted) return;

    final ts = DateTime.now().millisecondsSinceEpoch;
    context.read<ChatRoomBloc>().add(ChatRoomMediaSent(
          bytes: Uint8List.fromList(bytes),
          fileName: 'voice_$ts.webm',
          mimeType: 'audio/webm',
          messageType: 'audio',
        ));
    _scrollToBottom();
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _voiceRecorder.cancel();
    if (mounted) setState(() => _isRecording = false);
  }

  void _copyPhone() {
    final phone = widget.participantPhone ?? '';
    if (phone.isEmpty) return;
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Telefon raqami nusxalandi!'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openManualOrder(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<OperatorOrderBloc>()),
          RepositoryProvider.value(value: getIt<SearchProductsUseCase>()),
        ],
        child: CreateOperatorOrderDialog(
          phone: widget.participantPhone ?? '',
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
    final hasName = widget.participantName?.isNotEmpty == true;
    final displayName = hasName
        ? widget.participantName!
        : (widget.participantPhone?.isNotEmpty == true
              ? widget.participantPhone!
              : 'Mijoz');
    final phone = widget.participantPhone ?? '';
    final initial = displayName[0].toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF7),
      appBar: AppBar(
        backgroundColor: AppColors.sidebarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
          color: Colors.white,
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.accent.withValues(alpha: 0.25),
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SelectionArea(
                child: BlocBuilder<ChatRoomBloc, ChatRoomState>(
                  buildWhen: (p, s) =>
                      (p is ChatRoomLoaded) != (s is ChatRoomLoaded) ||
                      (p is ChatRoomLoaded &&
                          s is ChatRoomLoaded &&
                          p.isOnline != s.isOnline),
                  builder: (_, state) {
                    final isOnline = state is ChatRoomLoaded && state.isOnline;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isOnline
                                    ? const Color(0xFF4ADE80)
                                    : Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                fontSize: 11,
                                color: isOnline
                                    ? const Color(0xFF4ADE80)
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                            if (phone.isNotEmpty) ...[
                              Text(
                                '  ·  $phone',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                              GestureDetector(
                                onTap: _copyPhone,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 3),
                                  child: Icon(
                                    Icons.copy_rounded,
                                    size: 10,
                                    color: Colors.white.withValues(alpha: 0.35),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (phone.isNotEmpty) ...[
            BitrixCallButton(phone: phone, size: 40),
            const SizedBox(width: 4),
          ],
          BlocBuilder<ChatRoomBloc, ChatRoomState>(
            buildWhen: (p, s) =>
                (p is ChatRoomLoaded ? p.isSending : false) !=
                (s is ChatRoomLoaded ? s.isSending : false),
            builder: (ctx, state) {
              final isSending = state is ChatRoomLoaded && state.isSending;
              return IconButton(
                onPressed: isSending ? null : () => _openManualOrder(ctx),
                icon: const Icon(Icons.shopping_bag_outlined),
                tooltip: 'Buyurtma yaratish',
                color: Colors.white,
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocConsumer<ChatRoomBloc, ChatRoomState>(
        listenWhen: (p, s) {
          if (s is! ChatRoomLoaded) return false;
          if (p is! ChatRoomLoaded) return true;
          return s.messages.length > p.messages.length || s.sendError != null;
        },
        listener: (ctx, state) {
          if (state is ChatRoomLoaded) {
            if (state.sendError != null) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(state.sendError!),
                  backgroundColor: AppColors.error,
                ),
              );
            } else {
              _scrollToBottom();
            }
          }
        },
        builder: (ctx, state) {
          if (state is ChatRoomLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state is ChatRoomError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ctx.read<ChatRoomBloc>().add(
                      ChatRoomLoadRequested(widget.roomId),
                    ),
                    child: const Text('Qayta urinish'),
                  ),
                ],
              ),
            );
          }
          if (state is! ChatRoomLoaded) return const SizedBox();

          return Column(
            children: [
              // Messages list
              Expanded(
                child: state.messages.isEmpty
                    ? const _EmptyChat()
                    : SelectionArea(
                        child: ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount:
                              state.messages.length +
                              (state.isLoadingMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (state.isLoadingMore && i == 0) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              );
                            }
                            final msgOffset = state.isLoadingMore ? 1 : 0;
                            final msg = state.messages[i - msgOffset];
                            return MessageBubble(
                              message: msg,
                              onReply: () => ctx.read<ChatRoomBloc>().add(
                                ChatRoomReplySet(msg),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              // Reply bar
              if (state.replyToMessage != null)
                _ReplyBar(
                  message: state.replyToMessage!,
                  onCancel: () => ctx.read<ChatRoomBloc>().add(
                    const ChatRoomReplyCanceled(),
                  ),
                ),
              // Recording indicator
              if (_isRecording)
                _RecordingBar(
                  seconds: _recordingSeconds,
                  onCancel: _cancelRecording,
                ),
              // Input
              _InputBar(
                textCtrl: _textCtrl,
                focusNode: _focusNode,
                isSending: state.isSending,
                isRecording: _isRecording,
                onSend: _sendMessage,
                onRecommend: () => _openRecommend(ctx),
                onAttach: _pickAndSendFile,
                onVoiceToggle: _toggleRecording,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Recording indicator bar ──────────────────────────────────────────────────

class _RecordingBar extends StatelessWidget {
  final int seconds;
  final VoidCallback onCancel;
  const _RecordingBar({required this.seconds, required this.onCancel});

  String get _time {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Yozib olinmoqda...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _time,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.red,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded, size: 16),
            label: const Text('Bekor qilish'),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

// ─── Reply bar ────────────────────────────────────────────────────────────────

class _ReplyBar extends StatelessWidget {
  final ChatMessageEntity message;
  final VoidCallback onCancel;
  const _ReplyBar({required this.message, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final preview = message.messageType == 'operator_recommendation'
        ? '📦 Mahsulot tavsiyasi'
        : message.hasMedia
        ? '📎 Media'
        : message.text;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.isMine ? 'Sizning xabaringiz' : 'Javob',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preview,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: const Color(0xFF94A3B8),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController textCtrl;
  final FocusNode focusNode;
  final bool isSending;
  final bool isRecording;
  final VoidCallback onSend;
  final VoidCallback onRecommend;
  final VoidCallback onAttach;
  final VoidCallback onVoiceToggle;

  const _InputBar({
    required this.textCtrl,
    required this.focusNode,
    required this.isSending,
    required this.isRecording,
    required this.onSend,
    required this.onRecommend,
    required this.onAttach,
    required this.onVoiceToggle,
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
          // Recommend
          IconButton(
            onPressed: (isSending || isRecording) ? null : onRecommend,
            icon: const Icon(Icons.recommend_rounded),
            tooltip: 'Mahsulot tavsiya qilish',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          // Attach file
          IconButton(
            onPressed: (isSending || isRecording) ? null : onAttach,
            icon: const Icon(Icons.attach_file_rounded),
            tooltip: 'Fayl biriktirish',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              foregroundColor: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 8),
          // Text field
          Expanded(
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.enter): () {
                  if (!isSending && !isRecording) onSend();
                },
              },
              child: TextField(
                controller: textCtrl,
                focusNode: focusNode,
                enabled: !isRecording,
                maxLines: kIsWeb ? null : 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: isRecording ? 'Yozib olinmoqda...' : 'Xabar yozing...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: isRecording
                      ? Colors.red.withValues(alpha: 0.04)
                      : const Color(0xFFF8FAFC),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send / Mic / Stop
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: textCtrl,
            builder: (_, value, child) {
              final hasText = value.text.trim().isNotEmpty;
              if (isRecording) {
                return IconButton(
                  onPressed: onVoiceToggle,
                  icon: const Icon(Icons.stop_rounded),
                  tooltip: 'To\'xtatib yuborish',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                );
              }
              if (hasText) {
                return IconButton(
                  onPressed: isSending ? null : onSend,
                  icon: const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                );
              }
              return IconButton(
                onPressed: isSending ? null : onVoiceToggle,
                icon: const Icon(Icons.mic_rounded),
                tooltip: 'Ovozli xabar',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Empty chat ───────────────────────────────────────────────────────────────

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
            child: const Icon(
              Icons.chat_outlined,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Hali xabarlar yo\'q',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
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
