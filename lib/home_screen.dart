import 'package:flutter/material.dart';
import 'hotspot_controller.dart';
import 'socket_controller.dart';
import 'chat_screen.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'app_logger.dart';

Future<void> ensurePermissions() async {
  await AppLogger.log('Requesting permissions...');
  var locationStatus = await Permission.location.request();
  await AppLogger.log('Location permission status: ' + locationStatus.toString());
  var nearbyStatus = await Permission.nearbyWifiDevices.request();
  await AppLogger.log('Nearby Wi-Fi Devices permission status: ' + nearbyStatus.toString());
  if (!locationStatus.isGranted || !nearbyStatus.isGranted) {
    await AppLogger.log('Permission denied.');
    throw Exception('Location and Nearby Devices permissions are required to create hotspot.');
  }
  await AppLogger.log('All required permissions granted.');
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? ssid;
  String? password;
  String? hostIp;
  final _ipController = TextEditingController();

  void createHotspot() async {
    try {
      await AppLogger.log('Starting hotspot creation...');
      await ensurePermissions();
      final info = await HotspotController.createHotspot();
      await AppLogger.log('Hotspot info: ' + info.toString());
      setState(() {
        ssid = info['ssid'];
        password = info['password'];
      });
      await AppLogger.log('Detecting local IP address...');
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            setState(() {
              hostIp = addr.address;
            });
            await AppLogger.log('Local IP detected: $hostIp');
            break;
          }
        }
      }
      await AppLogger.log('Hotspot creation and IP detection complete.');
    } catch (e) {
      await AppLogger.log('Error creating hotspot: ' + e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating hotspot: ' + e.toString())),
        );
      }
    }
  }

  void joinChat() async {
    await AppLogger.log('Navigating to ChatScreen as client. Host IP: ' + _ipController.text.trim());
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          isHost: false,
          hostIp: _ipController.text.trim(),
        ),
      ),
    );
  }

  void startHostChat() async {
    await AppLogger.log('Navigating to ChatScreen as host. Host IP: $hostIp');
    if (hostIp != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            isHost: true,
            hostIp: hostIp!,
          ),
        ),
      );
    }
  }

  void _showLogDialog() async {
    final log = await AppLogger.readLog();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('App Log'),
        content: SingleChildScrollView(child: Text(log)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              await AppLogger.clearLog();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Clear Log'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.log('Building HomeScreen UI.');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi Hotspot Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.article),
            tooltip: 'View Log',
            onPressed: _showLogDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ElevatedButton(
              onPressed: createHotspot,
              child: const Text('Create Hotspot (Host)'),
            ),
            if (ssid != null && password != null && hostIp != null) ...[
              Text('SSID: $ssid'),
              Text('Password: $password'),
              Text('Host IP: $hostIp'),
              ElevatedButton(
                onPressed: startHostChat,
                child: const Text('Start Chat as Host'),
              ),
              const Divider(),
            ],
            const SizedBox(height: 24),
            const Text('Join as Client:'),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Enter Host IP',
              ),
            ),
            ElevatedButton(
              onPressed: joinChat,
              child: const Text('Join Chat'),
            ),
          ],
        ),
      ),
    );
  }
}
