import 'package:flutter/material.dart';
import 'chat_screen.dart';
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
    throw Exception('Location and Nearby Devices permissions are required for BLE chat.');
  }
  await AppLogger.log('All required permissions granted.');
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void startHostChat() async {
    try {
      await AppLogger.log('Starting BLE host chat...');
      await ensurePermissions();
      await AppLogger.log('Navigating to ChatScreen as BLE host');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ChatScreen(
            isHost: true,
          ),
        ),
      );
    } catch (e) {
      await AppLogger.log('Error starting BLE host: ' + e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting BLE host: ' + e.toString())),
        );
      }
    }
  }

  void startClientChat() async {
    try {
      await AppLogger.log('Starting BLE client chat...');
      await ensurePermissions();
      await AppLogger.log('Navigating to ChatScreen as BLE client');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ChatScreen(
            isHost: false,
          ),
        ),
      );
    } catch (e) {
      await AppLogger.log('Error starting BLE client: ' + e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting BLE client: ' + e.toString())),
        );
      }
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
        title: const Text('BLE Chat Messenger'),
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
                          'Host a BLE Chat',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: startHostChat,
                          icon: const Icon(Icons.bluetooth),
                          label: const Text('Start BLE Host'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Create a BLE service that other devices can discover and connect to.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
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
                          'Join as BLE Client',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: startClientChat,
                          icon: const Icon(Icons.bluetooth_searching),
                          label: const Text('Scan & Connect'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Scan for nearby BLE devices and connect to start chatting.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
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
