import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:web_socket_channel/web_socket_channel.dart';

class OperatorWsService {
  WebSocketChannel? _channel;
  final _ctrl = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;
  String? _token;
  bool _disposed = true;

  Stream<Map<String, dynamic>> get events => _ctrl.stream;

  static String _wsUrl(String token) {
    if (kIsWeb && !kDebugMode) return 'wss://${Uri.base.host}/ws/operator/?token=$token';
    return 'wss://my.imorganic.uz/ws/operator/?token=$token';
  }

  void connect(String token) {
    _token = token;
    _disposed = false;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _openSocket();
  }

  void _openSocket() {
    if (_disposed || _token == null) return;
    try {
      final uri = Uri.parse(_wsUrl(_token!));
      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen(
        (raw) {
          if (_disposed) return;
          try {
            _ctrl.add(jsonDecode(raw as String) as Map<String, dynamic>);
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
