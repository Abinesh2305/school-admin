import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

Future<String> getOsVersion() async {
  final deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.release; // e.g. "14"
  }

  if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    return iosInfo.systemVersion; // e.g. "17.2"
  }

  return 'unknown';
}
