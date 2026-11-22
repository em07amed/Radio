import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../services/diag_log.dart';
import '../theme.dart';

/// Shows player state, app errors and the Android log, with a copy button.
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});
  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  static const _ch = MethodChannel('radio/system');
  String _report = 'جاري التحميل...';

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    final st = audioHandler.playbackState.value;
    String logcat;
    try {
      logcat = await _ch.invokeMethod<String>('logcat') ?? '';
    } catch (e) {
      logcat = 'logcat error: $e';
    }
    // Keep the interesting part of the Android log near the top.
    final important = logcat
        .split('\n')
        .where((l) =>
            l.contains('AudioService') ||
            l.contains('audioservice') ||
            l.contains('ExoPlayer') ||
            l.contains('Exception') ||
            l.contains(' E ') ||
            l.contains('ForegroundService') ||
            l.contains('Notification'))
        .join('\n');
    setState(() {
      _report = '''
== Build ==
version ${updateService.currentVersion} build ${updateService.currentBuild}

== Player ==
current: ${audioHandler.current?.name ?? '-'}
playing: ${st.playing}
processing: ${st.processingState.name}
mediaItem: ${audioHandler.mediaItem.value?.title ?? '-'}

== App log ==
${DiagLog.dump()}

== Android log (important) ==
$important

== Android log (full) ==
$logcat
''';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تشخيص'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _build),
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _report));
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('اتنسخ، ابعته لـ Claude')));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: SelectableText(
          _report,
          textDirection: TextDirection.ltr,
          style: TextStyle(
              fontFamily: 'monospace', fontSize: 11, color: AppColors.ink),
        ),
      ),
    );
  }
}
