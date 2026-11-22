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

  @override
  bool operator ==(Object other) => other is Station && other.uuid == uuid;

  @override
  int get hashCode => uuid.hashCode;
}
