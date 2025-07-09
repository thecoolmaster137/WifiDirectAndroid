import 'package:flutter/services.dart';

class HotspotController {
  static const MethodChannel _channel = MethodChannel('hotspot');

  static Future<Map<String, String>> createHotspot() async {
    final result = await _channel.invokeMethod('createHotspot');
    return Map<String, String>.from(result);
  }
} 