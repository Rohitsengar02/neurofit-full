import 'package:flutter/foundation.dart';

/// Centralized API & Server Configuration for Admin HQ (No hardcoded IP addresses)
class ApiConstants {
  static const int serverPort = 5000;
  static const String serverHost = 'localhost';

  /// Primary backend server base URL (e.g. http://localhost:5000)
  static String get baseUrl {
    return 'http://$serverHost:$serverPort';
  }

  /// REST API base URL (e.g. http://localhost:5000/api)
  static String get apiBaseUrl {
    return '$baseUrl/api';
  }

  /// Real-time Socket.io server URL
  static String get socketUrl {
    return baseUrl;
  }
}
