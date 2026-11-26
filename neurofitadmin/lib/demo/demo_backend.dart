import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Demo mode for the admin panel.
///
/// The admin panel normally talks to the Node backend (MongoDB), to Firestore
/// over REST and to the Cloudflare API. In demo mode every one of those calls
/// is answered here, in memory, with demo data. Nothing leaves the browser
/// and nothing is saved: a page reload starts from the demo data again.
///
/// Everything else (images on Cloudflare R2, Unsplash and GitHub, fonts)
/// still goes to the network as usual.
class DemoBackendClient extends http.BaseClient {
  DemoBackendClient(this._inner);

  final http.Client _inner;

  static final _DemoStore _store = _DemoStore();

  // http.get() and friends close their client after each call; the real
  // client underneath is shared, so it must stay open.
  @override
  void close() {}

  static bool _isBackendRequest(Uri url) {
    if (url.path.startsWith('/api/') || url.path == '/api') return true;
    const blockedHosts = {
      'firestore.googleapis.com',
      'api.cloudflare.com',
    };
    return blockedHosts.contains(url.host);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!_isBackendRequest(request.url)) {
      return _inner.send(request);
    }

    String body = '';
    if (request is http.Request) {
      try {
        body = request.body;
      } catch (_) {
        body = '';
      }
    }

    _Result result;
    try {
      if (request.url.host == 'firestore.googleapis.com') {
        result = _store.firestore(request.method, request.url, body);
      } else if (request.url.host == 'api.cloudflare.com') {
        // Direct uploads to Cloudflare need a secret token, which a public
        // demo must never hold. Uploads are kept in the browser instead.
        result = const _Result(200, {'success': true});
      } else {
        result = _store.api(request.method, request.url, body);
      }
    } catch (e) {
      result = _Result(500, {'success': false, 'message': 'Demo error: $e'});
    }

    final bytes = utf8.encode(jsonEncode(result.body));
    // A tiny delay so loading states still feel natural.
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return http.StreamedResponse(
      Stream.value(bytes),
      result.status,
      contentLength: bytes.length,
      request: request,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  }
}

class _Result {
  const _Result(this.status, this.body);
  final int status;
  final Object body;
}

_Result _notFound([String what = 'Item']) =>
    _Result(404, {'success': false, 'message': '$what not found (demo data)'});

const String _gifBase = 'https://raw.githubusercontent.com/Rohitsengar02/exercies-data/main';
String _unsplash(String id, {int w = 800}) =>
    'https://images.unsplash.com/photo-$id?w=$w&auto=format&fit=crop&q=80';

String _nowIso([Duration ago = Duration.zero]) =>
    DateTime.now().subtract(ago).toUtc().toIso8601String();

/// How each REST collection names its own id field.
const Map<String, String> _idFields = {
  'products': 'id',
  'categories': 'id',
  'subcategories': 'id',
  'banners': 'bannerId',
  'layout': 'sectionId',
  'orders': 'orderId',
  'users': 'uid',
  'discounts': 'discountId',
  'workout-layout': 'sectionId',
  'workouts': 'id',
  'programs': 'id',
  'exercises': 'id',
  'workout-categories': 'id',
  'workout-banners': 'bannerId',
  'exercise-categories': 'categoryId',
  'notifications': 'notificationId',
};

/// Firestore number fields that the admin reads as doubleValue.
const Set<String> _doubleFields = {
  'price',
  'regularPrice',
  'monthlyPrice',
  'yearlyPrice',
  'rating',
  'value',
  'minOrderValue',
};

class _DemoStore {
  _DemoStore() {
    _seed();
  }

  final Map<String, List<Map<String, dynamic>>> _rest = {};
  // Firestore: full document path (after /documents/) -> fields (typed).
  final Map<String, Map<String, dynamic>> _fs = {};
  final List<String> _uploadedMedia = [];
  int _counter = 1000;

  String _newId(String prefix) => '${prefix}_demo${_counter++}';

  // ---------------------------------------------------------------------------
  // REST API (/api/...)
  // ---------------------------------------------------------------------------
  _Result api(String method, Uri url, String rawBody) {
    final segs = url.pathSegments.where((s) => s.isNotEmpty).toList();
    // segs[0] == 'api'
    if (segs.length < 2) {
      return const _Result(200, {'success': true, 'message': 'Neurofit demo API'});
    }
    final res = segs[1];
    final rest = segs.sublist(2);
    Map<String, dynamic> body = {};
    if (rawBody.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawBody);
        if (decoded is Map) body = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }

    switch (res) {
      case 'admin':
        return _admin(rest, body);
      case 'media':
        return _media(method, rest, body);
      case 'sync':
        return const _Result(200, {'success': true, 'message': 'Nothing to sync in demo mode'});
      case 'notifications':
        return const _Result(200, {'success': true, 'count': 0, 'data': []});
    }

    final list = _rest[res];
    if (list == null) return _notFound('Endpoint');
    final idField = _idFields[res] ?? 'id';

    // Collection-level actions
    if (rest.isEmpty) {
      if (method == 'GET') return _list(res, list, url.queryParameters);
      if (method == 'POST') return _create(res, list, idField, body);
      return _notFound('Endpoint');
    }

    if (rest.first == 'reorder' && method == 'POST') {
      return _reorder(list, body);
    }
    if (rest.first == 'active' && method == 'GET') {
      final active = list.where((e) => e['isActive'] != false).toList();
      return _Result(200, {'success': true, 'count': active.length, 'data': active});
    }
    if (rest.first == 'validate' && res == 'discounts') {
      final code = (body['code'] ?? '').toString().toUpperCase();
      final d = list.where((e) => (e['code'] ?? '').toString().toUpperCase() == code).toList();
      if (d.isEmpty) return const _Result(404, {'success': false, 'message': 'Invalid code'});
      return _Result(200, {'success': true, 'data': d.first});
    }

    final id = Uri.decodeComponent(rest.first);
    final index = list.indexWhere((e) => _matches(e, id, idField));

    // /:id/status
    if (rest.length > 1 && rest[1] == 'status') {
      if (index < 0) return _notFound();
      final item = list[index];
      if (res == 'orders') {
        item['orderStatus'] = body['orderStatus'] ?? body['status'] ?? item['orderStatus'];
      } else {
        final current = item['isActive'] != false;
        final next = body.containsKey('isActive')
            ? body['isActive'] == true
            : body.containsKey('status')
                ? body['status'].toString().toLowerCase() == 'active'
                : !current;
        item['isActive'] = next;
        item['status'] = next ? 'Active' : 'Inactive';
      }
      item['updatedAt'] = _nowIso();
      return _Result(200, {'success': true, 'data': item});
    }
    if (rest.length > 1) {
      // Sub-resources such as /users/:uid/addresses: nothing stored for them.
      return const _Result(200, {'success': true, 'count': 0, 'data': []});
    }

