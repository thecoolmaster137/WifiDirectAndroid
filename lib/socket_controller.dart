import 'dart:io';

class SocketController {
  ServerSocket? _server;
  Socket? _client;
  Function(String)? onMessage;

  // Host: Start server
  Future<String> startServer({required Function(String) onMessage}) async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, 4040);
    _server!.listen((client) {
      _client = client;
      client.listen((data) {
        onMessage(String.fromCharCodes(data));
      });
    });
    this.onMessage = onMessage;
    return _server!.address.address;
  }

  // Client: Connect to host
  Future<void> connectToHost(String hostIp, {required Function(String) onMessage}) async {
    _client = await Socket.connect(hostIp, 4040);
    _client!.listen((data) {
      onMessage(String.fromCharCodes(data));
    });
    this.onMessage = onMessage;
  }

  void sendMessage(String message) {
    _client?.write(message);
  }

  void close() {
    _client?.close();
    _server?.close();
  }
} 