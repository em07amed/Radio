import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/audio_handler.dart';
import 'services/favorites_service.dart';
import 'services/radio_api.dart';

late final RadioAudioHandler audioHandler;
final favoritesService = FavoritesService();
final radioApi = RadioApi();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFE53935),
      brightness: Brightness.dark,
    );
    return MaterialApp(
      title: 'راديو',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: scheme, useMaterial3: true),
      // Arabic UI, right-to-left.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const HomeScreen(),
    );
  }
}