    switch (method) {
      case 'GET':
        if (index < 0) return _notFound();
        return _Result(200, {'success': true, 'data': list[index]});
      case 'PUT':
      case 'PATCH':
      case 'POST':
        if (index < 0) {
          // Upsert, like the real backend's createOrUpdate routes.
          final created = {...body, idField: id, 'id': body['id'] ?? id, '_id': id};
          created['createdAt'] ??= _nowIso();
          created['updatedAt'] = _nowIso();
          list.add(created);
          return _Result(201, {'success': true, 'data': created});
        }
        final updated = {...list[index], ...body};
        updated['updatedAt'] = _nowIso();
        list[index] = updated;
        return _Result(200, {'success': true, 'data': updated});
      case 'DELETE':
        if (index < 0) return _notFound();
        list.removeAt(index);
        return const _Result(200, {'success': true, 'message': 'Deleted'});
    }
    return _notFound('Endpoint');
  }

  bool _matches(Map<String, dynamic> e, String id, String idField) =>
      e[idField]?.toString() == id ||
      e['id']?.toString() == id ||
      e['_id']?.toString() == id ||
      e['sectionId']?.toString() == id ||
      e['bannerId']?.toString() == id;

  _Result _list(String res, List<Map<String, dynamic>> list, Map<String, String> q) {
    Iterable<Map<String, dynamic>> out = list;
    if (res == 'subcategories' && (q['categoryId'] ?? '').isNotEmpty) {
      out = out.where((e) => e['parentCategoryId'] == q['categoryId']);
    }
    if (q['activeOnly'] == 'true') out = out.where((e) => e['isActive'] != false);
    if (res == 'orders' && (q['status'] ?? '').isNotEmpty) {
      out = out.where((e) => e['orderStatus'] == q['status']);
    }
    final data = out.toList();
    if (list.isNotEmpty && list.first.containsKey('sortOrder')) {
      data.sort((a, b) =>
          ((a['sortOrder'] as num?) ?? 0).compareTo((b['sortOrder'] as num?) ?? 0));
    }
    if (res == 'orders') {
      data.sort((a, b) => (b['createdAt'] ?? '').toString().compareTo((a['createdAt'] ?? '').toString()));
    }
    return _Result(200, {'success': true, 'count': data.length, 'data': data});
  }

  _Result _create(String res, List<Map<String, dynamic>> list, String idField,
      Map<String, dynamic> body) {
    final given = body[idField] ?? body['id'] ?? body['_id'];
    final id = (given == null || given.toString().isEmpty) ? _newId(res.replaceAll('-', '_')) : given.toString();
    final existing = list.indexWhere((e) => _matches(e, id, idField));
    final item = {
      ...body,
      idField: id,
      'id': body['id'] ?? id,
      '_id': id,
      'createdAt': body['createdAt'] ?? _nowIso(),
      'updatedAt': _nowIso(),
    };
    if (existing >= 0) {
      list[existing] = {...list[existing], ...item};
    } else {
      list.add(item);
    }
    return _Result(201, {'success': true, 'data': item});
  }

  _Result _reorder(List<Map<String, dynamic>> list, Map<String, dynamic> body) {
    final orders = body.values.whereType<List>().expand((l) => l).toList();
    for (final o in orders) {
      if (o is! Map) continue;
      final id = (o['id'] ?? o['sectionId'] ?? o['bannerId'] ?? o['_id'] ?? '').toString();
      final sort = o['sortOrder'] ?? o['displayOrder'] ?? o['order'];
      for (final e in list) {
        if (_matches(e, id, 'id')) {
          e['sortOrder'] = sort;
          e['displayOrder'] = sort;
        }
      }
    }
    return const _Result(200, {'success': true, 'message': 'Reordered'});
  }

  _Result _admin(List<String> rest, Map<String, dynamic> body) {
    if (rest.isNotEmpty && rest.first == 'login') {
      final email = (body['email'] ?? '').toString().trim().toLowerCase();
      final password = (body['password'] ?? '').toString();
      if (email == 'admin@neurofit.demo' && password == 'Demo@1234') {
        return _Result(200, {
          'success': true,
          'message': 'Admin authentication successful',
          'data': {
            'id': 'admin_demo',
            'email': email,
            'name': 'Demo Admin',
            'role': 'superadmin',
            'lastLogin': _nowIso(),
          },
        });
      }
      return const _Result(401, {'success': false, 'message': 'Invalid admin credentials'});
    }
    return const _Result(200, {'success': true});
  }

  _Result _media(String method, List<String> rest, Map<String, dynamic> body) {
    if (rest.isEmpty && method == 'GET') {
      final urls = <String>{
        ..._uploadedMedia,
        for (final list in _rest.values)
          for (final e in list)
            for (final k in const ['imageUrl', 'mainImageUrl', 'mediaUrl'])
              if (e[k] is String && (e[k] as String).startsWith('http')) e[k] as String,
      }.toList();
      return _Result(200, {'success': true, 'count': urls.length, 'data': urls});
    }
    if (rest.isNotEmpty && rest.first == 'upload') {
      // Keep the picture in the browser as a data URL so it shows up right away.
      final mime = (body['mimeType'] ?? 'image/jpeg').toString();
      final b64 = (body['imageBase64'] ?? '').toString();
      final url = b64.isEmpty ? _unsplash('1534438327276-14e5300c3a48') : 'data:$mime;base64,$b64';
      _uploadedMedia.insert(0, url);
      return _Result(200, {
        'success': true,
        'url': url,
        'fileName': body['fileName'] ?? 'upload',
      });
    }
    return _notFound('Media');
  }

  // ---------------------------------------------------------------------------
  // Firestore REST emulation (only what the admin panel uses)
  // ---------------------------------------------------------------------------
  _Result firestore(String method, Uri url, String rawBody) {
    final path = url.path;
    final marker = '/documents';
    final at = path.indexOf(marker);
    if (at < 0) return _notFound('Document');
    final docPath = path.substring(at + marker.length).replaceAll(RegExp(r'^/+|/+$'), '');
    final parts = docPath.split('/').where((s) => s.isNotEmpty).toList();
    final isCollection = parts.length.isOdd;

    Map<String, dynamic> fields = {};
    if (rawBody.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawBody);
        if (decoded is Map && decoded['fields'] is Map) {
          fields = Map<String, dynamic>.from(decoded['fields'] as Map);
        }
      } catch (_) {}
    }

    if (isCollection) {
      if (method == 'GET') {
        final prefix = '$docPath/';
        final docs = <Map<String, dynamic>>[];
        _fs.forEach((k, v) {
          if (k.startsWith(prefix) && !k.substring(prefix.length).contains('/')) {
            docs.add(_fsDoc(k, v));
          }
        });
        return _Result(200, docs.isEmpty ? <String, dynamic>{} : {'documents': docs});
      }
      if (method == 'POST') {
        final id = url.queryParameters['documentId'] ?? _newId('doc');
        final key = '$docPath/$id';
        _fs[key] = fields;
        return _Result(200, _fsDoc(key, fields));
      }
      return _notFound('Document');
    }

    switch (method) {
      case 'GET':
        final doc = _fs[docPath];
        if (doc == null) return _notFound('Document');
        return _Result(200, _fsDoc(docPath, doc));
      case 'PATCH':
        final masks = url.queryParametersAll['updateMask.fieldPaths'];
        final current = _fs[docPath] ?? <String, dynamic>{};
        if (masks != null && masks.isNotEmpty) {
          for (final m in masks) {
            if (fields.containsKey(m)) {
              current[m] = fields[m];
            } else {
              current.remove(m);
            }
          }
          _fs[docPath] = current;
        } else {
          _fs[docPath] = fields;
        }
        return _Result(200, _fsDoc(docPath, _fs[docPath]!));
      case 'DELETE':
        _fs.remove(docPath);
        _fs.removeWhere((k, _) => k.startsWith('$docPath/'));
        return const _Result(200, <String, dynamic>{});
    }
    return _notFound('Document');
  }

  Map<String, dynamic> _fsDoc(String key, Map<String, dynamic> fields) => {
        'name': 'projects/demo/databases/(default)/documents/$key',
        'fields': fields,
        'createTime': _nowIso(const Duration(days: 30)),
        'updateTime': _nowIso(),
      };

  void _fsPut(String collection, String id, Map<String, dynamic> plain) {
    _fs['$collection/$id'] = {
      for (final e in plain.entries) e.key: _fsValue(e.key, e.value),
    };
  }

  Map<String, dynamic> _fsValue(String key, Object? v) {
    if (v == null) return {'nullValue': null};
    if (v is bool) return {'booleanValue': v};
    if (v is num) {
      if (_doubleFields.contains(key) || v is! int) return {'doubleValue': v.toDouble()};
      return {'integerValue': v.toString()};
    }
    if (v is DateTime) return {'timestampValue': v.toUtc().toIso8601String()};
    if (v is List) {
      return {
        'arrayValue': {'values': [for (final x in v) _fsValue(key, x)]},
      };
    }
    if (v is Map) {
      return {
        'mapValue': {
          'fields': {for (final e in v.entries) e.key.toString(): _fsValue(e.key.toString(), e.value)},
        },
      };
    }
    return {'stringValue': v.toString()};
  }

  // ---------------------------------------------------------------------------
  // Seed
  // ---------------------------------------------------------------------------
  void _seed() {
    List<Map<String, dynamic>> copy(List<Map<String, dynamic>> src, String idField,
            [Map<String, dynamic> Function(Map<String, dynamic>)? extra]) =>
        [
          for (var i = 0; i < src.length; i++)
            () {
              final m = Map<String, dynamic>.from(jsonDecode(jsonEncode(src[i])) as Map);
              final id = (m[idField] ?? m['id']).toString();
              m[idField] = id;
              m['id'] ??= id;
              m['_id'] = id;
              m['sortOrder'] ??= i + 1;
              m['createdAt'] ??= _nowIso(Duration(days: 40 - i));
              m['updatedAt'] ??= _nowIso(Duration(days: i));
              return extra == null ? m : {...m, ...extra(m)};
            }(),
        ];

    _rest['categories'] = copy(_categories, 'id', (m) => {'status': 'Active', 'description': '${m['name']} for every training goal.'});
    _rest['subcategories'] = copy(_subcategories, 'id', (m) => {'status': 'Active'});
    _rest['products'] = copy(_products, 'id', (m) => {'status': 'Active', 'lowStockThreshold': 5, 'costPerItem': ((m['price'] as num) * 0.55).roundToDouble()});
    _rest['banners'] = copy(_banners, 'bannerId', (m) => {'status': 'Active', 'mediaType': 'image', 'showTitle': true, 'showHeading': true, 'type': 'hero', 'displayOrder': m['sortOrder']});
    _rest['layout'] = copy(_layoutSections, 'sectionId', (m) => {
          'displayOrder': m['sortOrder'],
          'showHeading': true,
          'showTitle': m['showTitle'] ?? true,
          'selectedItemIds': m['type'] == 'banners' ? ['ban_1', 'ban_2', 'ban_3'] : <String>[],
          'filterId': m['filterId'] ?? '',
          'filterName': m['filterName'] ?? '',
          'itemLimit': m['itemLimit'] ?? 8,
        });
    _rest['discounts'] = copy(_discounts, 'discountId', (m) => {'status': 'Active'});
    _rest['orders'] = copy(_seedOrders(), 'orderId');
    _rest['users'] = copy(_seedUsers(), 'uid');
    _rest['workouts'] = copy(_workouts, 'id');
    _rest['workout-categories'] = copy(_workoutCategories, 'id');
    _rest['exercise-categories'] = copy(_exerciseCategories, 'categoryId', (m) => {
          'categoryId': m['id'],
          'exerciseCount': _seedExercises().where((e) => e['categoryId'] == m['id']).length,
          'description': '${m['name']} exercises with demo GIFs.',
        });
    _rest['exercises'] = copy(_seedExercises(), 'id');
    _rest['workout-banners'] = copy(_workoutBanners, 'bannerId');
    _rest['workout-layout'] = copy(_workoutLayout, 'sectionId', (m) => {'displayOrder': m['sortOrder']});
    _rest['programs'] = copy(_programs, 'id');

    // Firestore-only screens (plans, programs, fitness CMS) and fallbacks.
    for (final p in _plans) {
      _fsPut('subscription_plans', p['planId'] as String, p);
    }
    for (final p in _programs) {
      _fsPut('fitness_programs', p['id'] as String, p);
    }
    for (final c in _cmsItems) {
      _fsPut('fitness_cms', c['itemId'] as String, c);
    }
    for (final d in _rest['discounts']!) {
      _fsPut('discounts', d['discountId'] as String, d);
    }
  }

  List<Map<String, dynamic>> _seedExercises() {
    final out = <Map<String, dynamic>>[];
    for (final e in _allExercises) {
      final muscle = e['muscleGroup'] as String;
      final cat = _exerciseCategoryFor[muscle] ?? 'ec_core';
      final gif = e['mediaUrl'] as String;
      out.add({
        'id': 'ex_${e['exerciseId']}',
        'exerciseId': e['exerciseId'],
        'title': e['title'],
        'name': e['title'],
        'categoryId': cat,
        'categoryName': _exerciseCategories.firstWhere((c) => c['id'] == cat)['name'],
        'category': _exerciseCategories.firstWhere((c) => c['id'] == cat)['name'],
        'muscleGroup': muscle,
        'equipment': e['equipment'] ?? 'Body weight',
        'difficulty': 'Intermediate',
        'sets': e['sets'],
        'reps': e['reps'],
        'mediaUrl': gif,
        'gifUrl': gif,
        'imageUrl': gif.replaceFirst('/videos/', '/images/').replaceFirst('.gif', '.jpg'),
        'mediaType': 'gif',
        'instructions': e['instructions'],
        'status': 'Active',
        'isActive': true,
      });
    }
    return out;
  }

  List<Map<String, dynamic>> _seedUsers() {
    const names = [
      ['Aarav Sharma', 'Build muscle', 'Intermediate', 'google'],
      ['Priya Nair', 'Lose weight', 'Beginner', 'email'],
      ['Rahul Verma', 'Get stronger', 'Advanced', 'google'],
      ['Sneha Iyer', 'Stay fit', 'Beginner', 'apple'],
      ['Karan Mehta', 'Lose weight', 'Intermediate', 'email'],
      ['Ananya Gupta', 'Improve flexibility', 'Beginner', 'google'],
      ['Vikram Singh', 'Build muscle', 'Advanced', 'google'],
      ['Isha Reddy', 'Stay fit', 'Intermediate', 'apple'],
    ];
    return [
      for (var i = 0; i < names.length; i++)
        {
          'uid': 'user_demo_${i + 1}',
          'name': names[i][0],
          'email': '${names[i][0].toLowerCase().replaceAll(' ', '.')}@example.com',
          'phone': '+91 98${(76543210 + i * 1111).toString()}',
          'photoUrl': '',
          'authProvider': names[i][3],
          'hasCompletedOnboarding': true,
          'fitnessGoal': names[i][1],
          'experienceLevel': names[i][2],
          'gender': i.isEven ? 'Male' : 'Female',
          'age': 22 + i * 2,
          'createdAt': _nowIso(Duration(days: 3 + i * 6)),
        },
    ];
  }

  List<Map<String, dynamic>> _seedOrders() {
    Map<String, dynamic> item(String id, int qty) {
      final p = _products.firstWhere((p) => p['id'] == id);
      return {
        'productId': id,
        'title': p['title'],
        'variant': '',
        'price': p['price'],
        'quantity': qty,
        'imageUrl': p['mainImageUrl'],
      };
    }

    Map<String, dynamic> address(String name, String city, String pin) => {
          'fullName': name,
          'phoneNumber': '+91 98765 43210',
          'streetAddress': '12, Green Park Residency',
          'city': city,
          'state': 'Maharashtra',
          'pincode': pin,
        };

    Map<String, dynamic> order(String id, String user, String name, String city, String status,
        String pay, int daysAgo, List<Map<String, dynamic>> items) {
      final subtotal = items.fold<num>(0, (s, i) => s + (i['price'] as num) * (i['quantity'] as num));
      return {
        'orderId': id,
        'uid': user,
        'userName': name,
        'customerName': name,
        'userEmail': '${name.toLowerCase().replaceAll(' ', '.')}@example.com',
        'orderStatus': status,
        'paymentMethod': pay,
        'paymentStatus': status == 'Cancelled' ? 'Refunded' : 'Paid',
        'subtotal': subtotal.toDouble(),
        'shippingFee': 0.0,
        'tax': 0.0,
        'totalAmount': subtotal.toDouble(),
        'createdAt': _nowIso(Duration(days: daysAgo, hours: daysAgo * 3)),
        'shippingAddress': address(name, city, '4110${10 + daysAgo}'),
        'items': items,
      };
    }

    return [
      order('NF10601', 'user_demo_1', 'Aarav Sharma', 'Pune', 'Placed', 'UPI', 0, [item('p_whey', 1), item('p_shaker', 1)]),
      order('NF10598', 'user_demo_2', 'Priya Nair', 'Mumbai', 'Processing', 'Card', 1, [item('p_mat', 1), item('p_bands', 1)]),
      order('NF10590', 'user_demo_3', 'Rahul Verma', 'Delhi', 'Shipped', 'UPI', 2, [item('p_dumbbell', 1)]),
      order('NF10577', 'user_demo_5', 'Karan Mehta', 'Bengaluru', 'Delivered', 'COD', 5, [item('p_bar', 2), item('p_granola', 1)]),
      order('NF10561', 'user_demo_7', 'Vikram Singh', 'Jaipur', 'Delivered', 'Card', 8, [item('p_creatine', 1), item('p_whey', 1)]),
      order('NF10548', 'user_demo_4', 'Sneha Iyer', 'Chennai', 'Cancelled', 'UPI', 11, [item('p_shoes', 1)]),
      order('NF10533', 'user_demo_8', 'Isha Reddy', 'Hyderabad', 'Delivered', 'UPI', 15, [item('p_kettle', 1), item('p_tee', 2)]),
    ];
  }
}

