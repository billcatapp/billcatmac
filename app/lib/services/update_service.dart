import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';

// version.json shape (host at feedUrl, update "version" to trigger update banner):
// {
//   "version": "1.1.0",
//   "download_url": "https://example.com/BillCat-1.1.0.dmg",
//   "release_notes": "What's new",
//   "mandatory": false
// }
class UpdateService {
  static const String feedUrl =
      'https://xawpxbhglzhaibmcpwho.supabase.co/storage/v1/object/public/billcat-updates/version.json';

  /// Returns an [UpdateInfo] if a newer version exists, null otherwise.
  /// Throws [UpdateCheckError] with a human-readable message on failure.
  static Future<UpdateInfo?> checkForUpdate() async {
    final info = await PackageInfo.fromPlatform();
    final current = info.version;

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client.getUrl(Uri.parse(feedUrl));
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw UpdateCheckError('Server returned ${res.statusCode}');
      }
      final body = await res.transform(utf8.decoder).join();
      client.close();

      final data = jsonDecode(body) as Map<String, dynamic>;
      final latest = data['version'] as String;

      if (_isNewer(latest, current)) {
        return UpdateInfo(
          version: latest,
          downloadUrl: data['download_url'] as String,
          releaseNotes: data['release_notes'] as String? ?? '',
          mandatory: data['mandatory'] as bool? ?? false,
        );
      }
      return null;
    } on UpdateCheckError {
      rethrow;
    } catch (e) {
      client.close();
      throw UpdateCheckError('Could not check for updates. Check your internet connection.');
    }
  }

  static bool _isNewer(String latest, String current) {
    // Strip pre-release suffix (e.g. "1.0.0-beta" → "1.0.0")
    String core(String v) => v.split('-').first;
    List<int> parse(String v) =>
        core(v).split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final l = parse(latest);
    final c = parse(current);
    for (int i = 0; i < 3; i++) {
      final lv = i < l.length ? l[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (lv > cv) return true;
      if (lv < cv) return false;
    }
    // Same core version: treat a pre-release as older than release
    final latestIsPre = latest.contains('-');
    final currentIsPre = current.contains('-');
    if (!latestIsPre && currentIsPre) return true;
    return false;
  }

  static Future<String> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// Downloads the zip, extracts it, replaces the running .app, and relaunches.
  /// [onProgress] is called with 0.0–1.0. The app exits at 1.0 and relaunches.
  static Future<void> installUpdate(
    String url,
    void Function(double progress) onProgress,
  ) async {
    final tmpDir = await Directory.systemTemp.createTemp('billcat_update_');
    final zipPath = '${tmpDir.path}/update.zip';

    // ── Download via curl (follows GitHub's multi-step redirect) ─────────────
    onProgress(0.05);

    // Get total size for progress tracking
    int totalBytes = 0;
    try {
      final headResult = await Process.run('curl', ['-sI', '-L', url]);
      final headOutput = headResult.stdout as String;
      final match = RegExp(r'content-length:\s*(\d+)', caseSensitive: false)
          .allMatches(headOutput)
          .lastOrNull;
      if (match != null) totalBytes = int.tryParse(match.group(1)!) ?? 0;
    } catch (_) {}

    // Download with progress polling via file size
    bool downloadComplete = false;
    Timer? pollTimer;
    if (totalBytes > 0) {
      pollTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
        if (downloadComplete) return;
        try {
          final size = File(zipPath).statSync().size;
          if (size > 0) onProgress(0.05 + (size / totalBytes) * 0.80);
        } catch (_) {}
      });
    }

    final dlResult = await Process.run('curl', ['-L', '--silent', '--show-error', '-o', zipPath, url]);
    downloadComplete = true;
    pollTimer?.cancel();

    if (dlResult.exitCode != 0) {
      throw UpdateCheckError('Download failed. Check your connection.');
    }

    // ── Extract ───────────────────────────────────────────────────────────────
    onProgress(0.88);
    final extractDir = '${tmpDir.path}/extracted';
    await Directory(extractDir).create();
    final unzip = await Process.run('unzip', ['-q', zipPath, '-d', extractDir]);
    if (unzip.exitCode != 0) throw UpdateCheckError('Failed to extract update.');

    // Find the .app inside extracted dir
    final entries = Directory(extractDir).listSync();
    final appEntry = entries.whereType<Directory>()
        .where((d) => d.path.endsWith('.app'))
        .toList();
    if (appEntry.isEmpty) throw UpdateCheckError('No .app found in update package.');
    final newAppPath = appEntry.first.path;

    // ── Replace & Relaunch ────────────────────────────────────────────────────
    onProgress(0.95);
    // Resolve the running .app bundle (3 levels up from the executable)
    final execPath = Platform.resolvedExecutable;
    final appPath = File(execPath).parent.parent.parent.path;

    // Write a detached script that waits for us to exit, then replaces the app
    final scriptPath = '${Directory.systemTemp.path}/billcat_updater_${DateTime.now().millisecondsSinceEpoch}.sh';
    final logPath = '${Directory.systemTemp.path}/billcat_update.log';
    await File(scriptPath).writeAsString(
      '#!/bin/bash\n'
      'exec >>${_esc(logPath)} 2>&1\n'
      'echo "[\$(date)] updater started, waiting for BillCat to quit..."\n'
      'for i in \$(seq 1 40); do sleep 0.5; pgrep -xq "BillCat" || break; done\n'
      'echo "[\$(date)] BillCat exited, replacing app..."\n'
      'rm -rf ${_esc(appPath)}\n'
      'cp -R ${_esc(newAppPath)} ${_esc(appPath)}\n'
      'xattr -cr ${_esc(appPath)}\n'
      'echo "[\$(date)] launching new app..."\n'
      'open ${_esc(appPath)}\n'
      'echo "[\$(date)] done"\n'
      'rm -rf ${_esc(tmpDir.path)}\n'
      'rm -- "\$0"\n',
    );
    await Process.run('chmod', ['+x', scriptPath]);

    onProgress(1.0);
    // nohup detaches the script from this process so it survives after exit(0)
    await Process.run('bash', ['-c', 'nohup bash ${_esc(scriptPath)} >/dev/null 2>&1 &']);
    await Future.delayed(const Duration(milliseconds: 500));
    exit(0);
  }

  // Shell-escape a path by wrapping in single quotes
  static String _esc(String path) => "'${path.replaceAll("'", "'\\''")}'";
}

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;
  final bool mandatory;

  const UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.mandatory,
  });
}

class UpdateCheckError implements Exception {
  final String message;
  const UpdateCheckError(this.message);
  @override
  String toString() => message;
}
