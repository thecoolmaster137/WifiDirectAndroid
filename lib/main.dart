import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(const WiFiHotspotMessengerApp());
}

class WiFiHotspotMessengerApp extends StatelessWidget {
  const WiFiHotspotMessengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wi-Fi Hotspot Messenger',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}