// -----------------------------------------------------------------------------
// Admin-only demo data
// -----------------------------------------------------------------------------
const Map<String, String> _exerciseCategoryFor = {
  'Chest': 'ec_chest',
  'Back': 'ec_back',
  'Legs': 'ec_legs',
  'Shoulders': 'ec_shoulders',
  'Arms': 'ec_arms',
  'Core': 'ec_core',
  'Cardio': 'ec_core',
  'Full Body': 'ec_legs',
};

List<Map<String, dynamic>> get _allExercises => [
      _benchPress, _pushUp, _inclinePress, _pullUp, _row, _pulldown, _squat, _deadlift,
      _lunge, _legPress, _lateralRaise, _curl, _dip, _bicycle, _sidePlank, _russianTwist,
      _climber, _burpee, _jumpSquat, _highKnee, _goblet, _swing,
    ];

final List<Map<String, dynamic>> _workoutCategories = [
  for (final c in [
    ['wcat_strength', 'Strength', 'Heavy compound lifts and progressive overload', _unsplash('1534438327276-14e5300c3a48', w: 500)],
    ['wcat_hiit', 'HIIT & Circuit', 'Short, intense intervals', _unsplash('1571019613454-1cb2f99b2d8b', w: 500)],
    ['wcat_core', 'Core & Abs', 'Stability and a stronger midsection', _unsplash('1518611012118-696072aa579a', w: 500)],
    ['wcat_yoga', 'Yoga & Flow', 'Mobility, breath and balance', _unsplash('1506126613408-eca07ce68773', w: 500)],
    ['wcat_cardio', 'Cardio Blast', 'Endurance and heart health', _unsplash('1517838277536-f5f99be501cd', w: 500)],
  ])
    {
      'id': c[0],
      'name': c[1],
      'description': c[2],
      'mediaType': 'image',
      'mediaUrl': c[3],
      'imageUrl': c[3],
      'isActive': true,
    },
];

