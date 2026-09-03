import 'package:flutter/foundation.dart';

/// Centralized API & Server Configuration for Admin HQ with instant Local vs Live Render toggle
class ApiConstants {
  /// 🔘 SWITCH HERE: Set to `true` for Local Backend, or `false` for Live Render Backend
  static const bool useLocalBackend = false;

  /// Live Render Production Base URL
  static const String liveRenderUrl = 'https://neurofit-full.onrender.com';

  /// Local Backend Configuration
  static const int serverPort = 5000;
  static const String serverHost = 'localhost';

  /// Returns active base URL based on toggle
  static String get baseUrl {
    if (useLocalBackend) {
      return 'http://$serverHost:$serverPort';
    }
    return liveRenderUrl;
  }

  /// REST API base URL (e.g. http://localhost:5000/api or https://neurofit-full.onrender.com/api)
  static String get apiBaseUrl {
    return '$baseUrl/api';
  }

  /// Real-time Socket.io server URL
  static String get socketUrl {
    return baseUrl;
  }

  /// Candidate Base URLs list for smart fallback
  static List<String> get candidateBaseUrls {
    if (useLocalBackend) {
      return [
        'http://$serverHost:$serverPort',
        'http://192.168.1.34:$serverPort',
        'http://10.0.2.2:$serverPort',
        liveRenderUrl,
      ];
    } else {
      return [
        liveRenderUrl,
        'http://$serverHost:$serverPort',
        'http://192.168.1.34:$serverPort',
      ];
    }
  }
}
