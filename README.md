# BLE Chat Messenger

A Flutter app for offline messaging using Bluetooth Low Energy (BLE).

## Features

- **BLE Host Mode**: Create a BLE service that other devices can discover and connect to
- **BLE Client Mode**: Scan for nearby BLE devices and connect to start chatting
- **Encrypted Messaging**: All messages are encrypted using AES-GCM
- **Offline Communication**: No internet required - direct device-to-device communication
- **Modern UI**: Beautiful Material 3 design with intuitive interface

## Getting Started

This project requires Flutter 3.0.0 or higher.

### Prerequisites

- Flutter SDK
- Android device with BLE support (for testing)
- Required permissions: Location and Nearby Devices

### Installation

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Connect your device and run `flutter run`

## Usage

1. **As Host**: Tap "Start BLE Host" to create a BLE service
2. **As Client**: Tap "Scan & Connect" to find and connect to nearby BLE hosts
3. **Chat**: Once connected, start sending encrypted messages

## Technical Details

- Uses `flutter_reactive_ble` for BLE communication
- Implements AES-GCM encryption for message security
- Supports both host and client roles
- Includes comprehensive logging for debugging

## Permissions

The app requires:
- Location permission (required for BLE scanning on Android)
- Nearby Devices permission (for BLE functionality)
