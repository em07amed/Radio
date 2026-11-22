import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../models/station.dart';
import '../theme.dart';
import 'equalizer.dart';

Future<void> playStation(BuildContext context, Station s) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await favoritesService.saveLast(s);
    radioApi.reportClick(s.uuid);
    await audioHandler.playStation(s);
  } catch (e) {
    messenger.showSnackBar(SnackBar(
      content: Text(e.toString().replaceFirst('Exception: ', '')),
    ));
  }
}

/// Station logo, or a soft gradient with the first letter when missing.
class StationLogo extends StatelessWidget {
  final Station station;
  final double size;
  final double radius;
  const StationLogo(
      {super.key, required this.station, this.size = 48, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    final letter = station.name.isEmpty ? '?' : station.name.characters.first;
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(gradient: AppColors.forName(station.name)),
      child: Text(letter.toUpperCase(),
          style: TextStyle(
              fontSize: size * 0.42,
              fontWeight: FontWeight.w800,
              color: Colors.white)),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: station.favicon.isEmpty
          ? fallback
          : Container(
              width: size,
              height: size,
              color: Colors.white,
              child: CachedNetworkImage(
                imageUrl: station.favicon,
                fit: BoxFit.cover,
                placeholder: (_, __) => fallback,
                errorWidget: (_, __, ___) => fallback,
              ),
            ),
    );
  }
}

class FavoriteButton extends StatelessWidget {
  final Station station;
  final double size;
  const FavoriteButton({super.key, required this.station, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Station>>(
      valueListenable: favoritesService.favorites,
      builder: (_, favs, __) {
        final fav = favs.contains(station);
        return IconButton(
          iconSize: size,
          onPressed: () => favoritesService.toggle(station),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Icon(
              fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(fav),
              color: fav ? AppColors.accent : AppColors.textDim,
            ),
          ),
        );
      },
    );
  }
}

/// White card row used in the stations list.
class StationTile extends StatelessWidget {
  final Station station;
  final VoidCallback? onPlayed;
  const StationTile({super.key, required this.station, this.onPlayed});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (_, item) => StreamBuilder<PlaybackState>(
        stream: audioHandler.playbackState,
        builder: (context, st) {
          final isCurrent = item.data?.id == station.url;
          final playing = isCurrent && (st.data?.playing ?? false);
          final f = station.frequency;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Material(
              color: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: isCurrent ? AppColors.accent : AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  playStation(context, station);
                  onPlayed?.call();
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(children: [
                    StationLogo(station: station),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(station.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.ink)),
                          const SizedBox(height: 2),
                          Text(
                              f != null
                                  ? 'FM ${f.toStringAsFixed(1)}'
                                  : station.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: f != null
                                      ? AppColors.accent
                                      : AppColors.textDim)),
                        ],
                      ),
                    ),
                    if (isCurrent)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Equalizer(
                            playing: playing, height: 16, barWidth: 3),
                      ),
                    FavoriteButton(station: station),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
