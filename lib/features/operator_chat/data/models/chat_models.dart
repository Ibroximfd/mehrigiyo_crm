import 'package:flutter/foundation.dart';

import '../../domain/entities/chat_entities.dart';

class ChatRoomModel extends ChatRoomEntity {
  const ChatRoomModel({
    required super.id,
    required super.participantName,
    required super.participantPhone,
    super.avatarUrl,
    super.leadId,
    super.lastMessage,
    super.lastMessageIsMine,
    super.lastMessageAt,
    super.unreadCount,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    // List endpoint: other_user | Create room endpoint: client | fallback: participant
    final other = json['other_user'] as Map<String, dynamic>?
        ?? json['client'] as Map<String, dynamic>?
        ?? json['participant'] as Map<String, dynamic>?;

    final firstName = other?['first_name']?.toString() ?? '';
    final lastName = other?['last_name']?.toString() ?? '';
    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

    // last_message can be object or null
    final lastMsgRaw = json['last_message'];
    String? lastMsg;
    bool? lastMsgIsMine;
    if (lastMsgRaw is Map) {
      lastMsg = lastMsgRaw['text']?.toString();
      lastMsgIsMine = lastMsgRaw['is_mine'] as bool?;
    } else if (lastMsgRaw is String) {
      lastMsg = lastMsgRaw;
    }

    return ChatRoomModel(
      id: json['room_id'] as int? ?? json['id'] as int,
      participantName: fullName.isNotEmpty
          ? fullName
          : other?['full_name']?.toString()
              ?? other?['name']?.toString()
              ?? json['participant_name']?.toString()
              ?? '',
      participantPhone: other?['phone']?.toString()
          ?? json['participant_phone']?.toString()
          ?? '',
      avatarUrl: other?['avatar']?.toString(),
      leadId: json['lead_id'] as int?,
      lastMessage: lastMsg,
      lastMessageIsMine: lastMsgIsMine,
      lastMessageAt: json['updated_at']?.toString(),
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }
}

class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.messageType,
    required super.text,
    required super.isMine,
    super.isRead,
    super.senderName,
    super.replyTo,
    super.attachments,
    super.recommendation,
    required super.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final recJson = json['recommendation'] as Map<String, dynamic>?;
    final msgType = json['message_type']?.toString() ?? 'text';

    // Sender display name (first + last). Used to show the client's name in the
    // chat header when the room itself carries no participant name.
    final sender = json['sender'] as Map<String, dynamic>?;
    final senderName = sender == null
        ? null
        : [
            sender['first_name']?.toString() ?? '',
            sender['last_name']?.toString() ?? '',
          ].where((s) => s.isNotEmpty).join(' ').trim();

    // Parse attachments — try list first, then top-level file field
    final attachmentsRaw = json['attachments'] as List? ?? [];
    var attachments = attachmentsRaw
        .map((a) => a is Map<String, dynamic>
            ? _parseAttachment(a, msgType)
            : a is String
                ? _parseAttachmentFromUrl(a, msgType)
                : null)
        .whereType<ChatAttachment>()
        .toList();

    // Some APIs put the media directly on the message when attachment list is empty
    if (attachments.isEmpty && msgType != 'text' && msgType != 'operator_recommendation') {
      final topUrl = json['file']?.toString()
          ?? json['media']?.toString()
          ?? json['url']?.toString()
          ?? json['voice']?.toString()
          ?? json['audio']?.toString()
          ?? json['image']?.toString()
          ?? json['video']?.toString();
      if (topUrl != null && topUrl.isNotEmpty) {
        final a = _parseAttachmentFromUrl(topUrl, msgType);
        if (a != null) attachments = [a];
      }
    }

    // Parse reply_to
    final replyRaw = json['reply_to'] as Map<String, dynamic>?;
    ChatMessageReply? replyTo;
    if (replyRaw != null) {
      replyTo = ChatMessageReply(
        id: replyRaw['id'] as int,
        text: replyRaw['text']?.toString() ?? '',
        messageType: replyRaw['message_type']?.toString() ?? 'text',
        isMine: replyRaw['is_mine'] as bool? ?? false,
      );
    }

    // ── TEMP DEBUG: trace how media (esp. audio) messages arrive from backend ──
    final isMedia = msgType != 'text' && msgType != 'operator_recommendation';
    if (isMedia || attachments.isNotEmpty) {
      debugPrint('[CHAT-DEBUG] msg id=${json['id']} type=$msgType '
          'keys=${json.keys.toList()}');
      debugPrint('[CHAT-DEBUG]   raw=$json');
      debugPrint('[CHAT-DEBUG]   parsed attachments='
          '${attachments.map((a) => '{type:${a.fileType}, url:${a.url}}').toList()}');
    }

    return ChatMessageModel(
      id: json['id'] as int,
      messageType: msgType,
      text: json['text']?.toString() ?? '',
      isMine: json['is_mine'] as bool? ?? false,
      isRead: json['is_read'] as bool? ?? false,
      senderName: (senderName != null && senderName.isNotEmpty) ? senderName : null,
      replyTo: replyTo,
      attachments: attachments,
      recommendation: recJson != null ? _parseRecommendation(recJson) : null,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  static ChatAttachment? _parseAttachment(Map<String, dynamic> json, [String? msgType]) {
    final url = json['file']?.toString()
        ?? json['url']?.toString()
        ?? json['file_url']?.toString()
        ?? '';
    if (url.isEmpty) return null;
    // Priority: explicit file_type > message_type > url extension
    final explicit = json['file_type']?.toString() ?? '';
    String fileType;
    if (explicit.isNotEmpty) {
      fileType = _normalizeType(explicit);
    } else if (msgType != null) {
      fileType = _typeFromMsgType(msgType) ?? _typeFromUrl(url);
    } else {
      fileType = _typeFromUrl(url);
    }
    return ChatAttachment(
      url: url,
      fileType: fileType,
      fileName: url.split('/').last.split('?').first,
    );
  }

  static ChatAttachment? _parseAttachmentFromUrl(String url, String msgType) {
    if (url.isEmpty) return null;
    final fileType = _typeFromMsgType(msgType) ?? _typeFromUrl(url);
    return ChatAttachment(
      url: url,
      fileType: fileType,
      fileName: url.split('/').last.split('?').first,
    );
  }

  static String _typeFromUrl(String url) {
    final ext = url.split('?').first.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'].contains(ext)) return 'image';
    if (['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'].contains(ext)) return 'video';
    if (['mp3', 'ogg', 'wav', 'm4a', 'aac', 'opus', 'amr'].contains(ext)) return 'audio';
    return 'file';
  }

  static String _normalizeType(String t) {
    if (['image', 'photo', 'picture'].contains(t)) return 'image';
    if (['video', 'film'].contains(t)) return 'video';
    if (['audio', 'voice', 'sound'].contains(t)) return 'audio';
    return 'file';
  }

  static String? _typeFromMsgType(String msgType) {
    switch (msgType) {
      case 'image': return 'image';
      case 'video': return 'video';
      case 'audio':
      case 'voice': return 'audio';
      default: return null;
    }
  }

  static ChatRecommendation _parseRecommendation(Map<String, dynamic> json) {
    final productsJson = json['products'] as List? ?? [];
    return ChatRecommendation(
      id: json['id'] as int,
      type: json['type']?.toString() ?? 'operator',
      products: productsJson
          .map((p) => _parseProduct(p as Map<String, dynamic>))
          .toList(),
      expiresAt: json['expires_at']?.toString() ?? '',
      isExpired: json['is_expired'] as bool? ?? false,
    );
  }

  static RecommendedProduct _parseProduct(Map<String, dynamic> json) {
    return RecommendedProduct(
      id: json['id'] as int,
      title: json['title']?.toString() ?? '',
      cost: (json['cost'] as num?)?.toInt() ?? 0,
      discount: (json['discount'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      image: json['image']?.toString() ?? '',
    );
  }
}

class ChatProductModel extends ChatProductEntity {
  const ChatProductModel({
    required super.id,
    required super.title,
    required super.cost,
    required super.discount,
    required super.isActive,
    required super.image,
  });

  factory ChatProductModel.fromJson(Map<String, dynamic> json) {
    return ChatProductModel(
      id: json['id'] as int,
      title: json['title']?.toString() ?? '',
      cost: (json['cost'] as num?)?.toInt() ?? 0,
      discount: (json['discount'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      image: json['image']?.toString() ?? '',
    );
  }
}
