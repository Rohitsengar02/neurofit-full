import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';

class DiscountModel {
  final String discountId;
  final String id;
  String title;
  String code;
  String type; // 'percentage' or 'fixed'
  double value; // e.g. 20.0 (for 20%) or 500.0 (for ₹500)
  double minOrderValue;
  int usedCount;
  int maxUses;
  String status; // 'Active' or 'Deactivated'
  bool isActive;
  final DateTime createdAt;
  DateTime updatedAt;

  DiscountModel({
    required this.discountId,
    String? id,
    required this.title,
    required this.code,
    required this.type,
    required this.value,
    this.minOrderValue = 0.0,
    this.usedCount = 0,
    this.maxUses = 500,
    this.status = 'Active',
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? discountId,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory DiscountModel.fromJson(Map<String, dynamic> json) {
    return DiscountModel(
      discountId: json['discountId'] ?? json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      code: json['code'] ?? '',
      type: json['type'] ?? 'percentage',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      minOrderValue: (json['minOrderValue'] as num?)?.toDouble() ?? 0.0,
      maxUses: (json['maxUses'] as num?)?.toInt() ?? 1000,
      usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? 'Active',
      isActive: (json['status'] ?? 'Active') == 'Active' || json['isActive'] == true,
    );
  }

  factory DiscountModel.fromFirestoreDoc(Map<String, dynamic> doc) {
    final String path = doc['name'] ?? '';
    final String autoId = path.split('/').last;
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};

    return DiscountModel(
      discountId: autoId,
      title: fields['title']?['stringValue'] ?? '',
      code: fields['code']?['stringValue'] ?? '',
      type: fields['type']?['stringValue'] ?? 'percentage',
      value: (fields['value']?['doubleValue'] ?? fields['value']?['integerValue'] ?? 0.0).toDouble(),
      minOrderValue: (fields['minOrderValue']?['doubleValue'] ?? fields['minOrderValue']?['integerValue'] ?? 0.0).toDouble(),
      usedCount: int.tryParse(fields['usedCount']?['integerValue']?.toString() ?? '0') ?? 0,
      maxUses: int.tryParse(fields['maxUses']?['integerValue']?.toString() ?? '500') ?? 500,
      status: fields['status']?['stringValue'] ?? 'Active',
      isActive: (fields['status']?['stringValue'] ?? 'Active') == 'Active',
    );
  }

  Map<String, dynamic> toFirestoreFields() {
    return {
      'discountId': {'stringValue': discountId},
      'id': {'stringValue': id},
      'title': {'stringValue': title},
      'code': {'stringValue': code.toUpperCase()},
      'type': {'stringValue': type},
      'value': {'doubleValue': value},
      'minOrderValue': {'doubleValue': minOrderValue},
      'usedCount': {'integerValue': usedCount.toString()},
      'maxUses': {'integerValue': maxUses.toString()},
      'status': {'stringValue': status},
    };
  }
}

class DiscountsBackendService extends ChangeNotifier {
  static final DiscountsBackendService _instance = DiscountsBackendService._internal();
  factory DiscountsBackendService() => _instance;

  DiscountsBackendService._internal() {
    fetchDiscountsFromFirestore();
    _initSocket();
  }

  IO.Socket? _socket;
  void _initSocket() {
    // Demo build: no live server to listen to.
    if (ApiConstants.demoMode) return;
    try {
      final socketUri = ApiConstants.socketUrl;
      _socket = IO.io(
        socketUri,
        IO.OptionBuilder().setTransports(['websocket', 'polling']).disableAutoConnect().build(),
      );

      _socket?.connect();

      _socket?.on('discount_created', (_) => fetchDiscountsFromFirestore());
      _socket?.on('discount_updated', (_) => fetchDiscountsFromFirestore());
      _socket?.on('discount_deleted', (_) => fetchDiscountsFromFirestore());
      _socket?.on('discounts_updated', (_) => fetchDiscountsFromFirestore());
    } catch (_) {}
  }

  static const String firebaseProjectId = "neurofit-52fe0";
  static const String firebaseApiKey = "AIzaSyDcGovQH3Sd_0kdNeSISK6eNCdtjA_g9vg";

