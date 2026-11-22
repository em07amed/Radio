import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/station.dart';

/// Thin client for the free Radio Browser API (https://www.radio-browser.info).
/// No API key needed. Tries several mirrors in case one is down.
class RadioApi {
  static const _mirrors = [
    'https://de1.api.radio-browser.info',
    'https://nl1.api.radio-browser.info',
    'https://at1.api.radio-browser.info',
    'https://de2.api.radio-browser.info',
  ];
  static const _headers = {'User-Agent': 'EzzatRadio/1.0'};
  static const _timeout = Duration(seconds: 10);

  String? _workingMirror;

  Future<List<dynamic>> _get(String path, Map<String, String> query) async {
    final ordered = [
      if (_workingMirror != null) _workingMirror!,
      ..._mirrors.where((m) => m != _workingMirror),
    ];
    Object? lastError;
    for (final base in ordered) {
      try {
        final uri = Uri.parse('$base$path').replace(queryParameters: query);
        final res = await http.get(uri, headers: _headers).timeout(_timeout);
        if (res.statusCode == 200) {
          _workingMirror = base;
          return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
        }
        lastError = 'HTTP ${res.statusCode}';
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('تعذر الاتصال بخادم المحطات ($lastError)');
  }

  List<Station> _parse(List<dynamic> raw) {
    final seen = <String>{};
    final out = <Station>[];
    for (final item in raw) {
      final s = Station.fromJson(item as Map<String, dynamic>);
      if (s.url.isEmpty || s.name.isEmpty) continue;
      // Radio Browser has many duplicate entries for the same station.
      if (seen.add(s.name.toLowerCase())) out.add(s);
    }
    return out;
  }

  final Map<String, List<Station>> _countryCache = {};

  Future<List<Station>> byCountry(String code,
      {int limit = 200, bool refresh = false}) async {
    if (!refresh && _countryCache[code] != null) return _countryCache[code]!;
    final raw = await _get('/json/stations/bycountrycodeexact/$code', {
      'hidebroken': 'true',
      'order': 'clickcount',
      'reverse': 'true',
      'limit': '$limit',
    });
    return _countryCache[code] = _parse(raw);
  }

  Future<List<Station>> search(String name, {int limit = 100}) async {
    final raw = await _get('/json/stations/search', {
      'name': name,
      'hidebroken': 'true',
      'order': 'clickcount',
      'reverse': 'true',
      'limit': '$limit',
    });
    return _parse(raw);
  }

  /// Tells Radio Browser a station was played (helps its popularity ranking).
  void reportClick(String uuid) {
    final base = _workingMirror ?? _mirrors.first;
    http
        .get(Uri.parse('$base/json/url/$uuid'), headers: _headers)
        .timeout(_timeout)
        .ignore();
  }
}
