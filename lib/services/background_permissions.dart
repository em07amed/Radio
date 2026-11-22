import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';

/// Makes sure the system lets the radio keep playing in the background:
/// notification permission (Android 13+) and no battery optimisation.
class BackgroundPermissions {
  static const _askedBatteryKey = 'asked_battery_opt';
  static const _ch = MethodChannel('radio/system');

  static Future<void> ensure(BuildContext context) async {
    // Android 13+: without this the player notification can be hidden.
    try {
      await _ch.invokeMethod('requestNotifications');
      if (await _ch.invokeMethod<bool>('isIgnoringBattery') ?? true) return;
    } on PlatformException {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_askedBatteryKey) ?? false) return;
    await prefs.setBool(_askedBatteryKey, true);
    if (!context.mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.battery_saver_rounded,
            color: AppColors.accent, size: 36),
        title: Text('التشغيل في الخلفية',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.ink)),
        content: Text(
          'عشان الراديو يفضل شغال وانت قافل الشاشة أو خارج من التطبيق، '
          'اسمح له يشتغل من غير توفير البطارية.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('بعدين', style: TextStyle(color: AppColors.textDim)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('اسمح'),
          ),
        ],
      ),
    );
    if (ok == true) await _ch.invokeMethod('requestIgnoreBattery');
  }
}