  final List<DiscountModel> _discounts = [];
  List<DiscountModel> get discounts => List.unmodifiable(_discounts);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchDiscountsFromFirestore() async {
    _isLoading = true;
    notifyListeners();

    // 1. Fetch from MongoDB Atlas Backend
    final backendUrls = [
      '${ApiConstants.apiBaseUrl}/discounts',
      ...ApiConstants.candidateBaseUrls.map((b) => '$b/api/discounts'),
    ];

    for (final url in backendUrls) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final items = data['data'] as List<dynamic>? ?? [];
          if (items.isNotEmpty) {
            _discounts.clear();
            for (var item in items) {
              _discounts.add(DiscountModel.fromJson(item));
            }
            _isLoading = false;
            notifyListeners();
            debugPrint('✅ [DISCOUNTS LOADED FROM MONGODB ATLAS] ${_discounts.length} live discount coupons');
            return;
          }
        }
      } catch (_) {}
    }

    // 2. Fallback to Firestore
    try {
      final Uri uri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/discounts?key=$firebaseApiKey',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final documents = data['documents'] as List<dynamic>?;
        if (documents != null) {
          final List<DiscountModel> fetched = [];
          for (var doc in documents) {
            fetched.add(DiscountModel.fromFirestoreDoc(doc));
          }
          fetched.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _discounts.clear();
          _discounts.addAll(fetched);
          debugPrint('✅ [DISCOUNTS LOADED FROM FIRESTORE] ${_discounts.length} live coupons');
        }
      }
    } catch (e) {
      debugPrint('Fetch discounts error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createDiscount({
    DiscountModel? discount,
    String? title,
    String? code,
    String? type,
    double? value,
    double? minOrderValue,
    int? maxUses,
    String? status,
  }) async {
    final disc = discount ??
        DiscountModel(
          discountId: 'disc_${DateTime.now().millisecondsSinceEpoch}',
          title: title ?? '',
          code: code ?? '',
          type: type ?? 'percentage',
          value: value ?? 0.0,
          minOrderValue: minOrderValue ?? 0.0,
          maxUses: maxUses ?? 1000,
          status: status ?? 'Active',
        );

    return addDiscount(disc);
  }

  Future<bool> addDiscount(DiscountModel discount) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Sync to MongoDB Atlas Backend
      final backendUrls = [
        '${ApiConstants.apiBaseUrl}/discounts',
        ...ApiConstants.candidateBaseUrls.map((b) => '$b/api/discounts'),
      ];

      for (final url in backendUrls) {
        try {
          final res = await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'discountId': discount.discountId,
              'id': discount.discountId,
              'title': discount.title,
              'code': discount.code,
              'type': discount.type,
              'value': discount.value,
              'minOrderValue': discount.minOrderValue,
              'maxUses': discount.maxUses,
              'usedCount': discount.usedCount,
              'status': discount.status,
              'isActive': discount.isActive,
            }),
          ).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200 || res.statusCode == 201) {
            debugPrint('✅ [DISCOUNT SAVED TO MONGODB ATLAS] ${discount.code}');
            await fetchDiscountsFromFirestore();
            return true;
          }
        } catch (_) {}
      }

      // 2. Fallback to Firestore
      final Uri uri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/discounts/${discount.discountId}?key=$firebaseApiKey',
      );
      final res = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fields': discount.toFirestoreFields()}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchDiscountsFromFirestore();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding discount: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateDiscount({
    DiscountModel? discount,
    String? discountId,
    String? title,
    String? code,
    String? type,
    double? value,
    double? minOrderValue,
    int? maxUses,
    String? status,
  }) async {
    if (discount != null) {
      return addDiscount(discount);
    }

    final dId = discountId ?? '';
    final existing = _discounts.firstWhere(
      (d) => d.discountId == dId || d.id == dId,
      orElse: () => DiscountModel(
        discountId: dId,
        title: title ?? '',
        code: code ?? '',
        type: type ?? 'percentage',
        value: value ?? 0.0,
      ),
    );

    if (title != null) existing.title = title;
    if (code != null) existing.code = code;
    if (type != null) existing.type = type;
    if (value != null) existing.value = value;
    if (minOrderValue != null) existing.minOrderValue = minOrderValue;
    if (maxUses != null) existing.maxUses = maxUses;
    if (status != null) {
      existing.status = status;
      existing.isActive = status == 'Active';
    }

    return addDiscount(existing);
  }

  Future<bool> deleteDiscount(String discountId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Delete from MongoDB Atlas Backend
      final backendUrls = [
        '${ApiConstants.apiBaseUrl}/discounts/$discountId',
        ...ApiConstants.candidateBaseUrls.map((b) => '$b/api/discounts/$discountId'),
      ];

      for (final url in backendUrls) {
        try {
          final res = await http.delete(Uri.parse(url)).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200 || res.statusCode == 204) {
            debugPrint('✅ [DISCOUNT DELETED FROM MONGODB ATLAS] $discountId');
            _discounts.removeWhere((d) => d.discountId == discountId || d.id == discountId);
            notifyListeners();
            return true;
          }
        } catch (_) {}
      }

      // 2. Fallback to Firestore
      final Uri uri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/discounts/$discountId?key=$firebaseApiKey',
      );
      final res = await http.delete(uri);
      if (res.statusCode == 200 || res.statusCode == 204) {
        _discounts.removeWhere((d) => d.discountId == discountId || d.id == discountId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
