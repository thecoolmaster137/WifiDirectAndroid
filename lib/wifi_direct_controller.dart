import 'package:flutter/services.dart';
import 'dart:async';

class WiFiDirectController {
  static const MethodChannel _channel = MethodChannel('wifi_direct');

  static final StreamController<String> _messageController = StreamController<String>.broadcast();
  static bool _handlerSet = false;

  static Stream<String> get messageStream {
    if (!_handlerSet) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onMessageReceived') {
          final msg = call.arguments as String?;
          if (msg != null) _messageController.add(msg);
        }
      });
      _handlerSet = true;
    }
    return _messageController.stream;
  }

  static Future<List<String>> discoverPeers() async {
    final List<dynamic> peers = await _channel.invokeMethod('discoverPeers');
    return peers.cast<String>();
  }

  static Future<void> connect(String deviceName) async {
    await _channel.invokeMethod('connect', {'deviceName': deviceName});
  }

  static Future<void> sendMessage(String deviceName, String message) async {
    await _channel.invokeMethod('sendMessage', {
      'deviceName': deviceName,
      'message': message,
    });
  }
}
