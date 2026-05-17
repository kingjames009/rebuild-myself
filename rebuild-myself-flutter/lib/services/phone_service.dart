import 'package:flutter/services.dart';

class PhoneService {
  static const _channel = MethodChannel('com.rebuildmyself/phone');

  static Future<bool> hasPermission() async {
    try {
      return await _channel.invokeMethod('hasPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestPermission');
    } catch (_) {}
  }

  /// Returns the SIM phone number, or null if unavailable / permission denied.
  static Future<String?> getPhoneNumber() async {
    try {
      return await _channel.invokeMethod('getPhoneNumber');
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
