import 'dart:async';
import 'dart:math';
import 'dart:ui' show FontFeature;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../models/station.dart';
import '../services/background_permissions.dart';
import '../theme.dart';
import '../widgets/station_tile.dart';
import 'stations_screen.dart';
import 'diagnostics_screen.dart';

/// Main screen: big frequency readout + a curved tuning dial.
/// Drag the dial to move between stations; it snaps and plays.
class DialScreen extends StatefulWidget {
  const DialScreen({super.key});
  @override
  State<DialScreen> createState() => _DialScreenState();
}

class _DialScreenState extends State<DialScreen>
    with SingleTickerProviderStateMixin {
  static const double slotPx = 64; // finger distance between two stations
  static bool _checkedUpdate = false;

  List<Station> _stations = [];
  bool _loading = true;
  String? _error;

  double _pos = 0; // continuous station index under the needle
  int _lastTick = 0;
  bool _dragging = false;

  late final AnimationController _snap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  )..addListener(() => setState(() => _pos = _snapAnim.value));
  Animation<double> _snapAnim = const AlwaysStoppedAnimation<double>(0.0);
  StreamSubscription<MediaItem?>? _itemSub;

  int get _index =>
      _stations.isEmpty ? 0 : _pos.round().clamp(0, _stations.length - 1);
  Station? get _shown => _stations.isEmpty ? null : _stations[_index];

  @override
  void initState() {
    super.initState();
    _load();
    // Quietly look for a newer build once per app launch.
    if (!_checkedUpdate) {
      _checkedUpdate = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await BackgroundPermissions.ensure(context);
        if (mounted) updateService.check(context, silent: true);
      });
    }
    // Keep the dial in sync when a station is picked from the list screen.
    _itemSub = audioHandler.mediaItem.listen((m) {
      final cur = audioHandler.current;
      if (m == null || cur == null || _stations.isEmpty || _dragging) return;
      final i = _ensureInList(cur);
      if (i != _index) _animateTo(i, play: false);
    });
  }

  @override
  void dispose() {
    _itemSub?.cancel();
    _snap.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await radioApi.byCountry('EG');
      // Stations with a known FM frequency first, in dial order.
      final known = list.where((s) => s.frequency != null).toList()
        ..sort((a, b) => a.frequency!.compareTo(b.frequency!));
      final rest = list.where((s) => s.frequency == null);
      _stations = [...known, ...rest];
      final start = audioHandler.current ?? favoritesService.lastStation;
      final i = start == null ? 0 : _ensureInList(start);
      setState(() {
        _pos = i.toDouble();
        _lastTick = i;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  /// Returns the index of [s], inserting it (e.g. from search) if missing.
  int _ensureInList(Station s) {
    final i = _stations.indexWhere((x) => x.url == s.url || x == s);
    if (i >= 0) return i;
    final f = s.frequency;
    var at = _stations.length;
    if (f != null) {
      at = _stations.indexWhere(
          (x) => x.frequency == null || x.frequency! > f);
      if (at < 0) at = _stations.length;
    }
    _stations.insert(at, s);
    if (at <= _pos.round() && _stations.length > 1) _pos += 1;
    return at;
  }

  void _animateTo(int i, {bool play = true}) {
    if (_stations.isEmpty) return;
    i = i.clamp(0, _stations.length - 1);
    _snapAnim = Tween<double>(begin: _pos, end: i.toDouble()).animate(
        CurvedAnimation(parent: _snap, curve: Curves.easeOutCubic));
    _snap.forward(from: 0).then((_) {
      if (play && mounted) _playIndex(i);
    });
  }

  void _playIndex(int i) {
    final s = _stations[i];
    final st = audioHandler.playbackState.value;
    if (audioHandler.current == s && st.playing) return;
    playStation(context, s);
  }

  void _togglePlay(bool playing) {
    final s = _shown;
    if (s == null) return;
    if (playing && audioHandler.current == s) {
      audioHandler.pause();
    } else if (audioHandler.current != s ||
        audioHandler.playbackState.value.processingState ==
            AudioProcessingState.idle) {
      playStation(context, s);
    } else {
      audioHandler.play();
    }
  }

  // ---- drag handling ----
  void _onDragStart(DragStartDetails _) {
    _snap.stop();
    _dragging = true;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_stations.isEmpty) return;
    setState(() {
      _pos = (_pos - d.delta.dx / slotPx)
          .clamp(0.0, (_stations.length - 1).toDouble());
    });
    if (_pos.round() != _lastTick) {
      _lastTick = _pos.round();
      HapticFeedback.selectionClick();
    }
  }

  void _onDragEnd(DragEndDetails d) {
    _dragging = false;
    final fling = -d.velocity.pixelsPerSecond.dx / slotPx * 0.18;
    _animateTo((_pos + fling).round());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: Column(children: [
            _header(context),
            Expanded(child: _body()),
            _controls(),
            const SizedBox(height: 28),
          ]),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
      child: Row(children: [
        Text('Radio',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.5)),
        const Spacer(),
        const SleepButton(),
        const _MenuButton(),
        IconButton(
          tooltip: 'كل المحطات',
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 30, color: AppColors.textDim),
          onPressed: _stations.isEmpty
              ? null
              : () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => StationsScreen(egypt: List.of(_stations)))),
        ),
      ]),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off_rounded,
              size: 44, color: AppColors.textDim),
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textDim)),
          const SizedBox(height: 12),
          TextButton(
              onPressed: _load,
              child: const Text('حاول تاني',
                  style: TextStyle(color: AppColors.accent))),
        ]),
      );
    }
    final s = _shown!;
    return Column(children: [
      const SizedBox(height: 36),
      _Readout(station: s),
      const SizedBox(height: 8),
      StreamBuilder<PlaybackState>(
        stream: audioHandler.playbackState,
        builder: (_, snap) {
          final st = snap.data;
          final isCur = audioHandler.current == s;
          final loading = isCur &&
              (st?.processingState == AudioProcessingState.loading ||
                  st?.processingState == AudioProcessingState.buffering);
          final live = isCur && (st?.playing ?? false) && !loading;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(s.frequency != null ? 'FM' : 'WEB',
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 1)),
              const SizedBox(width: 10),
              Text(
                  loading
                      ? 'TUNING…'
                      : live
                          ? 'LIVE'
                          : '',
                  style: TextStyle(
                      color: AppColors.textDim,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5)),
              FavoriteButton(station: s, size: 20),
            ],
          );
        },
      ),
      Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: CustomPaint(
            size: Size.infinite,
            painter: _DialPainter(
              pos: _pos,
              labels: [for (final x in _stations) _label(x)],
              slotPx: slotPx,
            ),
          ),
        ),
      ),
    ]);
  }

  static String _label(Station s) {
    final f = s.frequency;
    if (f != null) return f.toStringAsFixed(1);
    final w = s.name.split(RegExp(r'\s+')).first;
    return w.length > 7 ? w.substring(0, 7) : w;
  }

  Widget _controls() {
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (_, snap) {
        final st = snap.data;
        final isCur = _shown != null && audioHandler.current == _shown;
        final playing = isCur && (st?.playing ?? false);
        final loading = isCur &&
            (st?.processingState == AudioProcessingState.loading ||
                st?.processingState == AudioProcessingState.buffering);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              iconSize: 40,
              color: AppColors.ink,
              icon: const Icon(Icons.skip_previous_rounded),
              onPressed: _stations.isEmpty
                  ? null
                  : () => _animateTo(_index - 1),
            ),
            GestureDetector(
              onTap: () => _togglePlay(playing),
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 24,
                        offset: Offset(0, 10)),
                  ],
                ),
                child: loading
                    ? Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: AppColors.ink),
                      )
                    : Icon(
                        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 44,
                        color: AppColors.ink,
                      ),
              ),
            ),
            IconButton(
              iconSize: 40,
              color: AppColors.ink,
              icon: const Icon(Icons.skip_next_rounded),
              onPressed: _stations.isEmpty
                  ? null
                  : () => _animateTo(_index + 1),
            ),
          ],
        );
      },
    );
  }
}

