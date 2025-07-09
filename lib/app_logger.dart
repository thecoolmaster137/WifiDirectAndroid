import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AppLogger {
  static File? _logFile;

  static Future<File> _getLogFile() async {
    if (_logFile != null) return _logFile!;
    final dir = await getApplicationDocumentsDirectory();
    _logFile = File('${dir.path}/app_log.txt');
    if (!await _logFile!.exists()) {
      await _logFile!.create();
    }
    return _logFile!;
  }

  static Future<void> log(String message) async {
    final file = await _getLogFile();
    final timestamp = DateTime.now().toIso8601String();
    await file.writeAsString('[$timestamp] $message\n', mode: FileMode.append);
  }

  static Future<String> readLog() async {
    final file = await _getLogFile();
    return await file.readAsString();
  }

  static Future<void> clearLog() async {
    final file = await _getLogFile();
    await file.writeAsString('');
  }
} 