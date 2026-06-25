import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatWsService {
  WebSocketChannel? _channel;
  final _ctrl = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;
  int? _roomId;
  String? _token;
  bool _disposed = true;

  Stream<Map<String, dynamic>> get events => _ctrl.stream;

  static String _wsUrl(int roomId, String token) {
    if (kIsWeb && !kDebugMode) return '/ws/chat/$roomId/?token=$token';
    return 'wss://imorganic.uz/ws/chat/$roomId/?token=$token';
  }

  void connect(int roomId, String token) {
    _roomId = roomId;
    _token = token;
    _disposed = false;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _openSocket();
  }

  void _openSocket() {
    if (_disposed || _roomId == null || _token == null) return;
    try {
      final uri = Uri.parse(_wsUrl(_roomId!, _token!));
      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen(
        (raw) {
          if (_disposed) return;
          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            _ctrl.add(data);
          } catch (_) {}
        },
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
        cancelOnError: false,
      );
    } catch (_) {
      _onDisconnected();
    }
  }

  void _onDisconnected() {
    _channel = null;
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), _openSocket);
  }

  void disconnect() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}