/// Station name + big frequency, like "088.5" with a faded leading zero.
class _Readout extends StatelessWidget {
  final Station station;
  const _Readout({required this.station});

  @override
  Widget build(BuildContext context) {
    final f = station.frequency;
    final big = TextStyle(
      fontSize: 88,
      fontWeight: FontWeight.w500,
      height: 1.0,
      letterSpacing: -4,
      color: AppColors.ink,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Column(
        key: ValueKey(station.uuid),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              station.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textDim,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: f != null
                ? RichText(
                    text: TextSpan(style: big, children: [
                      if (f < 100)
                        TextSpan(
                            text: '0',
                            style: TextStyle(color: AppColors.inkFaded)),
                      TextSpan(text: f.toStringAsFixed(1)),
                    ]),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(station.name,
                          maxLines: 1,
                          style: big.copyWith(
                              fontSize: 56, letterSpacing: -1.5)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Draws the curved dial: tick marks on an arc, station labels, and the
/// fixed orange needle with a white knob in the centre.
class _DialPainter extends CustomPainter {
  final double pos;
  final List<String> labels;
  final double slotPx;
  final bool dark = AppColors.dark;
  _DialPainter({required this.pos, required this.labels, required this.slotPx});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w * 1.3;
    final top = h * 0.36; // y of the arc's highest point
    final c = Offset(w / 2, top + r);
    final slotAngle = slotPx / r;
    final maxA = asin(min(1.0, (w / 2) / r)) + 0.04;
    final n = labels.length;

    Offset at(double angle, double radius) =>
        c + Offset(sin(angle), -cos(angle)) * radius;

    // Dial body.
    final body = Rect.fromLTWH(0, top, w, h - top);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.dialTop, AppColors.bg],
        ).createShader(body),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.border,
    );

    // Inner faint "grill" ticks.
    final grill = Paint()
      ..strokeWidth = 1
      ..color = AppColors.ink.withValues(alpha: 0.06);
    const step = 0.1;
    for (var v = (pos - 6).floorToDouble(); v <= pos + 6; v += step) {
      final a = (v - pos) * slotAngle;
      if (a.abs() > maxA) continue;
      canvas.drawLine(at(a, r - 34), at(a, r - 64), grill);
    }

    // Main ticks: 5 per station, longer at each station.
    final first = ((pos - 8) * 5).floor();
    final last = ((pos + 8) * 5).ceil();
    for (var k = first; k <= last; k++) {
      final v = k / 5;
      if (v < 0 || v > n - 1) continue;
      final a = (v - pos) * slotAngle;
      if (a.abs() > maxA) continue;
      final major = k % 5 == 0;
      final fade = (1 - a.abs() / maxA).clamp(0.0, 1.0);
      final p = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = major ? 2 : 1
        ..color = AppColors.ink.withValues(alpha: (major ? 0.55 : 0.25) * fade);
      canvas.drawLine(at(a, r - 6), at(a, r - (major ? 24 : 13)), p);
    }

    // Station labels above the arc, rotated to follow it.
    final sel = pos.round();
    for (var i = max(0, pos.floor() - 6); i <= min(n - 1, pos.ceil() + 6); i++) {
      final a = (i - pos) * slotAngle;
      if (a.abs() > maxA) continue;
      final fade = (1 - a.abs() / maxA).clamp(0.0, 1.0);
      final isSel = i == sel;
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            fontSize: isSel ? 12 : 11,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
            color: (isSel ? AppColors.ink : AppColors.textDim)
                .withValues(alpha: isSel ? 1 : 0.9 * fade),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = at(a, r + 20);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(a);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Needle.
    final cx = w / 2;
    final needle = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, top - 58), Offset(cx, top + 44), needle);
    canvas.drawCircle(Offset(cx, top - 62), 3, Paint()..color = AppColors.accent);

    // Knob.
    final knob = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, top + 10), width: 20, height: 44),
      const Radius.circular(9),
    );
    canvas.drawShadow(Path()..addRRect(knob), Colors.black, 6, false);
    canvas.drawRRect(knob, Paint()..color = AppColors.card);
    canvas.drawRRect(
      knob,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.border,
    );
    canvas.drawLine(Offset(cx, top - 4), Offset(cx, top + 24), needle);
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.pos != pos || old.labels.length != labels.length ||
      old.dark != dark;
}