final List<Map<String, dynamic>> _workoutBanners = [
  {'bannerId': 'wban_1', 'title': '30-Day Strength Challenge', 'subtitle': 'Join 4,200 athletes this month', 'imageUrl': _unsplash('1534438327276-14e5300c3a48', w: 1200), 'mediaType': 'image', 'targetType': 'workout', 'targetId': 'w_strength', 'targetName': '4-Week Strength Builder', 'badge': 'CHALLENGE', 'buttonText': 'Start now', 'showTitle': true, 'isActive': true},
  {'bannerId': 'wban_2', 'title': 'Burn Fat in 20 Minutes', 'subtitle': 'No equipment HIIT', 'imageUrl': _unsplash('1571019613454-1cb2f99b2d8b', w: 1200), 'mediaType': 'image', 'targetType': 'workout', 'targetId': 'w_hiit', 'targetName': 'Fat Burn HIIT', 'badge': 'POPULAR', 'buttonText': 'Try it', 'showTitle': true, 'isActive': true},
  {'bannerId': 'wban_3', 'title': 'Morning Mobility', 'subtitle': 'Start the day loose and calm', 'imageUrl': _unsplash('1506126613408-eca07ce68773', w: 1200), 'mediaType': 'image', 'targetType': 'category', 'targetId': 'wcat_yoga', 'targetName': 'Yoga & Flow', 'badge': 'NEW', 'buttonText': 'Explore', 'showTitle': true, 'isActive': true},
];

