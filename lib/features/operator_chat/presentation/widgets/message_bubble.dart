import 'dart:ui_web' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/chat_entities.dart';
import 'voice_message_widget.dart';

// Tracks already-registered HtmlElementView factories to avoid duplicate registration
final _registeredViewIds = <String>{};

void _registerViewFactory(String viewId, web.HTMLElement Function() builder) {
  if (_registeredViewIds.contains(viewId)) return;
  _registeredViewIds.add(viewId);
  ui.platformViewRegistry.registerViewFactory(viewId, (_) => builder());
}

enum _MsgMenuAction { reply, copy }

class MessageBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final VoidCallback? onReply;
  final void Function(int replyId)? onReplyTap;

  const MessageBubble({
    super.key,
    required this.message,
    this.onReply,
    this.onReplyTap,
  });

  /// Opens a small context menu (Reply / Copy) anchored at [globalPos].
  /// Triggered by right-click (secondary tap) on desktop/web and long-press on
  /// touch — replacing the old double-tap-to-reply gesture.
  Future<void> _showContextMenu(BuildContext context, Offset globalPos) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final hasText = message.text.trim().isNotEmpty;
    final selected = await showMenu<_MsgMenuAction>(
      context: context,
      position: RelativeRect.fromRect(
        globalPos & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        const PopupMenuItem(
          value: _MsgMenuAction.reply,
          height: 44,
          child: Row(
            children: [
              Icon(Icons.reply_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Javob berish', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        if (hasText)
          const PopupMenuItem(
            value: _MsgMenuAction.copy,
            height: 44,
            child: Row(
              children: [
                Icon(Icons.copy_rounded, size: 18, color: Color(0xFF64748B)),
                SizedBox(width: 10),
                Text('Nusxalash', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
      ],
    );

    switch (selected) {
      case _MsgMenuAction.reply:
        onReply?.call();
      case _MsgMenuAction.copy:
        await Clipboard.setData(ClipboardData(text: message.text));
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget bubble;
    if (message.isRecommendation && message.recommendation != null) {
      bubble = _RecommendationBubble(
        message: message,
        rec: message.recommendation!,
      );
    } else if (message.hasMedia) {
      bubble = _MediaBubble(message: message, onReplyTap: onReplyTap);
    } else {
      bubble = _TextBubble(message: message, onReplyTap: onReplyTap);
    }

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onSecondaryTapDown: (d) => _showContextMenu(context, d.globalPosition),
      onLongPressStart: (d) => _showContextMenu(context, d.globalPosition),
      child: bubble,
    );
  }
}

// ─── Reply preview (inside bubble) ───────────────────────────────────────────

class _ReplyPreview extends StatelessWidget {
  final ChatMessageReply reply;
  final bool isMine;
  final VoidCallback? onTap;
  const _ReplyPreview({required this.reply, required this.isMine, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = isMine
        ? Colors.white.withValues(alpha: 0.18)
        : AppColors.primaryLight;
    final accent = isMine ? Colors.white70 : AppColors.primary;
    final textColor = isMine ? Colors.white70 : const Color(0xFF475569);

    String preview;
    if (reply.messageType == 'operator_recommendation') {
      preview = '📦 Mahsulot tavsiyasi';
    } else {
      preview = reply.text.isNotEmpty ? reply.text : '📎 Media';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: accent, width: 3)),
        ),
        child: Text(
          preview,
          style: TextStyle(fontSize: 12, color: textColor, height: 1.3),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ─── Text bubble ─────────────────────────────────────────────────────────────

class _TextBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final void Function(int)? onReplyTap;
  const _TextBubble({required this.message, this.onReplyTap});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.replyTo != null)
              _ReplyPreview(
                reply: message.replyTo!,
                isMine: isMine,
                onTap: onReplyTap != null ? () => onReplyTap!(message.replyTo!.id) : null,
              ),
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: TextStyle(
                  color: isMine ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 4),
            _TimeRow(
              createdAt: message.createdAt,
              isMine: isMine,
              isRead: message.isRead,
              isPending: message.id < 0,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Media bubble ─────────────────────────────────────────────────────────────

class _MediaBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final void Function(int)? onReplyTap;
  const _MediaBubble({required this.message, this.onReplyTap});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 16),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.replyTo != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: _ReplyPreview(
                    reply: message.replyTo!,
                    isMine: isMine,
                    onTap: onReplyTap != null ? () => onReplyTap!(message.replyTo!.id) : null,
                  ),
                ),
              // If attachments parsed, show them; else show fallback card from message_type
              if (message.attachments.isNotEmpty)
                ...message.attachments.map(
                  (a) => _AttachmentWidget(
                    attachment: a,
                    isMine: isMine,
                    messageId: message.id,
                  ),
                )
              else
                // No parsed attachment — show type-based card (URL unknown, no action)
                _MediaCard(
                  icon: _iconForType(message.messageType),
                  label: _labelForType(message.messageType),
                  isMine: isMine,
                  iconColor: _colorForType(message.messageType),
                  bgColor: _bgForType(message.messageType, isMine),
                ),
              if (message.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isMine ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 14,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                child: _TimeRow(
                  createdAt: message.createdAt,
                  isMine: isMine,
                  isRead: message.isRead,
                  isPending: message.id < 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentWidget extends StatelessWidget {
  final ChatAttachment attachment;
  final bool isMine;
  final int messageId;
  const _AttachmentWidget({
    required this.attachment,
    required this.isMine,
    required this.messageId,
  });

  String get _resolvedUrl => ApiConstants.resolveMediaUrl(attachment.url);

  @override
  Widget build(BuildContext context) {
    switch (attachment.fileType) {
      case 'image':
        return _ImageAttachment(url: _resolvedUrl, isMine: isMine);
      case 'audio':
      case 'voice':
        // Inline Telegram-style player — no dialog. Driven by AudioBloc.
        return VoiceMessageWidget(
          messageId: messageId,
          url: attachment.url,
          isMine: isMine,
          fileName: attachment.fileName,
        );
      case 'video':
        return _MediaCard(
          icon: Icons.videocam_rounded,
          label: attachment.fileName ?? 'Video',
          isMine: isMine,
          onTap: () => _showVideoDialog(context),
          iconColor: const Color(0xFF6366F1),
          bgColor: const Color(0xFFE0E7FF),
        );
      default:
        return _MediaCard(
          icon: Icons.attach_file_rounded,
          label: attachment.fileName ?? 'Fayl',
          isMine: isMine,
          isPending: _resolvedUrl.isEmpty,
          onTap: _resolvedUrl.isEmpty
              ? null
              : () {
                  if (kIsWeb) web.window.open(_resolvedUrl, '_blank');
                },
        );
    }
  }

  void _showVideoDialog(BuildContext context) {
    final viewId = 'video-${attachment.url.hashCode}';
    _registerViewFactory(viewId, () {
      return web.HTMLVideoElement()
        ..src = _resolvedUrl
        ..controls = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.background = '#000'
        ..style.borderRadius = '12px';
    });

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 560,
                height: 360,
                child: HtmlElementView(viewType: viewId),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isMine;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? bgColor;
  final bool isPending;

  const _MediaCard({
    required this.icon,
    required this.label,
    required this.isMine,
    this.onTap,
    this.iconColor,
    this.bgColor,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    final ic = iconColor ?? (isMine ? Colors.white70 : AppColors.primary);
    final bg = bgColor ?? (isMine ? Colors.white12 : AppColors.primaryLight);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: ic, size: 20),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isMine ? Colors.white : const Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    isPending ? 'Yuklanmoqda...' : 'Ochish uchun bosing',
                    style: TextStyle(
                      fontSize: 10,
                      color: isMine ? Colors.white54 : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            if (isPending)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: isMine ? Colors.white38 : const Color(0xFFCBD5E1),
                ),
              )
            else
              Icon(
                Icons.open_in_new_rounded,
                size: 14,
                color: isMine ? Colors.white38 : const Color(0xFFCBD5E1),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Time + read ─────────────────────────────────────────────────────────────

class _TimeRow extends StatelessWidget {
  final String createdAt;
  final bool isMine;
  final bool isRead;
  final bool isPending;
  const _TimeRow({
    required this.createdAt,
    required this.isMine,
    required this.isRead,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isMine ? Colors.white70 : const Color(0xFF94A3B8);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_fmt(createdAt), style: TextStyle(fontSize: 10, color: color)),
        if (isMine) ...[
          const SizedBox(width: 4),
          Icon(
            isPending
                ? Icons.access_time_rounded
                : isRead
                ? Icons.done_all_rounded
                : Icons.done_rounded,
            size: 13,
            color: isPending
                ? Colors.white38
                : isRead
                ? const Color(0xFF34D399)
                : Colors.white54,
          ),
        ],
      ],
    );
  }

  String _fmt(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

// ─── Recommendation bubble ────────────────────────────────────────────────────

class _RecommendationBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final ChatRecommendation rec;
  const _RecommendationBubble({required this.message, required this.rec});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.86,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.recommend_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    rec.type == 'operator'
                        ? 'Operator tavsiyasi'
                        : 'Doktor tavsiyasi',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  if (rec.isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Muddati o\'tgan',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFDC3545),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Product list
            ...rec.products.asMap().entries.map(
              (e) => Column(
                children: [
                  if (e.key > 0)
                    const Divider(
                      height: 1,
                      indent: 14,
                      endIndent: 14,
                      color: Color(0xFFF1F5F9),
                    ),
                  _ProductCard(product: e.value),
                ],
              ),
            ),
            // Time
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
              child: Text(
                _fmtTime(message.createdAt),
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                textAlign: isMine ? TextAlign.right : TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final RecommendedProduct product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: product.image.isNotEmpty
                ? Image.network(
                    ApiConstants.resolveMediaUrl(product.image),
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    // Web: fall back to an HTML <img> when the canvas fetch is
                    // blocked by CORS, so cross-origin media still renders.
                    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                    errorBuilder: (_, e, s) => _imgPlaceholder(),
                  )
                : _imgPlaceholder(),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Final price
                    Text(
                      '${_fmt(product.finalPrice)} so\'m',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    if (product.discount > 0) ...[
                      const SizedBox(width: 6),
                      // Discount badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${product.discount}%',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC3545),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (product.discount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${_fmt(product.cost)} so\'m',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(
      Icons.inventory_2_outlined,
      size: 28,
      color: Color(0xFFCBD5E1),
    ),
  );

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

String _fmtTime(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return '';
  }
}

IconData _iconForType(String t) {
  switch (t) {
    case 'image':
      return Icons.image_rounded;
    case 'video':
      return Icons.videocam_rounded;
    case 'audio':
    case 'voice':
      return Icons.mic_rounded;
    default:
      return Icons.attach_file_rounded;
  }
}

String _labelForType(String t) {
  switch (t) {
    case 'image':
      return 'Rasm';
    case 'video':
      return 'Video';
    case 'audio':
    case 'voice':
      return 'Ovozli xabar';
    default:
      return 'Fayl';
  }
}

Color _colorForType(String t) {
  switch (t) {
    case 'image':
      return const Color(0xFF6366F1);
    case 'video':
      return const Color(0xFF6366F1);
    case 'audio':
    case 'voice':
      return const Color(0xFF10B981);
    default:
      return AppColors.primary;
  }
}

Color _bgForType(String t, bool isMine) {
  if (isMine) return Colors.white12;
  switch (t) {
    case 'image':
      return const Color(0xFFE0E7FF);
    case 'video':
      return const Color(0xFFE0E7FF);
    case 'audio':
    case 'voice':
      return const Color(0xFFD1FAE5);
    default:
      return AppColors.primaryLight;
  }
}

// ─── Image thumbnail — StatelessWidget, Image.network ────────────────────────

class _ImageAttachment extends StatelessWidget {
  final String url;
  final bool isMine;
  const _ImageAttachment({required this.url, required this.isMine});

  void _openViewer(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black87,
      barrierDismissible: true,
      builder: (_) => _ImageViewerDialog(url: url),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        width: 200,
        height: 160,
        color: isMine ? Colors.white10 : Colors.black12,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
        ),
      );
    }

    return RepaintBoundary(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: () => _openViewer(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260, maxHeight: 260),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                cacheWidth: 260,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    width: 200,
                    height: 160,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        color: isMine ? Colors.white70 : AppColors.primary,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, _, _) => InkWell(
                  onTap: () => _openViewer(context),
                  child: Container(
                    width: 200,
                    height: 160,
                    color: isMine
                        ? Colors.white10
                        : const Color(0xFFF1F5F9),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image_rounded,
                            size: 36,
                            color: isMine
                                ? Colors.white38
                                : const Color(0xFFCBD5E1)),
                        const SizedBox(height: 6),
                        Text(
                          'Rasmni ochish',
                          style: TextStyle(
                            fontSize: 11,
                            color: isMine
                                ? Colors.white54
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Full-screen viewer — StatefulWidget (FocusNode for ESC) ─────────────────

class _ImageViewerDialog extends StatefulWidget {
  final String url;
  const _ImageViewerDialog({required this.url});

  @override
  State<_ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<_ImageViewerDialog> {
  late final FocusNode _focusNode;
  // true when Image.network fails (CORS) — fallback to HtmlElementView <img>
  bool _htmlFallback = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context, rootNavigator: true).pop();

  void _download() {
    final name = widget.url.split('/').last.split('?').first;
    final anchor = web.HTMLAnchorElement()
      ..href = widget.url
      ..download = name.isNotEmpty ? name : 'image'
      ..target = '_blank';
    web.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
  }

  Widget _buildImage() {
    if (_htmlFallback) {
      // Image.network failed (CORS) — use HTML <img> which loads cross-origin fine
      final viewId = 'img-viewer-${widget.url.hashCode}';
      _registerViewFactory(viewId, () => web.HTMLImageElement()
        ..src = widget.url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'contain'
        ..style.pointerEvents = 'none'); // pass events to Flutter
      return HtmlElementView(viewType: viewId);
    }

    return Image.network(
      widget.url,
      fit: BoxFit.contain,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      },
      errorBuilder: (_, _, _) {
        // Switch to HtmlElementView on next frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_htmlFallback) {
            setState(() => _htmlFallback = true);
          }
        });
        return const Center(
          child: CircularProgressIndicator(color: Colors.white54),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _close();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: SizedBox.expand(
          child: Stack(
            children: [
              // Image — zoomable via InteractiveViewer
              InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 5.0,
                panEnabled: true,
                scaleEnabled: true,
                child: Center(child: _buildImage()),
              ),

              // Top gradient bar (Flutter layer — always clickable)
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 12, right: 12, bottom: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ViewerBtn(
                        icon: Icons.close_rounded,
                        tooltip: 'Yopish (ESC)',
                        onTap: _close,
                      ),
                      Row(children: [
                        _ViewerBtn(
                          icon: Icons.download_rounded,
                          tooltip: 'Yuklab olish',
                          onTap: _download,
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewerBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _ViewerBtn(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
              color: Colors.black45, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
