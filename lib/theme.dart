import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFFF2F2F2);
  static const ink = Color(0xFF111111);
  static const inkFaded = Color(0xFFD6D6D6);
  static const textDim = Color(0xFF8A8A8A);
  static const accent = Color(0xFFFF7A1A); // orange needle / FM
  static const card = Colors.white;
  static const border = Color(0xFFE4E4E4);

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

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.light,
  ).copyWith(primary: AppColors.accent, surface: AppColors.bg);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
