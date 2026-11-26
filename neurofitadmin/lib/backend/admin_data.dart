import 'dart:async';

import 'package:flutter/foundation.dart';

import 'live_backend.dart';

/// Live numbers for every analytics screen, from GET /api/admin/stats.
/// One shared copy, refreshed at most once a minute.
class AdminStats extends ChangeNotifier {
  AdminStats._();
  static final AdminStats I = AdminStats._();

  Map<String, dynamic> data = {};
  bool loading = false;
  String? error;
  DateTime? _at;

  bool get ready => data.isNotEmpty;

  Future<void> load({bool force = false}) async {
    if (loading) return;
    if (!force && _at != null && DateTime.now().difference(_at!) < const Duration(seconds: 60)) return;
    loading = true;
    try {
      final j = await Api.get('/admin/stats');
      data = Map<String, dynamic>.from(j['data'] as Map);
      _at = DateTime.now();
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ---------- typed access ----------
  Map<String, dynamic> sec(String k) => data[k] is Map ? Map<String, dynamic>.from(data[k]) : <String, dynamic>{};
  num n(String section, String key) => (sec(section)[key] as num?) ?? 0;
  List<Map<String, dynamic>> rows(String k) => [for (final x in (data[k] as List? ?? const [])) Map<String, dynamic>.from(x as Map)];

  /// Daily values for the last [days] days (oldest first).
  List<double> series(String key, [int days = 30]) {
    final s = (sec('series')[key] as List?) ?? const [];
    final v = [for (final p in s) ((p as Map)['value'] as num? ?? 0).toDouble()];
    return v.length > days ? v.sublist(v.length - days) : v;
  }

  double sum(String key, int days) => series(key, days).fold(0.0, (a, b) => a + b);

  /// Growth of the last 7 days against the 7 days before, as a percentage.
  double growth(String key) {
    final s = series(key, 14);
    if (s.length < 14) return 0;
    final prev = s.sublist(0, 7).fold<double>(0, (a, b) => a + b);
    final cur = s.sublist(7).fold<double>(0, (a, b) => a + b);
    if (prev == 0) return cur > 0 ? 100 : 0;
    return (cur - prev) / prev * 100;
  }

  String growthLabel(String key, [String suffix = 'vs last 7 days']) {
    final g = growth(key);
    return '${g.abs().toStringAsFixed(1)}% $suffix';
  }

  bool growthUp(String key) => growth(key) >= 0;
}

// ---------- formatting ----------
String fmtInt(num v) {
  final s = v.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return (v < 0 ? '-' : '') + b.toString();
}

/// Indian grouping: ₹24,58,300
String fmtInr(num v) {
  final s = v.round().abs().toString();
  String out;
  if (s.length <= 3) {
    out = s;
  } else {
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    out = '${parts.join(',')},$last3';
  }
  return '₹$out';
}

/// 120K+, 1.2M, 950
String fmtShort(num v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}K';
  return v.round().toString();
}

String fmtPct(num v) => '${v.toStringAsFixed(1)}%';

String timeAgo(String? iso) {
  final t = DateTime.tryParse(iso ?? '');
  if (t == null) return '';
  final d = DateTime.now().difference(t.toLocal());
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 30) return '${d.inDays}d ago';
  return '${(d.inDays / 30).floor()}mo ago';
}

String shortDate(String? iso) {
  final t = DateTime.tryParse(iso ?? '')?.toLocal();
  if (t == null) return '';
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${t.day} ${m[t.month - 1]} ${t.year}';
}

/// Loads a list endpoint once per screen; screens call [AdminList.of].
class AdminList extends ChangeNotifier {
  AdminList(this.path);
  final String path;
  List<Map<String, dynamic>> items = [];
  bool loading = true;
  String? error;

  static final Map<String, AdminList> _cache = {};
  static AdminList of(String path) => _cache.putIfAbsent(path, () => AdminList(path)..load());

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      items = Api.list(await Api.get(path));
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
