import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

enum ConnectivityStatus { online, offline, serverUnreachable }

class ConnectivityService extends ChangeNotifier {
  ConnectivityStatus _status = ConnectivityStatus.online;
  Timer? _checkTimer;

  ConnectivityStatus get status => _status;
  bool get isOnline => _status == ConnectivityStatus.online;
  bool get isOffline => _status == ConnectivityStatus.offline;

  void startMonitoring() {
    _checkConnectivity();
    _checkTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkConnectivity());
  }

  void stopMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      final online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _status = online ? ConnectivityStatus.online : ConnectivityStatus.offline;
    } catch (_) {
      _status = ConnectivityStatus.offline;
    }
    notifyListeners();
  }

  Future<bool> checkOllamaReachable(String url) async {
    try {
      final result = await HttpClient()
          .getUrl(Uri.parse(url.replaceAll('/api/generate', '')))
          .timeout(const Duration(seconds: 2));
      final response = await result.close();
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
