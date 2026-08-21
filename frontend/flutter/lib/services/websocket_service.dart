import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Connects to the Spring Boot WebSocket endpoint and broadcasts
/// incoming case-update events to all registered listeners.
class WebSocketService {
  static WebSocketService? _instance;
  WebSocketService._();
  static WebSocketService get instance => _instance ??= WebSocketService._();

  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _controller;
  bool _connected = false;
  Timer? _reconnectTimer;

  static const String _wsBase = 'ws://192.168.31.211:8081/ws';

  Stream<Map<String, dynamic>> get stream {
    _controller ??= StreamController<Map<String, dynamic>>.broadcast();
    return _controller!.stream;
  }

  bool get isConnected => _connected;

  /// Connect to the WebSocket server. Attaches JWT token as query param.
  Future<void> connect() async {
    if (_connected) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final uri = Uri.parse('$_wsBase?token=$token');

      _channel = WebSocketChannel.connect(uri);
      _controller ??= StreamController<Map<String, dynamic>>.broadcast();
      _connected = true;

      _channel!.stream.listen(
        (raw) {
          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            _controller!.add(data);
          } catch (_) {}
        },
        onDone: _onDisconnect,
        onError: (_) => _onDisconnect(),
        cancelOnError: false,
      );
      debugPrint('[WS] Connected to $_wsBase');
    } catch (e) {
      debugPrint('[WS] Connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _onDisconnect() {
    _connected = false;
    debugPrint('[WS] Disconnected. Scheduling reconnect…');
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), connect);
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _connected = false;
  }
}
