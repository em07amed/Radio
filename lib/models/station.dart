class Station {
  final String uuid;
  final String name;
  final String url;
  final String favicon;
  final String tags;
  final String country;
  final String codec;
  final int bitrate;

  const Station({
    required this.uuid,
    required this.name,
    required this.url,
    this.favicon = '',
    this.tags = '',
    this.country = '',
    this.codec = '',
    this.bitrate = 0,
  });

  factory Station.fromJson(Map<String, dynamic> j) {
    final resolved = (j['url_resolved'] ?? '').toString().trim();
    return Station(
      uuid: (j['stationuuid'] ?? '').toString(),
      name: (j['name'] ?? '').toString().trim(),
      url: resolved.isNotEmpty ? resolved : (j['url'] ?? '').toString().trim(),
      favicon: (j['favicon'] ?? '').toString().trim(),
      tags: (j['tags'] ?? '').toString(),
      country: (j['country'] ?? '').toString(),
      codec: (j['codec'] ?? '').toString(),
      bitrate: (j['bitrate'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'stationuuid': uuid,
        'name': name,
        'url_resolved': url,
        'favicon': favicon,
        'tags': tags,
        'country': country,
        'codec': codec,
        'bitrate': bitrate,
      };

  /// First two tags + bitrate, for the list subtitle.
  String get subtitle {
    final t = tags
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(2)
        .join(' • ');
    final parts = <String>[
      if (t.isNotEmpty) t,
      if (bitrate > 0) '$bitrate kbps',
    ];
    return parts.isEmpty ? country : parts.join('  ·  ');
  }

  /// FM frequency parsed from the name or tags (e.g. "Nogoum FM 100.6"),
  /// or null when the station doesn't mention one.
  double? get frequency {
    final re = RegExp(r'(?<![\d.])(8[7-9]|9\d|10[0-8])[.,](\d)(?!\d)');
    for (final src in [name, tags]) {
      final m = re.firstMatch(src);
      if (m != null) {
        final f = double.parse('${m.group(1)}.${m.group(2)}');
        if (f >= 87.5 && f <= 108.0) return f;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) => other is Station && other.uuid == uuid;

  @override
  int get hashCode => uuid.hashCode;
}
