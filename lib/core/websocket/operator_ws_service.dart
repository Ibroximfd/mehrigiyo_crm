import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:web_socket_channel/web_socket_channel.dart';

class OperatorWsService {
  WebSocketChannel? _channel;
  final _ctrl = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;
  String? _token;
  bool _disposed = true;
  int _retryAttempt = 0;
  final _jitter = Random();

  Stream<Map<String, dynamic>> get events => _ctrl.stream;

  static String _wsUrl(String token) {
    if (kIsWeb && !kDebugMode) {
      return 'wss://${Uri.base.host}/ws/operator/?token=$token';
    }
    return 'wss://my.imorganic.uz/ws/operator/?token=$token';
  }

  void connect(String token) {
    _token = token;
    _disposed = false;
    _retryAttempt = 0;
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
          // A delivered message means the connection is healthy again.
          _retryAttempt = 0;
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
    // Exponential backoff (2s, 4s, 8s… capped at 60s) plus random jitter so a
    // server restart doesn't make every connected client reconnect in the same
    // instant (thundering herd).
    final backoff = min(60, 2 << min(_retryAttempt, 5));
    _retryAttempt++;
    final delayMs = backoff * 1000 + _jitter.nextInt(1000);
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), _openSocket);
  }

  void disconnect() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}
