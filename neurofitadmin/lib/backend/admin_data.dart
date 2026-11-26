import 'dart:async';

import 'package:flutter/material.dart';

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

/// Users for the New / Active / Premium screens from GET /api/admin/user-list,
/// already shaped as the rows those screens draw.
class AdminUsers extends ChangeNotifier {
  AdminUsers(this.segment);
  final String segment;
  List<Map<String, dynamic>> rows = [];
  bool loading = true;
  String? error;

  static final Map<String, AdminUsers> _cache = {};
  static AdminUsers of(String segment) => _cache.putIfAbsent(segment, () => AdminUsers(segment)..load());

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      final list = Api.list(await Api.get('/admin/user-list?segment=$segment&limit=300'));
      rows = [for (final u in list) userRow(u)];
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  static const _green = Color(0xFF10B981), _greenBg = Color(0xFFECFDF5);
  static const _amber = Color(0xFFF59E0B), _amberBg = Color(0xFFFEF3C7);
  static const _violet = Color(0xFF8B5CF6), _violetBg = Color(0xFFF5F3FF);
  static const _slateBg = Color(0xFFE2E8F0);

  static Map<String, dynamic> userRow(Map<String, dynamic> u) {
    final sub = u['subscription'] is Map ? Map<String, dynamic>.from(u['subscription']) : null;
    final premium = u['isPremium'] == true || sub != null;
    final created = DateTime.tryParse('${u['createdAt'] ?? ''}')?.toLocal();
    final last = DateTime.tryParse('${u['lastActiveAt'] ?? ''}')?.toLocal();
    final online = last != null && DateTime.now().difference(last).inMinutes < 15;
    final isNew = created != null && DateTime.now().difference(created).inDays < 7;
    final google = u['authProvider'] == 'google';
    final until = DateTime.tryParse('${sub?['until'] ?? ''}')?.toLocal();
    String expiry = premium ? 'Active' : 'Free plan';
    if (until != null) {
      final d = until.difference(DateTime.now()).inDays;
      expiry = d >= 0 ? 'Renews in ${d}d' : 'Expired ${-d}d ago';
    }
    final name = '${u['name'] ?? ''}'.trim();
    final streak = (u['streak'] as num? ?? 0).toInt();
    final photo = '${u['photoUrl'] ?? ''}';
    return {
      ...u,
      'uid': u['uid'] ?? u['id'],
      'name': name.isEmpty ? 'NeuroFit user' : name,
      'email': '${u['email'] ?? ''}',
      'phone': '${u['phone'] ?? ''}'.isEmpty ? 'No phone' : '${u['phone']}',
      'joined': shortDate(u['createdAt']?.toString()),
      'source': google ? 'Google' : 'Email sign-up',
      'sourceIcon': google ? Icons.g_mobiledata_rounded : Icons.email_outlined,
      'plan': sub != null ? '${sub['planName'] ?? 'Coaching'}' : (premium ? 'Premium' : 'Free Plan'),
      'planColor': premium ? _amber : _green,
      'planBg': premium ? _amberBg : _greenBg,
      'badge': premium ? (sub != null ? 'Coached' : 'Premium') : (isNew ? 'New' : (u['status'] == 'active' ? 'Active' : 'Suspended')),
      'badgeColor': premium ? _amber : _violet,
      'badgeBg': premium ? _amberBg : _violetBg,
      'avatarBg': premium ? _amberBg : (online ? const Color(0xFFDCFCE7) : _slateBg),
      'img': photo,
      'lastActive': online ? 'Online now' : (last == null ? 'Never' : timeAgo(last.toIso8601String())),
      'status': online ? 'Online' : 'Away',
      'streak': '🔥 $streak ${streak == 1 ? 'Day' : 'Days'}',
      'workouts': '${u['workoutsDone'] ?? 0} Done',
      'tier': sub != null ? '${sub['planName'] ?? 'Coaching'} · ${sub['months'] ?? 1} mo' : (premium ? 'Premium member' : 'Free plan'),
      'expiry': expiry,
      'trainer': sub != null ? '${sub['trainerName'] ?? '-'}' : 'No trainer',
      'spend': fmtInr(u['spend'] as num? ?? 0),
    };
  }
}

/// Every coach (any status) from GET /api/admin/trainers, shaped as the rows
/// the trainer screens draw. Actions write through and reload.
class AdminTrainers extends ChangeNotifier {
  AdminTrainers._();
  static final AdminTrainers I = AdminTrainers._();

  List<Map<String, dynamic>> rows = [];
  bool loading = false;
  String? error;
  DateTime? _at;

