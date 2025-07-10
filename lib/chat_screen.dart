import 'package:flutter/material.dart';
import 'socket_controller.dart';
import 'app_logger.dart';
import 'package:flutter/services.dart';

class ChatScreen extends StatefulWidget {
  final bool isHost;
  final String hostIp;

  const ChatScreen({super.key, required this.isHost, required this.hostIp});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final List<String> messages = [];
  late SocketController socketController;

  @override
  void initState() {
    super.initState();
    socketController = SocketController();
    _initConnection();
  }

  Future<void> _initConnection() async {
    try {
      if (widget.isHost) {
        await AppLogger.log('Starting server as host. Host IP: ${widget.hostIp}');
        await socketController.startServer(onMessage: _onMessage);
      } else {
        await AppLogger.log('Connecting as client to host IP: ${widget.hostIp}');
        await socketController.connectToHost(widget.hostIp, onMessage: _onMessage);
      }
      await AppLogger.log('Connection established.');
    } catch (e) {
      await AppLogger.log('Error establishing connection: $e');
    }
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
    if (text.isNotEmpty) {
      await socketController.sendMessage(text);
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
    socketController.close();
    AppLogger.log('ChatScreen disposed.');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.log('Building ChatScreen UI. isHost:  [${widget.isHost}, hostIp: ${widget.hostIp}');
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.isHost ? 'Host Chat' : 'Client Chat')),
      body: Container(
        color: Colors.grey[50],
        child: Column(
          children: [
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
          ],
        ),
      ),
    );
  }
}
