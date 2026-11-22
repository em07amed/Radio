import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../models/station.dart';
import 'station_tile.dart';

/// Bottom "now playing" bar. Shows the last station on launch (not auto-played).
class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, stateSnap) {
        final state = stateSnap.data;
        final Station? station =
            audioHandler.current ?? favoritesService.lastStation;
        if (station == null) return const SizedBox.shrink();

        final playing = state?.playing ?? false;
        final loading = state?.processingState ==
                AudioProcessingState.loading ||
            state?.processingState == AudioProcessingState.buffering;
        final scheme = Theme.of(context).colorScheme;

        return Material(
          color: scheme.surfaceContainerHigh,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  StationLogo(station: station, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(station.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          loading
                              ? 'جاري التحميل...'
                              : playing
                                  ? 'شغال الآن'
                                  : 'متوقف',
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  _SleepButton(),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: loading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : IconButton.filled(
                            icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                            onPressed: () {
                              if (playing) {
                                audioHandler.pause();
                              } else if (audioHandler.current == null) {
                                playStation(context, station);
                              } else {
                                audioHandler.play();
                              }
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SleepButton extends StatefulWidget {
  @override
  State<_SleepButton> createState() => _SleepButtonState();
}

class _SleepButtonState extends State<_SleepButton> {
  static const _options = [15, 30, 45, 60, 90];

  @override
  Widget build(BuildContext context) {
    final active = audioHandler.sleepAt != null;
    return PopupMenuButton<int>(
      tooltip: 'مؤقت الإيقاف',
      icon: Icon(active ? Icons.bedtime : Icons.bedtime_outlined,
          color: active ? Theme.of(context).colorScheme.primary : null),
      onSelected: (min) {
        final messenger = ScaffoldMessenger.of(context);
        if (min == 0) {
          audioHandler.cancelSleepTimer();
          messenger.showSnackBar(
              const SnackBar(content: Text('تم إلغاء مؤقت الإيقاف')));
        } else {
          audioHandler.setSleepTimer(Duration(minutes: min));
          messenger.showSnackBar(
              SnackBar(content: Text('الراديو هيقف بعد $min دقيقة')));
        }
        setState(() {});
      },
      itemBuilder: (_) => [
        for (final m in _options)
          PopupMenuItem(value: m, child: Text('بعد $m دقيقة')),
        if (active)
          const PopupMenuItem(value: 0, child: Text('إلغاء المؤقت')),
      ],
    );
  }
}
