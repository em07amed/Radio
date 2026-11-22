import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' show PlatformDispatcher;

import 'screens/dial_screen.dart';
import 'services/audio_handler.dart';
import 'services/favorites_service.dart';
import 'services/radio_api.dart';
import 'services/update_service.dart';
import 'services/diag_log.dart';
import 'theme.dart';

late final RadioAudioHandler audioHandler;
final favoritesService = FavoritesService();
final radioApi = RadioApi();
final themeController = ThemeController();
final updateService = UpdateService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (d) {
    DiagLog.add('FlutterError: ${d.exceptionAsString()}');
    FlutterError.presentError(d);
  };
  PlatformDispatcher.instance.onError = (e, st) {
    DiagLog.add('Uncaught: $e\n$st');
    return true;
  };
  await Future.wait([
    favoritesService.init(),
    themeController.init(),
    updateService.init(),
  ]);
  DiagLog.add('AudioService.init start');
  audioHandler = await AudioService.init(
    builder: () => RadioAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.ezzat.radio_app.audio',
      androidNotificationChannelName: 'تشغيل الراديو',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      // Must be a white-on-transparent drawable; the adaptive launcher
      // icon is rejected as a notification icon on Android 8+.
      androidNotificationIcon: 'drawable/ic_stat_radio',
    ),
  );
  DiagLog.add('AudioService.init done');
  audioHandler.playbackState
      .map((s) => '${s.playing} ${s.processingState.name}')
      .distinct()
      .listen((s) => DiagLog.add('playbackState: $s'));
  runApp(const RadioApp());
}

class RadioApp extends StatelessWidget {
  const RadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController.mode,
      builder: (context, mode, _) => MaterialApp(
        title: 'راديو',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        themeAnimationDuration: Duration.zero,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        builder: (context, child) {
          // Point the color getters at the active brightness, then rebuild
          // the whole tree whenever it flips.
          final dark = Theme.of(context).brightness == Brightness.dark;
          AppColors.dark = dark;
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: AppColors.bg,
            systemNavigationBarIconBrightness:
                dark ? Brightness.light : Brightness.dark,
          ));
          return KeyedSubtree(key: ValueKey(dark), child: child!);
        },
        home: const DialScreen(),
      ),
    );
  }
}
