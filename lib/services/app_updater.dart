import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Checks GitHub releases for new APKs and installs them on the phone.
/// Uses Android's PackageInstaller API via process_run or direct Intent.
class AppUpdater {
  static const _owner = 'paumkim';
  static const _repo = 'zomi-website';
  static const _lastCheckKey = 'last_update_check';
  static const _currentVersion = '1.0.1';

  static String? _cachedLatestVersion;

  /// Check if a newer version is available on GitHub.
  static Future<String?> checkForUpdate() async {
    try {
      final uri = Uri.parse(
        'https://api.github.com/repos/$_owner/$_repo/releases/latest');
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tag = data['tag_name'] as String?;
        if (tag != null && tag != _cachedLatestVersion) {
          _cachedLatestVersion = tag;
          // Compare versions
          if (tag.compareTo(_currentVersion) > 0) {
            return tag;
          }
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
    return null;
  }

  /// Download and install the latest APK from GitHub releases.
  static Future<bool> downloadAndInstall(String version) async {
    try {
      final url = 'https://github.com/$_owner/$_repo/releases/download/$version/app-release.apk';
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(minutes: 5));

      if (response.statusCode != 200) return false;

      // Save to a temp file
      final tempDir = Directory.systemTemp;
      final apkFile = File('${tempDir.path}/pau_update.apk');
      await apkFile.writeAsBytes(response.bodyBytes);

      // Install via Intent (requires package:open_file or process_run)
      // For now, save the path for manual installation
      debugPrint('APK downloaded to: ${apkFile.path}');

      // Try to open with system installer
      if (Platform.isAndroid) {
        // Using Process to invoke the package installer
        await Process.run('am', [
          'start', '-a', 'android.intent.action.VIEW',
          '-d', 'file://${apkFile.path}',
          '-t', 'application/vnd.android.package-archive',
        ]);
      }

      return true;
    } catch (e) {
      debugPrint('Download/install failed: $e');
      return false;
    }
  }

  /// Save the last check time to avoid rate limiting.
  static Future<void> markChecked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());
  }
}
