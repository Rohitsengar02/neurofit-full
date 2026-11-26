import 'package:flutter/foundation.dart';

/// Centralized API & Server Configuration for Admin HQ with instant Local vs Live Render toggle
class ApiConstants {
  /// DEMO MODE (default on): the admin panel runs on its own with demo data.
  /// Every backend, MongoDB and Firestore call is answered inside the app
  /// (see lib/demo/demo_backend.dart) and nothing is saved anywhere.
  /// Images still load from their public Cloudflare R2 / CDN URLs.
  /// Build with --dart-define=DEMO_MODE=false to talk to the real backend.
  static const bool demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: true);

  /// Demo admin login, only accepted in demo mode.
  static const String demoAdminEmail = 'admin@neurofit.demo';
  static const String demoAdminPassword = 'Demo@1234';

  /// Placeholder host used in demo mode. Requests to it never leave the app.
  static const String demoBaseUrl = 'https://demo.neurofit.local';

  /// 🔘 SWITCH HERE: Set to `true` for Local Backend, or `false` for Live Render Backend
  static const bool useLocalBackend = false;

  /// Live Render Production Base URL
  static const String liveRenderUrl = 'https://neurofit-full.onrender.com';

  /// Local Backend Configuration
  static const int serverPort = 5000;
  static const String serverHost = 'localhost';

  /// Returns active base URL based on toggle
  static String get baseUrl {
    if (demoMode) return demoBaseUrl;
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
    if (demoMode) return [demoBaseUrl];
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
