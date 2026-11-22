import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../models/station.dart';

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

class StationLogo extends StatelessWidget {
  final Station station;
  final double size;
  const StationLogo({super.key, required this.station, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(Icons.radio, size: size * 0.55),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: station.favicon.isEmpty
          ? fallback
          : CachedNetworkImage(
              imageUrl: station.favicon,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, __) => fallback,
              errorWidget: (_, __, ___) => fallback,
            ),
    );
  }
}

class StationTile extends StatelessWidget {
  final Station station;
  const StationTile({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Station>>(
      valueListenable: favoritesService.favorites,
      builder: (context, favs, _) {
        final isFav = favs.contains(station);
        return StreamBuilder(
          stream: audioHandler.mediaItem,
          builder: (context, snap) {
            final isCurrent = snap.data?.id == station.url;
            return ListTile(
              leading: StationLogo(station: station),
              title: Text(
                station.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : null,
                  color: isCurrent
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              subtitle: Text(station.subtitle,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                color: isFav ? Colors.redAccent : null,
                onPressed: () => favoritesService.toggle(station),
              ),
              onTap: () => playStation(context, station),
            );
          },
        );
      },
    );
  }
}
