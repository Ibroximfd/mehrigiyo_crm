import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:web_socket_channel/web_socket_channel.dart';

/// Connects to every room's WS endpoint on behalf of the chat list.
/// Merges all room streams into one; injects '_room_id' into each event map.
class ChatListWsService {
  final _channels = <int, WebSocketChannel>{};
  final _timers = <int, Timer?>{};
  final _ctrl = StreamController<Map<String, dynamic>>.broadcast();
  final _roomIds = <int>{};
  String _token = '';
  bool _disposed = false;

  Stream<Map<String, dynamic>> get events => _ctrl.stream;

  static String _wsUrl(int roomId, String token) {
    if (kIsWeb && !kDebugMode) return '/ws/chat/$roomId/?token=$token';
    return 'wss://imorganic.uz/ws/chat/$roomId/?token=$token';
  }

  void connectAll(List<int> roomIds, String token) {
    _token = token;
    _disposed = false;
    for (final id in roomIds) {
      if (!_roomIds.contains(id)) {
        _roomIds.add(id);
        _openRoom(id);
      }
    }
  }

  void _openRoom(int roomId) {
    if (_disposed || _token.isEmpty) return;
    _channels[roomId]?.sink.close();
    try {
      final uri = Uri.parse(_wsUrl(roomId, _token));
      final ch = WebSocketChannel.connect(uri);
      _channels[roomId] = ch;
      ch.stream.listen(
        (raw) {
          if (_disposed) return;
          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            // Inject room_id so the bloc knows which room this event belongs to
            _ctrl.add({...data, '_room_id': roomId});
          } catch (_) {}
        },
        onDone: () => _onDisconnected(roomId),
        onError: (_) => _onDisconnected(roomId),
        cancelOnError: false,
      );
    } catch (_) {
      _onDisconnected(roomId);
    }
  }

  void _onDisconnected(int roomId) {
    _channels.remove(roomId);
    if (_disposed) return;
    _timers[roomId]?.cancel();
    _timers[roomId] = Timer(
      const Duration(seconds: 5),
      () => _openRoom(roomId),
    );
  }

  void disconnect() {
    _disposed = true;
    for (final t in _timers.values) {
      t?.cancel();
    }
    _timers.clear();
    for (final ch in _channels.values) {
      ch.sink.close();
    }
    _channels.clear();
    _roomIds.clear();
  }
}