class SleepButton extends StatefulWidget {
  const SleepButton({super.key});
  @override
  State<SleepButton> createState() => _SleepButtonState();
}

class _SleepButtonState extends State<SleepButton> {
  static const _options = [15, 30, 45, 60, 90];

  @override
  Widget build(BuildContext context) {
    final active = audioHandler.sleepAt != null;
    return PopupMenuButton<int>(
      tooltip: 'مؤقت الإيقاف',
      icon: Icon(active ? Icons.bedtime_rounded : Icons.bedtime_outlined,
          color: active ? AppColors.accent : AppColors.textDim),
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

/// Theme mode + update check + version.
class _MenuButton extends StatelessWidget {
  const _MenuButton();

  @override
  Widget build(BuildContext context) {
    final mode = themeController.mode.value;
    PopupMenuItem<String> themeItem(ThemeMode m, IconData icon, String label) =>
        PopupMenuItem(
          value: 'theme_${m.name}',
          child: Row(children: [
            Icon(icon, size: 20, color: AppColors.ink),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(color: AppColors.ink))),
            if (mode == m)
              const Icon(Icons.check_rounded, size: 18, color: AppColors.accent),
          ]),
        );

    return PopupMenuButton<String>(
      tooltip: 'الإعدادات',
      icon: Icon(Icons.more_vert_rounded, color: AppColors.textDim),
      onSelected: (v) {
        switch (v) {
          case 'theme_system':
            themeController.set(ThemeMode.system);
          case 'theme_light':
            themeController.set(ThemeMode.light);
          case 'theme_dark':
            themeController.set(ThemeMode.dark);
          case 'update':
            updateService.check(context);
          case 'diag':
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const DiagnosticsScreen()));
        }
      },
      itemBuilder: (_) => [
        themeItem(ThemeMode.system, Icons.brightness_auto_rounded, 'زي الموبايل'),
        themeItem(ThemeMode.light, Icons.light_mode_rounded, 'فاتح'),
        themeItem(ThemeMode.dark, Icons.dark_mode_rounded, 'غامق'),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'update',
          child: Row(children: [
            Icon(Icons.system_update_rounded, size: 20, color: AppColors.ink),
            const SizedBox(width: 12),
            Text('تحقق من التحديثات', style: TextStyle(color: AppColors.ink)),
          ]),
        ),
        PopupMenuItem(
          value: 'diag',
          child: Row(children: [
            Icon(Icons.bug_report_outlined, size: 20, color: AppColors.ink),
            const SizedBox(width: 12),
            Text('تشخيص', style: TextStyle(color: AppColors.ink)),
          ]),
        ),
        PopupMenuItem(
          enabled: false,
          child: Text(
            'الإصدار ${updateService.currentVersion ?? '?'} '
            '(build ${updateService.currentBuild ?? '?'})',
            style: TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
