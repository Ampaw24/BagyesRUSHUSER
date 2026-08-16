import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Resolves the platform label and human-readable device name used when
/// registering this device's push token with the backend.
class DeviceInfoUtils {
  static final _deviceInfo = DeviceInfoPlugin();

  static Future<({String platform, String deviceName})> getDetails() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final info = await _deviceInfo.androidInfo;
        return (platform: 'android', deviceName: '${info.manufacturer} ${info.model}');
      case TargetPlatform.iOS:
        final info = await _deviceInfo.iosInfo;
        return (platform: 'ios', deviceName: info.name);
      default:
        return (platform: defaultTargetPlatform.name, deviceName: 'unknown');
    }
  }
}