Map<String, dynamic> _wl(String id, String title, String type, String mode, {String subtitle = '', List<String> ids = const []}) => {
      'sectionId': id,
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'type': type,
      'layoutMode': mode,
      'filterSource': 'all',
      'filterId': '',
      'filterName': '',
      'selectedItemIds': ids,
      'itemLimit': 8,
      'showTitle': true,
      'showHeading': true,
      'isActive': true,
    };

final List<Map<String, dynamic>> _workoutLayout = [
  _wl('wsec_hero', 'Featured', 'hero_banners', 'hero_carousel', ids: ['wban_1', 'wban_2', 'wban_3']),
  _wl('wsec_cats', 'Browse by Category', 'categories', 'carousel'),
  _wl('wsec_popular', 'Popular Programs', 'popular_programs', 'carousel', subtitle: 'Most started this week', ids: ['w_strength', 'w_hiit', 'w_core']),
  _wl('wsec_muscles', 'Train by Muscle', 'muscle_groups', 'grid'),
  _wl('wsec_trending', 'Trending Challenges', 'trending_challenges', 'carousel'),
  _wl('wsec_coaches', 'Celebrity Coaches', 'celebrity_coaches', 'carousel'),
];

final List<Map<String, dynamic>> _programs = [
  {'id': 'prog_shred', 'title': '8-Week Shred', 'type': '8-Week Shreds', 'subtitle': 'Lose fat, keep muscle', 'weeks': 8, 'workoutsPerWeek': 5, 'level': 'Advanced', 'coach': 'Coach Vikram', 'enrolledCount': 1420, 'rating': 4.9, 'price': 1999.0, 'badge': 'BESTSELLER', 'imageUrl': _unsplash('1534438327276-14e5300c3a48'), 'description': 'A structured 8-week cut with strength days, HIIT finishers and a meal guide.', 'features': ['40 guided workouts', 'Weekly check-ins', 'Meal guide'], 'isActive': true, 'status': 'Active'},
  {'id': 'prog_begin', 'title': 'Beginner Foundations', 'type': '4-Week Starter', 'subtitle': 'Learn the basics safely', 'weeks': 4, 'workoutsPerWeek': 3, 'level': 'Beginner', 'coach': 'Coach Aisha', 'enrolledCount': 2310, 'rating': 4.8, 'price': 999.0, 'badge': 'NEW', 'imageUrl': _unsplash('1571019613454-1cb2f99b2d8b'), 'description': 'Form-first training for complete beginners, three short sessions a week.', 'features': ['12 guided workouts', 'Form videos', 'Habit tracker'], 'isActive': true, 'status': 'Active'},
  {'id': 'prog_yoga', 'title': 'Yoga for Athletes', 'type': '6-Week Mobility', 'subtitle': 'Move better, recover faster', 'weeks': 6, 'workoutsPerWeek': 4, 'level': 'Intermediate', 'coach': 'Coach Meera', 'enrolledCount': 860, 'rating': 4.9, 'price': 1499.0, 'badge': 'TRENDING', 'imageUrl': _unsplash('1506126613408-eca07ce68773'), 'description': 'Mobility flows that fit around your training week.', 'features': ['24 flows', 'Breathwork', 'Recovery plans'], 'isActive': true, 'status': 'Active'},
];

final List<Map<String, dynamic>> _plans = [
  {'planId': 'plan_free', 'name': 'Starter', 'title': 'Starter', 'tagline': 'Everything you need to begin', 'badge': '', 'monthlyPrice': 0.0, 'yearlyPrice': 0.0, 'currency': '₹', 'features': ['Basic workouts', 'Step tracking', 'Community feed'], 'isPopular': false, 'status': 'Active', 'isActive': true, 'subscribersCount': 12840, 'sortOrder': 1},
  {'planId': 'plan_pro', 'name': 'Pro', 'title': 'Pro', 'tagline': 'Personal plans and Kemo AI', 'badge': 'MOST POPULAR', 'monthlyPrice': 499.0, 'yearlyPrice': 4499.0, 'currency': '₹', 'features': ['All programs', 'Kemo AI coach', 'Nutrition plans', 'No ads'], 'isPopular': true, 'status': 'Active', 'isActive': true, 'subscribersCount': 3260, 'sortOrder': 2},
  {'planId': 'plan_elite', 'name': 'Elite', 'title': 'Elite', 'tagline': '1-on-1 coaching with a trainer', 'badge': 'BEST VALUE', 'monthlyPrice': 1499.0, 'yearlyPrice': 13999.0, 'currency': '₹', 'features': ['Everything in Pro', 'Personal trainer', 'Weekly video calls', 'Priority support'], 'isPopular': false, 'status': 'Active', 'isActive': true, 'subscribersCount': 540, 'sortOrder': 3},
];

final List<Map<String, dynamic>> _cmsItems = [
  {'itemId': 'cms_1', 'type': 'banner', 'title': 'New: 8-Week Shred', 'subtitle': 'Enrolment open now', 'imageUrl': _unsplash('1534438327276-14e5300c3a48', w: 1200), 'targetType': 'program', 'targetId': 'prog_shred', 'targetName': '8-Week Shred', 'badge': 'FEATURED', 'buttonText': 'Explore', 'sortOrder': 1, 'status': 'Active', 'isActive': true},
  {'itemId': 'cms_2', 'type': 'banner', 'title': 'Yoga Week', 'subtitle': 'Free mobility flows all week', 'imageUrl': _unsplash('1506126613408-eca07ce68773', w: 1200), 'targetType': 'category', 'targetId': 'wcat_yoga', 'targetName': 'Yoga & Flow', 'badge': 'FREE', 'buttonText': 'Start', 'sortOrder': 2, 'status': 'Active', 'isActive': true},
];

