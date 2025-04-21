import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class WifiService {
  static const MethodChannel _channel = MethodChannel('wifiInfo');

  static Future<String> getWifiSSID() async {
    try {
      // Request permissions
      final locationStatus = await Permission.locationWhenInUse.request();
      final nearbyWifiStatus = await Permission.nearbyWifiDevices.request();

      if (!locationStatus.isGranted || !nearbyWifiStatus.isGranted) {
        return 'Permissions not granted';
      }

      final String? ssid = await _channel.invokeMethod('getWifiSSID');
      return ssid ?? 'Unknown';
    } catch (e) {
      print('Error fetching Wi-Fi SSID: $e');
      return 'Unknown';
    }
  }
}
