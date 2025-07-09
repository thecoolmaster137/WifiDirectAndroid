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
    final theme = Theme.of(context);
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
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Host a Chat',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: createHotspot,
                          icon: const Icon(Icons.wifi_tethering),
                          label: const Text('Create Hotspot'),
                        ),
                        if (ssid != null && password != null && hostIp != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('SSID: $ssid', style: theme.textTheme.bodyMedium),
                                Text('Password: $password', style: theme.textTheme.bodyMedium),
                                Text('Host IP: $hostIp', style: theme.textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: startHostChat,
                            icon: const Icon(Icons.chat),
                            label: const Text('Start Chat as Host'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Join as Client',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _ipController,
                          decoration: const InputDecoration(
                            labelText: 'Enter Host IP',
                            prefixIcon: Icon(Icons.dns),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: joinChat,
                          icon: const Icon(Icons.login),
                          label: const Text('Join Chat'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