// Static demo catalogue
// -----------------------------------------------------------------------------
final List<Map<String, dynamic>> _categories = [
  {'id': 'cat_supplements', 'name': 'Supplements', 'slug': 'supplements', 'imageUrl': _unsplash('1593095948071-474c5cc2989d', w: 400), 'sortOrder': 1, 'isActive': true, 'productCount': 4},
  {'id': 'cat_equipment', 'name': 'Equipment', 'slug': 'equipment', 'imageUrl': _unsplash('1534438327276-14e5300c3a48', w: 400), 'sortOrder': 2, 'isActive': true, 'productCount': 4},
  {'id': 'cat_apparel', 'name': 'Apparel', 'slug': 'apparel', 'imageUrl': _unsplash('1542291026-7eec264c27ff', w: 400), 'sortOrder': 3, 'isActive': true, 'productCount': 3},
  {'id': 'cat_snacks', 'name': 'Healthy Snacks', 'slug': 'healthy-snacks', 'imageUrl': _unsplash('1490645935967-10de6ba17061', w: 400), 'sortOrder': 4, 'isActive': true, 'productCount': 2},
];

final List<Map<String, dynamic>> _subcategories = [
  {'id': 'sub_protein', 'name': 'Protein', 'parentCategoryId': 'cat_supplements', 'parentCategoryName': 'Supplements', 'imageUrl': _unsplash('1593095948071-474c5cc2989d', w: 300), 'sortOrder': 1, 'isActive': true},
  {'id': 'sub_vitamins', 'name': 'Vitamins', 'parentCategoryId': 'cat_supplements', 'parentCategoryName': 'Supplements', 'imageUrl': _unsplash('1584308666744-24d5c474f2ae', w: 300), 'sortOrder': 2, 'isActive': true},
  {'id': 'sub_weights', 'name': 'Weights', 'parentCategoryId': 'cat_equipment', 'parentCategoryName': 'Equipment', 'imageUrl': _unsplash('1534438327276-14e5300c3a48', w: 300), 'sortOrder': 1, 'isActive': true},
  {'id': 'sub_bands', 'name': 'Bands & Mats', 'parentCategoryId': 'cat_equipment', 'parentCategoryName': 'Equipment', 'imageUrl': _unsplash('1518611012118-696072aa579a', w: 300), 'sortOrder': 2, 'isActive': true},
  {'id': 'sub_shoes', 'name': 'Shoes', 'parentCategoryId': 'cat_apparel', 'parentCategoryName': 'Apparel', 'imageUrl': _unsplash('1542291026-7eec264c27ff', w: 300), 'sortOrder': 1, 'isActive': true},
  {'id': 'sub_bars', 'name': 'Protein Bars', 'parentCategoryId': 'cat_snacks', 'parentCategoryName': 'Healthy Snacks', 'imageUrl': _unsplash('1490645935967-10de6ba17061', w: 300), 'sortOrder': 1, 'isActive': true},
];

Map<String, dynamic> _product(String id, String title, String cat, String catName, String sub,
        String subName, double price, double regular, String img,
        {bool featured = false, double rating = 4.6, int reviews = 120, String desc = ''}) =>
    {
      'id': id,
      'title': title,
      'description': desc.isNotEmpty
          ? desc
          : '$title from the Neurofit store. Demo product for previewing the shop screens.',
      'sku': 'NF-${id.toUpperCase()}',
      'categoryId': cat,
      'categoryName': catName,
      'subcategoryId': sub,
      'subcategoryName': subName,
      'price': price,
      'regularPrice': regular,
      'stock': 40,
      'brand': 'Neurofit',
      'vendor': 'Neurofit Official',
      'tags': [catName.toLowerCase(), subName.toLowerCase()],
      'status': 'active',
      'mainImageUrl': img,
      'additionalImages': [img],
      'variants': [],
      'isFeatured': featured,
      'rating': rating,
      'reviewCount': reviews,
    };

final List<Map<String, dynamic>> _products = [
  _product('p_whey', 'Whey Protein Isolate 1kg', 'cat_supplements', 'Supplements', 'sub_protein', 'Protein', 2999, 3799, _unsplash('1593095948071-474c5cc2989d'), featured: true, rating: 4.8, reviews: 842, desc: '27g protein per scoop, low sugar, chocolate flavour. Mixes smoothly with water or milk.'),
  _product('p_creatine', 'Creatine Monohydrate 250g', 'cat_supplements', 'Supplements', 'sub_protein', 'Protein', 899, 1199, _unsplash('1579722821273-0f6c7d44362f'), featured: true, rating: 4.7, reviews: 516),
  _product('p_multi', 'Daily Multivitamin (60 tabs)', 'cat_supplements', 'Supplements', 'sub_vitamins', 'Vitamins', 549, 699, _unsplash('1584308666744-24d5c474f2ae'), rating: 4.5, reviews: 210),
  _product('p_shaker', 'Neurofit Steel Shaker', 'cat_supplements', 'Supplements', 'sub_protein', 'Protein', 499, 699, _unsplash('1517838277536-f5f99be501cd'), rating: 4.4, reviews: 98),
  _product('p_dumbbell', 'Adjustable Dumbbells 2×10kg', 'cat_equipment', 'Equipment', 'sub_weights', 'Weights', 4499, 5999, _unsplash('1534438327276-14e5300c3a48'), featured: true, rating: 4.7, reviews: 301),
  _product('p_bands', 'Resistance Bands Set', 'cat_equipment', 'Equipment', 'sub_bands', 'Bands & Mats', 1799, 2299, _unsplash('1518611012118-696072aa579a'), featured: true, rating: 4.6, reviews: 455),
  _product('p_mat', 'Yoga Mat 6mm', 'cat_equipment', 'Equipment', 'sub_bands', 'Bands & Mats', 1299, 1599, _unsplash('1506126613408-eca07ce68773'), rating: 4.5, reviews: 187),
  _product('p_kettle', 'Cast Iron Kettlebell 12kg', 'cat_equipment', 'Equipment', 'sub_weights', 'Weights', 2199, 2699, _unsplash('1517836357463-d25dfeac3438'), rating: 4.6, reviews: 143),
  _product('p_shoes', 'Neurofit Runner Shoes', 'cat_apparel', 'Apparel', 'sub_shoes', 'Shoes', 3499, 4999, _unsplash('1542291026-7eec264c27ff'), featured: true, rating: 4.7, reviews: 389),
  _product('p_tee', 'DryFit Training Tee', 'cat_apparel', 'Apparel', 'sub_shoes', 'Shoes', 799, 1199, _unsplash('1581009146145-b5ef050c2e1e'), rating: 4.3, reviews: 76),
  _product('p_bar', 'Protein Bar Box (12)', 'cat_snacks', 'Healthy Snacks', 'sub_bars', 'Protein Bars', 1199, 1440, _unsplash('1490645935967-10de6ba17061'), rating: 4.4, reviews: 164),
  _product('p_granola', 'High-Protein Granola 500g', 'cat_snacks', 'Healthy Snacks', 'sub_bars', 'Protein Bars', 449, 599, _unsplash('1512621776951-a57141f2eefd'), rating: 4.5, reviews: 92),
];

