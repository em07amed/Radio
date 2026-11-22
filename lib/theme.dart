import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Colors for the current brightness. [dark] is set by the app builder
/// before the widget tree builds, and the tree is rebuilt when it changes.
class AppColors {
  static bool dark = false;

  static Color get bg => dark ? const Color(0xFF0E0E10) : const Color(0xFFF2F2F2);
  static Color get ink => dark ? const Color(0xFFF2F2F2) : const Color(0xFF111111);
  static Color get inkFaded =>
      dark ? const Color(0xFF38383C) : const Color(0xFFD6D6D6);
  static Color get textDim =>
      dark ? const Color(0xFF8E8E93) : const Color(0xFF8A8A8A);
  static Color get card => dark ? const Color(0xFF1B1B1E) : Colors.white;
  static Color get border =>
      dark ? const Color(0xFF2A2A2E) : const Color(0xFFE4E4E4);
  static Color get dialTop => dark ? const Color(0xFF1E1E22) : Colors.white;
  static Color get shadow =>
      dark ? const Color(0x66000000) : const Color(0x14000000);
  static const accent = Color(0xFFFF7A1A); // orange needle / FM

  /// Stable soft gradient per station (used when there's no logo).
  static LinearGradient forName(String name) {
    const palettes = [
      [Color(0xFFFFB37A), Color(0xFFFF7A1A)],
      [Color(0xFF9BB8FF), Color(0xFF5B7CFA)],
      [Color(0xFF8EE3C8), Color(0xFF2BB58A)],
      [Color(0xFFFFA5B8), Color(0xFFF2557A)],
      [Color(0xFFC6A8FF), Color(0xFF8A5CF6)],
      [Color(0xFFB8B8B8), Color(0xFF6E6E6E)],
    ];
    final p = palettes[name.hashCode.abs() % palettes.length];
    return LinearGradient(
        colors: p, begin: Alignment.topLeft, end: Alignment.bottomRight);
  }
}

/// Light / dark / follow system, saved on the device.
class ThemeController {
  static const _key = 'theme_mode';
  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    mode.value = ThemeMode.values[
        (_prefs.getInt(_key) ?? 0).clamp(0, ThemeMode.values.length - 1)];
  }

  Future<void> set(ThemeMode m) async {
    mode.value = m;
    await _prefs.setInt(_key, m.index);
  }
}

ThemeData buildTheme(Brightness b) {
  final wasDark = AppColors.dark;
  AppColors.dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.accent, brightness: b)
      .copyWith(primary: AppColors.accent, surface: AppColors.bg);
  final t = ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.dark ? const Color(0xFF2A2A2E) : const Color(0xFF111111),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
  AppColors.dark = wasDark;
  return t;
}
