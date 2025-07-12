import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:typed_data';

class BleChatController {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  DiscoveredDevice? _connectedDevice;
  QualifiedCharacteristic? _chatCharacteristic;
  Stream<List<int>>? _messageStream;
  Function(String)? onMessage;

  // Encryption key (for demo; use secure key exchange in production)
  static final _key = SecretKey(List<int>.filled(32, 1)); // 256-bit key
  static final _algo = AesGcm.with256bits();

  // BLE UUIDs (randomly generated for chat service/characteristic)
  static final Uuid chatServiceUuid = Uuid.parse('12345678-1234-5678-1234-56789abcdef0');
  static final Uuid chatCharUuid = Uuid.parse('12345678-1234-5678-1234-56789abcdef1');

  // Start advertising as a chat host (not supported in flutter_reactive_ble, placeholder)
  Future<void> startAdvertising() async {
    // BLE advertising as a GATT server is not supported in flutter_reactive_ble.
    // This is a placeholder for future implementation or for use with another package.
    // For now, host can just wait for client to connect.
  }

  // Start scanning for chat hosts
  Stream<DiscoveredDevice> scanForPeers() {
    return _ble.scanForDevices(withServices: [chatServiceUuid]);
  }

  // Connect to a peer
  Future<void> connectToPeer(DiscoveredDevice device, {required Function(String) onMessage}) async {
    _connectedDevice = device;
    this.onMessage = onMessage;
    await _ble.connectToDevice(id: device.id).first;
    _chatCharacteristic = QualifiedCharacteristic(
      serviceId: chatServiceUuid,
      characteristicId: chatCharUuid,
      deviceId: device.id,
    );
    _messageStream = _ble.subscribeToCharacteristic(_chatCharacteristic!);
    _messageStream!.listen((data) async {
      final msg = await decryptMessage(data);
      onMessage(msg);
    });
  }

  // Send a message
  Future<void> sendMessage(String message) async {
    if (_chatCharacteristic != null) {
      final encrypted = await encryptMessage(message);
      await _ble.writeCharacteristicWithResponse(_chatCharacteristic!, value: encrypted);
    }
  }

  Future<List<int>> encryptMessage(String message) async {
    final nonce = _algo.newNonce();
    final secretBox = await _algo.encrypt(
      message.codeUnits,
      secretKey: _key,
      nonce: nonce,
    );
    return nonce + secretBox.cipherText + secretBox.mac.bytes;
  }

  Future<String> decryptMessage(List<int> data) async {
    final nonce = data.sublist(0, 12);
    final mac = Mac(data.sublist(data.length - 16));
    final cipherText = data.sublist(12, data.length - 16);
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    final clear = await _algo.decrypt(secretBox, secretKey: _key);
    return String.fromCharCodes(clear);
  }

  void close() {
    // No explicit close needed for BLE, just clear reference
    _connectedDevice = null;
  }
} 