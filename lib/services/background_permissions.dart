import 'package:flutter/services.dart';

/// Android 13+: ask for the notification permission so the player
/// notification (and lock-screen controls) can be shown.
class BackgroundPermissions {
  static const _ch = MethodChannel('radio/system');

  static Future<void> ensure() async {
    try {
      await _ch.invokeMethod('requestNotifications');
    } on PlatformException {
      // Older Android: nothing to ask for.
    }
  }
}
