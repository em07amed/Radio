import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';

/// Checks GitHub Releases for a newer build. CI tags each release
/// `build-<N>` and builds the APK with the same build number N.
class UpdateService {
  static const repo = 'em07amed/radio';

  /// Set with --dart-define=STORE=play for the Google Play build.
  /// Play updates the app itself, so in-app updating is disabled there.
  static const isPlayBuild = String.fromEnvironment('STORE') == 'play';

  int? currentBuild;
  String? currentVersion;

  Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    currentBuild = int.tryParse(info.buildNumber);
    currentVersion = info.version;
  }

  /// Returns (build, apkUrl, notes) of the latest release, or null.
  Future<({int build, String url, String notes})?> _latest() async {
    final res = await http.get(
      Uri.parse('https://api.github.com/repos/$repo/releases/latest'),
      headers: {'Accept': 'application/vnd.github+json'},
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 404) {
      throw Exception('مش لاقي الإصدارات (لازم الـ repo يكون Public)');
    }
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final tag = (j['tag_name'] ?? '').toString();
    final build = int.tryParse(tag.replaceFirst('build-', ''));
    final assets = (j['assets'] as List?) ?? [];
    final apk = assets.cast<Map<String, dynamic>>().firstWhere(
        (a) => (a['name'] ?? '').toString().endsWith('.apk'),
        orElse: () => {});
    final url = (apk['browser_download_url'] ?? j['html_url'] ?? '').toString();
    if (build == null || url.isEmpty) return null;
    return (build: build, url: url, notes: (j['body'] ?? '').toString());
  }

  /// [silent]: on app start — only speak up when an update exists.
  Future<void> check(BuildContext context, {bool silent = false}) async {
    if (isPlayBuild) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final latest = await _latest();
      if (!context.mounted) return;
      if (latest == null || latest.build <= (currentBuild ?? 0)) {
        if (!silent) {
          messenger.showSnackBar(SnackBar(
              content: Text('عندك آخر إصدار (build ${currentBuild ?? '?'})')));
        }
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.system_update_rounded,
              color: AppColors.accent, size: 36),
          title: Text('تحديث جديد',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.ink)),
          content: Text(
            'إصدار جديد متاح (build ${latest.build}).\n'
            'انت دلوقتي على build ${currentBuild ?? '?'}.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textDim),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('بعدين', style: TextStyle(color: AppColors.textDim)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: () {
                Navigator.pop(ctx);
                launchUrl(Uri.parse(latest.url),
                    mode: LaunchMode.externalApplication);
              },
              child: const Text('نزّل التحديث'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!silent) {
        messenger.showSnackBar(SnackBar(
            content: Text('تعذر التحقق من التحديثات: '
                '${e.toString().replaceFirst('Exception: ', '')}')));
      }
    }
  }
}
