import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/station.dart';

/// Favorites + last played station, stored locally.
class FavoritesService {
  static const _favKey = 'favorites';
  static const _lastKey = 'last_station';

  final ValueNotifier<List<Station>> favorites = ValueNotifier([]);
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getStringList(_favKey) ?? [];
    favorites.value = raw
        .map((e) => Station.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  bool isFavorite(Station s) => favorites.value.contains(s);

  Future<void> toggle(Station s) async {
    final list = [...favorites.value];
    list.contains(s) ? list.remove(s) : list.add(s);
    favorites.value = list;
    await _prefs.setStringList(
        _favKey, list.map((e) => jsonEncode(e.toJson())).toList());
  }

  Station? get lastStation {
    final raw = _prefs.getString(_lastKey);
    if (raw == null) return null;
    return Station.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveLast(Station s) =>
      _prefs.setString(_lastKey, jsonEncode(s.toJson()));
}
