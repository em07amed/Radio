import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../models/station.dart';
import '../widgets/player_bar.dart';
import '../widgets/station_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('راديو'),
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.radio), text: 'مصر'),
            Tab(icon: Icon(Icons.search), text: 'بحث'),
            Tab(icon: Icon(Icons.favorite), text: 'المفضلة'),
          ]),
        ),
        body: const TabBarView(children: [
          _EgyptTab(),
          _SearchTab(),
          _FavoritesTab(),
        ]),
        bottomNavigationBar: const PlayerBar(),
      ),
    );
  }
}

/// Egyptian stations, sorted by popularity, with a local filter box.
class _EgyptTab extends StatefulWidget {
  const _EgyptTab();
  @override
  State<_EgyptTab> createState() => _EgyptTabState();
}

class _EgyptTabState extends State<_EgyptTab>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Station>> _future;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _future = radioApi.byCountry('EG');
  }

  Future<void> _reload() async {
    setState(() => _future = radioApi.byCountry('EG'));
    await _future;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Station>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _ErrorView(message: '${snap.error}', onRetry: _reload);
        }
        final q = _filter.toLowerCase();
        final list = snap.data!
            .where((s) => q.isEmpty || s.name.toLowerCase().contains(q))
            .toList();
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'فلتر المحطات المصرية...',
                prefixIcon: Icon(Icons.filter_list),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) => StationTile(station: list[i]),
              ),
            ),
          ),
        ]);
      },
    );
  }
}

/// Worldwide search by station name (debounced).
class _SearchTab extends StatefulWidget {
  const _SearchTab();
  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab>
    with AutomaticKeepAliveClientMixin {
  Timer? _debounce;
  List<Station> _results = [];
  bool _loading = false;
  String? _error;

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(q));
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await radioApi.search(q.trim());
      if (mounted) setState(() => _results = r);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: TextField(
          decoration: const InputDecoration(
            hintText: 'ابحث عن أي محطة في العالم...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: _search,
        ),
      ),
      if (_loading) const LinearProgressIndicator(),
      Expanded(
        child: _error != null
            ? Center(child: Text(_error!))
            : ListView.builder(
                itemCount: _results.length,
                itemBuilder: (_, i) => StationTile(station: _results[i]),
              ),
      ),
    ]);
  }
}

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Station>>(
      valueListenable: favoritesService.favorites,
      builder: (context, favs, _) {
        if (favs.isEmpty) {
          return const Center(
            child: Text('مفيش محطات مفضلة لسه\nدوس على ♡ جنب أي محطة',
                textAlign: TextAlign.center),
          );
        }
        return ListView.builder(
          itemCount: favs.length,
          itemBuilder: (_, i) => StationTile(station: favs[i]),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off, size: 48),
        const SizedBox(height: 12),
        Text(message.replaceFirst('Exception: ', ''),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton(onPressed: onRetry, child: const Text('حاول تاني')),
      ]),
    );
  }
}