final List<Map<String, dynamic>> _banners = [
  {'id': 'ban_1', 'title': 'Protein Week', 'subtitle': 'Up to 25% off whey and creatine', 'badge': 'LIMITED', 'buttonText': 'Shop Protein', 'imageUrl': _unsplash('1593095948071-474c5cc2989d', w: 1200), 'targetType': 'category', 'targetId': 'cat_supplements', 'targetName': 'Supplements', 'discountCode': 'PROTEIN25', 'sortOrder': 1, 'isActive': true},
  {'id': 'ban_2', 'title': 'Build Your Home Gym', 'subtitle': 'Dumbbells, kettlebells and bands', 'badge': 'NEW', 'buttonText': 'Explore', 'imageUrl': _unsplash('1534438327276-14e5300c3a48', w: 1200), 'targetType': 'category', 'targetId': 'cat_equipment', 'targetName': 'Equipment', 'discountCode': '', 'sortOrder': 2, 'isActive': true},
  {'id': 'ban_3', 'title': 'Run Further', 'subtitle': 'New Neurofit Runner shoes', 'badge': 'FEATURED', 'buttonText': 'View', 'imageUrl': _unsplash('1542291026-7eec264c27ff', w: 1200), 'targetType': 'product', 'targetId': 'p_shoes', 'targetName': 'Neurofit Runner Shoes', 'discountCode': '', 'sortOrder': 3, 'isActive': true},
];

final List<Map<String, dynamic>> _layoutSections = [
  {'id': 'sec_banners', 'title': 'Top Deals', 'type': 'banners', 'layoutMode': 'hero_carousel', 'filterSource': 'all', 'sortOrder': 1, 'isActive': true, 'showTitle': false},
  {'id': 'sec_categories', 'title': 'Shop by Category', 'type': 'categories', 'layoutMode': 'carousel', 'filterSource': 'all', 'sortOrder': 2, 'isActive': true},
  {'id': 'sec_featured', 'title': 'Featured Picks', 'subtitle': 'Most loved by the community', 'type': 'products', 'layoutMode': 'carousel', 'filterSource': 'featured', 'itemLimit': 8, 'sortOrder': 3, 'isActive': true},
  {'id': 'sec_supplements', 'title': 'Supplements', 'type': 'products', 'layoutMode': 'carousel', 'filterSource': 'category', 'filterId': 'cat_supplements', 'filterName': 'Supplements', 'itemLimit': 8, 'sortOrder': 4, 'isActive': true},
  {'id': 'sec_all', 'title': 'All Products', 'type': 'products', 'layoutMode': 'grid', 'filterSource': 'all', 'itemLimit': 12, 'sortOrder': 5, 'isActive': true},
];

final List<Map<String, dynamic>> _discounts = [
  {'id': 'disc_1', 'code': 'PROTEIN25', 'title': '25% off supplements', 'type': 'percentage', 'value': 25, 'minOrderValue': 999, 'maxUses': 1000, 'usedCount': 120, 'isActive': true},
  {'id': 'disc_2', 'code': 'WELCOME200', 'title': '₹200 off your first order', 'type': 'fixed', 'value': 200, 'minOrderValue': 1499, 'maxUses': 1000, 'usedCount': 48, 'isActive': true},
];

Map<String, dynamic> _ex(String id, String name, String muscle, String gif, String tip,
        {int sets = 3, int reps = 12, int seconds = 0, int rest = 45}) =>
    {
      'exerciseId': id,
      'title': name,
      'muscleGroup': muscle,
      'mediaUrl': '$_gifBase/videos/$gif',
      'mediaType': 'gif',
      'sets': sets,
      'reps': reps,
      'durationSeconds': seconds,
      'restSeconds': rest,
      'instructions': tip,
    };

final _benchPress = _ex('0025', 'Barbell Bench Press', 'Chest', '0025-EIeI8Vf.gif', 'Keep your feet planted and lower the bar to mid-chest.', reps: 10);
final _pushUp = _ex('0662', 'Push-up', 'Chest', '0662-I4hDWkc.gif', 'Body in a straight line, elbows at about 45 degrees.', reps: 15);
final _inclinePress = _ex('0314', 'Dumbbell Incline Press', 'Chest', '0314-ns0SIbU.gif', 'Bench at 45 degrees, press up and slightly in.', reps: 10);
final _pullUp = _ex('0652', 'Pull-up', 'Back', '0652-lBDjFxJ.gif', 'Pull your chest to the bar, control the way down.', reps: 8);
final _row = _ex('0027', 'Barbell Bent-over Row', 'Back', '0027-eZyBC3j.gif', 'Hinge at the hips and pull the bar to your belly.', reps: 10);
final _pulldown = _ex('2330', 'Lat Pulldown', 'Back', '2330-LEprlgG.gif', 'Pull the bar to your upper chest, squeeze your back.', reps: 12);
final _squat = _ex('0043', 'Barbell Squat', 'Legs', '0043-qXTaZnJ.gif', 'Chest up, knees track over toes, go to parallel.', reps: 8, rest: 90);
final _deadlift = _ex('0032', 'Barbell Deadlift', 'Legs', '0032-ila4NZS.gif', 'Keep the bar close and your back flat.', reps: 6, rest: 90);
final _lunge = _ex('0336', 'Dumbbell Lunge', 'Legs', '0336-RRWFUcw.gif', 'Step forward and lower until both knees are at 90 degrees.', reps: 12);
final _legPress = _ex('2287', 'Leg Press', 'Legs', '2287-V07qpXy.gif', 'Press through your heels, do not lock your knees.', reps: 12);
final _lateralRaise = _ex('0334', 'Dumbbell Lateral Raise', 'Shoulders', '0334-DsgkuIt.gif', 'Lift to shoulder height with a slight bend in the elbows.', reps: 15);
final _curl = _ex('0294', 'Dumbbell Biceps Curl', 'Arms', '0294-NbVPDMW.gif', 'Keep your elbows by your sides.', reps: 12);
final _dip = _ex('0814', 'Triceps Dip', 'Arms', '0814-X6C6i5Y.gif', 'Lower until your elbows reach 90 degrees.', reps: 12);
final _bicycle = _ex('0972', 'Bicycle Crunch', 'Core', '0972-tZkGYZ9.gif', 'Bring the opposite elbow to knee, slow and controlled.', reps: 20);
final _sidePlank = _ex('3544', 'Side Plank', 'Core', '3544-5VXmnV5.gif', 'Hips up, body in a straight line.', reps: 1, seconds: 30);
final _russianTwist = _ex('0687', 'Russian Twist', 'Core', '0687-XVDdcoj.gif', 'Lean back slightly and rotate from your torso.', reps: 20);
final _climber = _ex('0630', 'Mountain Climber', 'Cardio', '0630-RJgzwny.gif', 'Drive your knees fast, keep hips level.', reps: 1, seconds: 40, rest: 20);
final _burpee = _ex('1160', 'Burpee', 'Cardio', '1160-dK9394r.gif', 'Chest to floor, then jump with arms overhead.', reps: 12, rest: 30);
final _jumpSquat = _ex('0514', 'Jump Squat', 'Legs', '0514-LIlE5Tn.gif', 'Land softly and go straight into the next rep.', reps: 15, rest: 30);
final _highKnee = _ex('3636', 'High Knees', 'Cardio', '3636-ealLwvX.gif', 'Knees to hip height, stay on the balls of your feet.', reps: 1, seconds: 40, rest: 20);
final _goblet = _ex('1760', 'Goblet Squat', 'Legs', '1760-yn8yg1r.gif', 'Hold the dumbbell at your chest, sit between your heels.', reps: 12);
final _swing = _ex('0549', 'Kettlebell Swing', 'Full Body', '0549-UHJlbu3.gif', 'Snap your hips forward, arms stay relaxed.', reps: 15);

