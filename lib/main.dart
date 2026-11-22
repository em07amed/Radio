import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/dial_screen.dart';
import 'services/audio_handler.dart';
import 'services/favorites_service.dart';
import 'services/radio_api.dart';
import 'theme.dart';

late final RadioAudioHandler audioHandler;
final favoritesService = FavoritesService();
final radioApi = RadioApi();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.bg,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  await favoritesService.init();
  audioHandler = await AudioService.init(
    builder: () => RadioAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.ezzat.radio_app.audio',
      androidNotificationChannelName: 'تشغيل الراديو',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
  runApp(const RadioApp());
}

class RadioApp extends StatelessWidget {
  const RadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'راديو',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const DialScreen(),
    );
  }
}
