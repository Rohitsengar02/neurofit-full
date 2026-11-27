import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';

/// Signed-in admin, kept across reloads.
class AdminSession {
  AdminSession._();

  static String? accessToken;
  static String? refreshToken;
  static String email = '';
  static String name = '';
  static String role = '';

  static bool get isSignedIn => (refreshToken ?? '').isNotEmpty;

  static const _k = 'admin_session_v2';

  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_k);
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      accessToken = j['a'];
      refreshToken = j['r'];
      email = j['e'] ?? '';
      name = j['n'] ?? '';
      role = j['role'] ?? '';
    } catch (_) {}
  }

  static Future<void> save(Map<String, dynamic> login) async {
    final data = (login['data'] is Map) ? Map<String, dynamic>.from(login['data']) : <String, dynamic>{};
    accessToken = (login['accessToken'] ?? data['accessToken'])?.toString();
    refreshToken = (login['refreshToken'] ?? data['refreshToken'])?.toString();
    email = (data['email'] ?? email).toString();
    name = (data['name'] ?? name).toString();
    role = (data['role'] ?? role).toString();
    await _persist();
  }

  static Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_k, jsonEncode({'a': accessToken, 'r': refreshToken, 'e': email, 'n': name, 'role': role}));
      if (email.isNotEmpty) await p.setString('admin_last_email', email);
    } catch (_) {}
  }

  static Future<String> lastEmail() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getString('admin_last_email') ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<void> clear() async {
    final r = refreshToken;
    accessToken = null;
    refreshToken = null;
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_k);
    } catch (_) {}
    if (r != null) {
      try {
        await http.post(Uri.parse('${ApiConstants.apiBaseUrl}/auth/logout'),
            headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refreshToken': r}));
      } catch (_) {}
    }
  }

  static Completer<bool>? _refreshing;

  /// Gets a new access token with the refresh token. Only one refresh runs at a time.
  static Future<bool> refresh(http.Client inner) async {
    if (_refreshing != null) return _refreshing!.future;
    final c = _refreshing = Completer<bool>();
    try {
      if (!isSignedIn) {
        c.complete(false);
      } else {
        final res = await inner.post(Uri.parse('${ApiConstants.apiBaseUrl}/auth/refresh'),
            headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refreshToken': refreshToken}));
        if (res.statusCode == 200) {
          final j = jsonDecode(res.body) as Map<String, dynamic>;
          accessToken = j['accessToken'];
          refreshToken = j['refreshToken'];
          await _persist();
          c.complete(true);
        } else {
          accessToken = null;
          refreshToken = null;
          await _persist();
          onSignedOut?.call();
          c.complete(false);
        }
      }
    } catch (_) {
      c.complete(false);
    } finally {
      _refreshing = null;
    }
    return c.future;
  }

  /// Called when the session can no longer be refreshed (the app returns to login).
  static void Function()? onSignedOut;
}

/// Sends every call the admin panel makes to the NeuroFit API:
/// - `/api/...` calls get the admin's token (and are retried once after a token refresh)
/// - old Firestore REST calls go to the API's Firestore-compatible endpoint (same Postgres data)
/// - old hosts (localhost, the previous Render backend) are rewritten to the live API
/// - direct Cloudflare API calls are refused (uploads go through /api/media/upload)
class LiveBackendClient extends http.BaseClient {
  LiveBackendClient(this._inner);
  final http.Client _inner;

  static final Uri _base = Uri.parse(ApiConstants.baseUrl);
  static const _legacyHosts = {'neurofit-full.onrender.com', 'localhost', '127.0.0.1', '10.0.2.2', '192.168.1.34', '192.168.1.36'};

  @override
  void close() {}

  Uri _map(Uri u) {
    if (u.host == 'firestore.googleapis.com') {
      final q = Map<String, dynamic>.from(u.queryParametersAll)..remove('key');
      return _base.replace(path: '/fs${u.path}', queryParameters: q.isEmpty ? null : q);
    }
    if (_legacyHosts.contains(u.host) && (u.path.startsWith('/api') || u.path.startsWith('/uploads'))) {
      return _base.replace(path: u.path, query: u.hasQuery ? u.query : null);
    }
    return u;
  }

  bool _ours(Uri u) => u.host == _base.host;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.host == 'api.cloudflare.com') {
      return _json(request, 400, {'success': false, 'message': 'Uploads go through the NeuroFit API now'});
    }
    final url = _map(request.url);
    final bytes = await request.finalize().toBytes();

    Future<http.StreamedResponse> go() {
      final r = http.Request(request.method, url)
        ..followRedirects = request.followRedirects
        ..headers.addAll(request.headers)
        ..bodyBytes = bytes;
      if (_ours(url) && (AdminSession.accessToken ?? '').isNotEmpty) {
        r.headers['Authorization'] = 'Bearer ${AdminSession.accessToken}';
      }
      return _inner.send(r);
    }

    var res = await go();
    if (res.statusCode == 401 && _ours(url) && !url.path.contains('/auth/') && !url.path.endsWith('/admin/login')) {
      await res.stream.drain<void>();
      if (await AdminSession.refresh(_inner)) res = await go();
    }
    return res;
  }

  http.StreamedResponse _json(http.BaseRequest req, int status, Object body) {
    final b = utf8.encode(jsonEncode(body));
    return http.StreamedResponse(Stream.value(b), status,
        contentLength: b.length, request: req, headers: const {'content-type': 'application/json; charset=utf-8'});
  }
}

/// Small helper for screens that read the API directly.
class Api {
  static Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(Uri.parse('${ApiConstants.apiBaseUrl}$path')).timeout(const Duration(seconds: 60));
    final j = jsonDecode(res.body);
    if (res.statusCode >= 400) throw ApiError(j is Map ? (j['message'] ?? 'Request failed').toString() : 'Request failed');
    return j is Map<String, dynamic> ? j : {'data': j};
  }

  static Future<Map<String, dynamic>> send(String method, String path, [Object? body]) async {
    final req = http.Request(method, Uri.parse('${ApiConstants.apiBaseUrl}$path'))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(body ?? {});
    final res = await http.Response.fromStream(await http.Client().send(req)).timeout(const Duration(seconds: 60));
    final j = res.body.isEmpty ? {} : jsonDecode(res.body);
    if (res.statusCode >= 400) throw ApiError(j is Map ? (j['message'] ?? 'Request failed').toString() : 'Request failed');
    return j is Map<String, dynamic> ? j : {'data': j};
  }

  static List<Map<String, dynamic>> list(Map<String, dynamic> j) =>
      [for (final x in (j['data'] is List ? j['data'] as List : const [])) if (x is Map) Map<String, dynamic>.from(x)];

  /// Waits for the API to answer (a free Render server can take ~50 s to wake up).
  static Future<bool> warmUp({Duration max = const Duration(seconds: 75)}) async {
    final end = DateTime.now().add(max);
    while (DateTime.now().isBefore(end)) {
      try {
        final r = await http.get(Uri.parse('${ApiConstants.baseUrl}/health')).timeout(const Duration(seconds: 20));
        if (r.statusCode == 200) return true;
      } catch (_) {}
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    return false;
  }
}

class ApiError implements Exception {
  ApiError(this.message);
  final String message;
  @override
  String toString() => message;
}
