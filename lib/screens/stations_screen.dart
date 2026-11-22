import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../models/station.dart';
import '../theme.dart';
import '../widgets/station_tile.dart';

/// Opened from the chevron on the dial screen: Egypt list, worldwide search,
/// favorites. Tapping a station plays it and returns to the dial.
class StationsScreen extends StatelessWidget {
  final List<Station> egypt;
  const StationsScreen({super.key, required this.egypt});

  @override
  Widget build(BuildContext context) {
    void back() => Navigator.of(context).pop();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('المحطات',
                style: TextStyle(fontWeight: FontWeight.w800)),
            bottom: const TabBar(
              indicatorColor: AppColors.accent,
              labelColor: AppColors.ink,
              unselectedLabelColor: AppColors.textDim,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'مصر'),
                Tab(text: 'بحث'),
                Tab(text: 'المفضلة'),
              ],
            ),
          ),
          body: TabBarView(children: [
            _FilterList(stations: egypt, onPlayed: back),
            _SearchTab(onPlayed: back),
            ValueListenableBuilder<List<Station>>(
              valueListenable: favoritesService.favorites,
              builder: (_, favs, __) => favs.isEmpty
                  ? const Center(
                      child: Text('مفيش محطات مفضلة لسه\nدوس على ♡ جنب أي محطة',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textDim)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: favs.length,
                      itemBuilder: (_, i) =>
                          StationTile(station: favs[i], onPlayed: back),
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}

InputDecoration _searchDecoration(String hint, IconData icon) =>
    InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textDim),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );

class _FilterList extends StatefulWidget {
  final List<Station> stations;
  final VoidCallback onPlayed;
  const _FilterList({required this.stations, required this.onPlayed});
  @override
  State<_FilterList> createState() => _FilterListState();
}

class _FilterListState extends State<_FilterList> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase();
    final list = widget.stations
        .where((s) => q.isEmpty || s.name.toLowerCase().contains(q))
        .toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: TextField(
          decoration: _searchDecoration('فلتر المحطات...', Icons.filter_list),
          onChanged: (v) => setState(() => _q = v),
        ),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) =>
              StationTile(station: list[i], onPlayed: widget.onPlayed),
        ),
      ),
    ]);
  }
}

class _SearchTab extends StatefulWidget {
  final VoidCallback onPlayed;
  const _SearchTab({required this.onPlayed});
  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  Timer? _debounce;
  List<Station> _results = [];
  bool _loading = false;
  String? _error;

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
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: TextField(
          decoration:
              _searchDecoration('ابحث عن أي محطة في العالم...', Icons.search),
          textInputAction: TextInputAction.search,
          onChanged: (q) {
            _debounce?.cancel();
            _debounce =
                Timer(const Duration(milliseconds: 500), () => _search(q));
          },
          onSubmitted: _search,
        ),
      ),
      if (_loading) const LinearProgressIndicator(color: AppColors.accent),
      Expanded(
        child: _error != null
            ? Center(child: Text(_error!.replaceFirst('Exception: ', '')))
            : ListView.builder(
                itemCount: _results.length,
                itemBuilder: (_, i) => StationTile(
                    station: _results[i], onPlayed: widget.onPlayed),
              ),
      ),
    ]);
  }
}
