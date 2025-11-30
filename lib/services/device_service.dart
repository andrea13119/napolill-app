import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Get device temperature (simulated for now, as real temperature APIs are limited)
  /// Returns temperature in Celsius
  Future<double?> getDeviceTemperature() async {
    try {
      // Note: Real device temperature APIs are very limited and often restricted
      // This is a simulated implementation that returns a reasonable temperature
      // In a real app, you might need platform-specific implementations

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Simulate temperature based on device state
        // In reality, you'd need root access or specific manufacturer APIs
        return _simulateAndroidTemperature(androidInfo);
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        // iOS doesn't provide temperature APIs for security reasons
        return _simulateIOSTemperature(iosInfo);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting device temperature: $e');
      return null;
    }
  }

  /// Simulate Android temperature (since real APIs are restricted)
  double _simulateAndroidTemperature(AndroidDeviceInfo androidInfo) {
    // Simulate temperature based on device characteristics
    // This is just for demonstration - real temperature would need special permissions
    final baseTemp = 25.0; // Base temperature in Celsius

    // Add some variation based on device info
    final variation = (androidInfo.model.hashCode % 10) - 5; // -5 to +5 degrees
    final temperature = baseTemp + variation;

    // Ensure temperature is within reasonable bounds
    return temperature.clamp(15.0, 45.0);
  }

  /// Simulate iOS temperature (since iOS doesn't provide temperature APIs)
  double _simulateIOSTemperature(IosDeviceInfo iosInfo) {
    // iOS doesn't provide temperature APIs for security reasons
    // This is just for demonstration
    final baseTemp = 24.0; // Base temperature in Celsius

    // Add some variation based on device info
    final variation = (iosInfo.model.hashCode % 8) - 4; // -4 to +4 degrees
    final temperature = baseTemp + variation;

    // Ensure temperature is within reasonable bounds
    return temperature.clamp(18.0, 42.0);
  }

  /// Check if temperature is in safe range
  bool isTemperatureSafe(double temperature) {
    // Safe range: 15°C to 35°C
    return temperature >= 15.0 && temperature <= 35.0;
  }

  /// Check if temperature is dangerous
  bool isTemperatureDangerous(double temperature) {
    // Dangerous: above 40°C or below 10°C
    return temperature > 40.0 || temperature < 10.0;
  }

  /// Get temperature color based on safety
  String getTemperatureColor(double temperature) {
    if (isTemperatureDangerous(temperature)) {
      return 'red'; // Dangerous
    } else if (isTemperatureSafe(temperature)) {
      return 'green'; // Safe
    } else {
      return 'orange'; // Warning
    }
  }

  /// Check if vibration is available on device
  Future<bool> isVibrationAvailable() async {
    try {
      // Check if device supports vibration
      // This is a basic check - actual vibration availability depends on hardware
      return true; // Most modern devices support vibration
    } catch (e) {
      debugPrint('Error checking vibration availability: $e');
      return false;
    }
  }

  /// Open device settings for this app
  Future<void> openDeviceSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
    }
  }
}
