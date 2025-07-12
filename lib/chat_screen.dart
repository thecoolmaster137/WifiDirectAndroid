import 'package:flutter/material.dart';
import 'ble_chat_controller.dart';
import 'app_logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class ChatScreen extends StatefulWidget {
  final bool isHost;

  const ChatScreen({super.key, required this.isHost});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final List<String> messages = [];
  late BleChatController bleController;
  Stream<DiscoveredDevice>? _scanStream;
  List<DiscoveredDevice> _foundPeers = [];
  bool _isHost = false;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    bleController = BleChatController();
    if (widget.isHost) {
      _isHost = true;
      _startAdvertising();
    } else {
      _startScanning();
    }
  }

  void _startAdvertising() async {
    await bleController.startAdvertising();
    setState(() {
      _connected = true; // Host is ready
    });
  }

  void _startScanning() {
    _scanStream = bleController.scanForPeers();
    _scanStream!.listen((device) {
      if (!_foundPeers.any((d) => d.id == device.id)) {
        setState(() {
          _foundPeers.add(device);
        });
      }
    });
  }

  void _connectToPeer(DiscoveredDevice device) async {
    await bleController.connectToPeer(device, onMessage: _onMessage);
    setState(() {
      _connected = true;
    });
  }

  void _onMessage(String msg) async {
    setState(() {
      messages.add("Peer: $msg");
    });
    await AppLogger.log('Received message: $msg');
    HapticFeedback.lightImpact();
  }

  void sendMessage() async {
    final text = _controller.text.trim();
    if (text.isNotEmpty && _connected) {
      await bleController.sendMessage(text);
      setState(() {
        messages.add("Me: $text");
        _controller.clear();
      });
      await AppLogger.log('Sent message: $text');
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    bleController.close();
    AppLogger.log('ChatScreen disposed.');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.log('Building ChatScreen UI. isHost: ${widget.isHost}');
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isHost ? 'BLE Host Chat' : 'BLE Client Chat')),
      body: Container(
        color: Colors.grey[50],
        child: Column(
          children: [
            if (!_connected && !_isHost)
              Expanded(
                child: ListView.builder(
                  itemCount: _foundPeers.length,
                  itemBuilder: (_, i) {
                    final device = _foundPeers[i];
                    return ListTile(
                      title: Text(device.name.isNotEmpty ? device.name : device.id),
                      subtitle: Text(device.id),
                      onTap: () => _connectToPeer(device),
                    );
                  },
                ),
              ),
            if (_connected)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final isMe = messages[i].startsWith('Me:');
                    final msg = messages[i].replaceFirst(RegExp(r'^(Me:|Peer:) '), '');
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blueAccent : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          msg,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_connected)
              Card(
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => sendMessage(),
                        ),
                      ),
                      IconButton(
                        onPressed: sendMessage,
                        icon: const Icon(Icons.send, color: Colors.blueAccent),
                      ),
                    ],
                  ),
                ),
              ),
            if (!_connected && _isHost)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('Waiting for BLE client to connect...', style: TextStyle(fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }
}
