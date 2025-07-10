import 'dart:io';
import 'package:cryptography/cryptography.dart';

class SocketController {
  ServerSocket? _server;
  Socket? _client;
  Function(String)? onMessage;

  // Encryption key (for demo; use secure key exchange in production)
  static final _key = SecretKey(List<int>.filled(32, 1)); // 256-bit key
  static final _algo = AesGcm.with256bits();

  Future<List<int>> encryptMessage(String message) async {
    final nonce = _algo.newNonce();
    final secretBox = await _algo.encrypt(
      message.codeUnits,
      secretKey: _key,
      nonce: nonce,
    );
    // Prepend nonce to ciphertext for transport
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

  // Host: Start server
  Future<String> startServer({required Function(String) onMessage}) async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, 4040);
    _server!.listen((client) {
      _client = client;
      client.listen((data) async {
        final msg = await decryptMessage(data);
        onMessage(msg);
      });
    });
    this.onMessage = onMessage;
    return _server!.address.address;
  }

  // Client: Connect to host
  Future<void> connectToHost(String hostIp, {required Function(String) onMessage}) async {
    _client = await Socket.connect(hostIp, 4040);
    _client!.listen((data) async {
      final msg = await decryptMessage(data);
      onMessage(msg);
    });
    this.onMessage = onMessage;
  }

  Future<void> sendMessage(String message) async {
    if (_client != null) {
      final encrypted = await encryptMessage(message);
      _client!.add(encrypted);
    }
  }

  void close() {
    _client?.close();
    _server?.close();
  }
} 