Map<String, dynamic> _day(int n, String title, String focus, List<Map<String, dynamic>> ex,
        {int minutes = 45, int kcal = 350, bool rest = false}) =>
    {
      'dayNumber': n,
      'weekNumber': ((n - 1) ~/ 7) + 1,
      'title': title,
      'focus': focus,
      'durationMinutes': minutes,
      'caloriesBurn': kcal,
      'isRestDay': rest,
      'exercises': ex,
    };

Map<String, dynamic> _workout(String id, String title, String subtitle, String cat, String catName,
        String level, String coach, String img, List<Map<String, dynamic>> days,
        {int minutes = 45, int kcal = 380, bool featured = true, double rating = 4.8}) {
  final firstDayExercises = (days.first['exercises'] as List);
  return {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'description':
        '$title is a $level program by $coach. Follow the days in order and track every set in the app.',
    'category': catName,
    'workoutCategoryId': cat,
    'durationMinutes': minutes,
    'caloriesBurn': kcal,
    'level': level,
    'coach': coach,
    'imageUrl': img,
    'mediaType': 'image',
    'exercisesCount': firstDayExercises.length,
    'rating': rating,
    'completionRate': 91.0,
    'tags': [catName, level],
    'exercises': firstDayExercises,
    'days': days,
    'isFeatured': featured,
    'isActive': true,
  };
}

final List<Map<String, dynamic>> _workouts = [
  _workout('w_strength', '4-Week Strength Builder', 'Push, pull and legs split', 'wcat_strength', 'Strength', 'Intermediate', 'Coach Vikram', _unsplash('1534438327276-14e5300c3a48'), [
    _day(1, 'Push Day', 'Chest, shoulders & triceps', [_benchPress, _inclinePress, _lateralRaise, _dip]),
    _day(2, 'Pull Day', 'Back & biceps', [_pullUp, _row, _pulldown, _curl]),
    _day(3, 'Leg Day', 'Quads, glutes & hamstrings', [_squat, _deadlift, _lunge, _legPress], minutes: 55, kcal: 450),
    _day(4, 'Rest & Recover', 'Light walk and stretching', [], minutes: 20, kcal: 90, rest: true),
    _day(5, 'Upper Body', 'Full upper body', [_pushUp, _row, _lateralRaise, _curl, _dip]),
  ], minutes: 50, kcal: 420),
  _workout('w_hiit', 'Fat Burn HIIT', '20-minute intervals, no equipment', 'wcat_hiit', 'HIIT & Circuit', 'Beginner', 'Coach Aisha', _unsplash('1571019613454-1cb2f99b2d8b'), [
    _day(1, 'Full Body Blast', 'Cardio intervals', [_burpee, _jumpSquat, _climber, _highKnee], minutes: 20, kcal: 280),
    _day(2, 'Lower Body Burn', 'Legs & cardio', [_jumpSquat, _lunge, _highKnee, _goblet], minutes: 22, kcal: 300),
    _day(3, 'Core Cardio', 'Abs & conditioning', [_climber, _bicycle, _russianTwist, _burpee], minutes: 20, kcal: 260),
  ], minutes: 20, kcal: 280),
  _workout('w_core', 'Core Crusher', 'Stronger abs in 15 minutes', 'wcat_core', 'Core & Abs', 'Beginner', 'Coach Meera', _unsplash('1518611012118-696072aa579a'), [
    _day(1, 'Abs Basics', 'Upper & lower abs', [_bicycle, _russianTwist, _sidePlank], minutes: 15, kcal: 140),
    _day(2, 'Obliques', 'Side core', [_sidePlank, _russianTwist, _climber], minutes: 15, kcal: 150),
  ], minutes: 15, kcal: 140),
  _workout('w_yoga', 'Morning Mobility Flow', 'Gentle stretching to start the day', 'wcat_yoga', 'Yoga & Flow', 'Beginner', 'Coach Meera', _unsplash('1506126613408-eca07ce68773'), [
    _day(1, 'Wake Up Flow', 'Hips, spine & shoulders', [_sidePlank, _lunge, _goblet], minutes: 25, kcal: 120),
  ], minutes: 25, kcal: 120, rating: 4.9),
  _workout('w_cardio', 'Cardio Endurance', 'Build your stamina', 'wcat_cardio', 'Cardio Blast', 'Intermediate', 'Coach Arjun', _unsplash('1517838277536-f5f99be501cd'), [
    _day(1, 'Intervals', 'Heart-rate zones 3 to 4', [_highKnee, _burpee, _climber, _jumpSquat], minutes: 30, kcal: 360),
    _day(2, 'Kettlebell Conditioning', 'Power & cardio', [_swing, _goblet, _climber], minutes: 30, kcal: 380),
  ], minutes: 30, kcal: 360),
  _workout('w_home', 'Home Dumbbell Plan', 'Full body with one pair of dumbbells', 'wcat_strength', 'Strength', 'Beginner', 'Coach Vikram', _unsplash('1581009146145-b5ef050c2e1e'), [
    _day(1, 'Full Body A', 'Strength basics', [_goblet, _inclinePress, _lunge, _curl]),
    _day(2, 'Full Body B', 'Strength basics', [_swing, _pushUp, _lateralRaise, _dip]),
  ], minutes: 40, kcal: 330, featured: false),
];

final List<Map<String, dynamic>> _exerciseCategories = [
  for (final c in const [
    ['ec_chest', 'Chest', '0025-EIeI8Vf'],
    ['ec_back', 'Back', '0652-lBDjFxJ'],
    ['ec_legs', 'Legs', '0043-qXTaZnJ'],
    ['ec_shoulders', 'Shoulders', '0334-DsgkuIt'],
    ['ec_arms', 'Arms', '0294-NbVPDMW'],
    ['ec_core', 'Core', '0972-tZkGYZ9'],
  ])
    {
      'id': c[0],
      'name': c[1],
      'slug': c[1].toLowerCase(),
      'imageUrl': '$_gifBase/images/${c[2]}.jpg',
      'mediaType': 'image',
      'isActive': true,
    },
];