  Future<void> load({bool force = false}) async {
    if (loading) return;
    if (!force && _at != null && DateTime.now().difference(_at!) < const Duration(seconds: 30)) return;
    loading = true;
    try {
      rows = [for (final t in Api.list(await Api.get('/admin/trainers'))) trainerRow(t)];
      _at = DateTime.now();
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> withStatus(String s) => rows.where((r) => r['rawStatus'] == s).toList();

  Future<void> setStatus(String id, String action, {String? reason}) async {
    await Api.send('POST', '/admin/trainers/$id/$action', {if (reason != null) 'reason': reason});
    await load(force: true);
    AdminStats.I.load(force: true);
  }

  Future<void> setVip(String id, bool vip) async {
    await Api.send('PUT', '/admin/trainers/$id', {'vip': vip});
    await load(force: true);
  }

  Future<String> assign(String id, String email) async {
    final r = await Api.send('POST', '/admin/trainers/$id/assign', {'email': email});
    await load(force: true);
    final d = r['data'] is Map ? r['data'] as Map : const {};
    return '${d['userName'] ?? email}';
  }

  static const _statusLabel = {'pending': 'Pending Review', 'approved': 'Approved', 'rejected': 'Rejected', 'suspended': 'Suspended'};
  static const _statusColor = {'pending': Color(0xFFF59E0B), 'approved': Color(0xFF10B981), 'rejected': Color(0xFFEF4444), 'suspended': Color(0xFF64748B)};

  static String _price(List plans, int months) {
    for (final p in plans) {
      if (p is Map && (p['months'] as num? ?? 0).toInt() == months) return fmtInr(p['price'] as num? ?? 0);
    }
    return '-';
  }

  static Map<String, dynamic> trainerRow(Map<String, dynamic> t) {
    final status = '${t['status'] ?? 'pending'}';
    final vip = t['vip'] == true;
    final rating = (t['rating'] as num? ?? 0).toDouble();
    final reviews = (t['reviews'] as num? ?? 0).toInt();
    final plans = t['plans'] is List ? t['plans'] as List : const [];
    final certs = t['certifications'] is List ? (t['certifications'] as List).join(' • ') : '${t['certifications'] ?? ''}';
    final spec = t['specialties'] is List && (t['specialties'] as List).isNotEmpty ? (t['specialties'] as List).join(', ') : '${t['cat'] ?? 'Fitness'}';
    final elite = !vip && rating >= 4.5 && reviews >= 5;
    final applied = '${t['appliedAt'] ?? t['createdAt'] ?? ''}';
    final years = (t['years'] as num? ?? 0).toInt();
    return {
      ...t,
      'id': t['id'],
      'name': '${t['name'] ?? 'Coach'}',
      'email': '${t['email'] ?? ''}',
      'phone': '${t['phone'] ?? ''}',
      'specialty': spec,
      'category': '${t['cat'] ?? 'Fitness'}',
      'tier': vip ? 'VIP Master Coach' : (elite ? 'Elite Coach' : (status == 'approved' ? 'Verified Coach' : _statusLabel[status] ?? status)),
      'tierColor': vip ? const Color(0xFFF59E0B) : (elite ? const Color(0xFF8B5CF6) : const Color(0xFF06B6D4)),
      'tierBg': vip ? const Color(0xFFFEF3C7) : (elite ? const Color(0xFFF5F3FF) : const Color(0xFFECFEFF)),
      'isPremium': vip,
      'rating': reviews == 0 ? 'New' : '${rating.toStringAsFixed(1)} ★',
      'reviewsCount': '$reviews ${reviews == 1 ? 'review' : 'reviews'}',
      'experience': years > 0 ? '$years+ Yrs Exp' : 'New coach',
      'certifications': certs.isEmpty ? 'No certificates uploaded' : certs,
      'cert': certs.isEmpty ? 'No certificates uploaded' : certs,
      'clientsCount': (t['clients'] as num? ?? 0).toInt(),
      'clientGrowth': '+${t['newClients30d'] ?? 0} this month',
      'monthlyRevenue': '${fmtInr(t['revenue30d'] as num? ?? 0)} / mo',
      'monthlyRate': '${_price(plans, 1)} / mo',
      'planRate': _price(plans, 3),
      'callRate': _price(plans, 12),
      'successRate': reviews == 0 ? '-' : fmtPct(rating / 5 * 100),
      'rawStatus': status,
      'appStatus': _statusLabel[status] ?? status,
      'status': status == 'approved' ? (t['live'] == true ? 'Live now' : 'Active') : (_statusLabel[status] ?? status),
      'statusColor': _statusColor[status] ?? const Color(0xFF64748B),
      'img': '${t['photo'] ?? ''}',
      'avatar': '${t['photo'] ?? ''}',
      'bio': '${t['bio'] ?? ''}'.isEmpty ? '${t['headline'] ?? 'Fitness coach'}' : '${t['bio']}',
      'appliedDate': applied.isEmpty ? '' : '${timeAgo(applied)} · ${shortDate(applied)}',
    };
  }
}
