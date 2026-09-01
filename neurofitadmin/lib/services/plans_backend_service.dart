import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'redis_cache_service.dart';

class SubscriptionPlanModel {
  final String planId;
  final String id;
  String name;
  String title;
  String tagline;
  String badge;
  double monthlyPrice;
  double yearlyPrice;
  String currency;
  List<String> features;
  bool isPopular;
  String status;
  bool isActive;
  int subscribersCount;
  int sortOrder;
  final DateTime createdAt;
  DateTime updatedAt;

  SubscriptionPlanModel({
    required this.planId,
    String? id,
    required this.name,
    String? title,
    this.tagline = '',
    this.badge = '',
    required this.monthlyPrice,
    required this.yearlyPrice,
    this.currency = '₹',
    required this.features,
    this.isPopular = false,
    this.status = 'Active',
    this.isActive = true,
    this.subscribersCount = 0,
    this.sortOrder = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? planId,
        title = title ?? name,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toFirestoreFields() {
    return {
      'planId': {'stringValue': planId},
      'id': {'stringValue': id},
      'name': {'stringValue': name},
      'title': {'stringValue': title},
      'tagline': {'stringValue': tagline},
      'badge': {'stringValue': badge},
      'monthlyPrice': {'doubleValue': monthlyPrice},
      'yearlyPrice': {'doubleValue': yearlyPrice},
      'currency': {'stringValue': currency},
      'features': {
        'arrayValue': {
          'values': features.map((f) => {'stringValue': f}).toList()
        }
      },
      'isPopular': {'booleanValue': isPopular},
      'status': {'stringValue': status},
      'isActive': {'booleanValue': isActive},
      'subscribersCount': {'integerValue': subscribersCount.toString()},
      'sortOrder': {'integerValue': sortOrder.toString()},
      'createdAt': {'timestampValue': createdAt.toUtc().toIso8601String()},
      'updatedAt': {'timestampValue': updatedAt.toUtc().toIso8601String()},
    };
  }

  factory SubscriptionPlanModel.fromFirestoreDoc(Map<String, dynamic> doc) {
    final String fullPath = doc['name'] ?? '';
    final String docId = fullPath.split('/').last;
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};

    final String pId = fields['planId']?['stringValue'] ?? fields['id']?['stringValue'] ?? docId;
    final String name = fields['name']?['stringValue'] ?? fields['title']?['stringValue'] ?? 'Plan';
    final String title = fields['title']?['stringValue'] ?? name;
    final String tagline = fields['tagline']?['stringValue'] ?? '';
    final String badge = fields['badge']?['stringValue'] ?? '';

    final double monthlyPrice = (fields['monthlyPrice']?['doubleValue'] != null)
        ? (fields['monthlyPrice']['doubleValue'] as num).toDouble()
        : double.tryParse(fields['monthlyPrice']?['integerValue']?.toString() ?? '499') ?? 499.0;

    final double yearlyPrice = (fields['yearlyPrice']?['doubleValue'] != null)
        ? (fields['yearlyPrice']['doubleValue'] as num).toDouble()
        : double.tryParse(fields['yearlyPrice']?['integerValue']?.toString() ?? '4499') ?? 4499.0;

    final String currency = fields['currency']?['stringValue'] ?? '₹';

    final List<String> features = [];
    final fArray = fields['features']?['arrayValue']?['values'] as List<dynamic>?;
    if (fArray != null) {
      for (var f in fArray) {
        if (f['stringValue'] != null) features.add(f['stringValue']);
      }
    }

    final bool isPopular = fields['isPopular']?['booleanValue'] ?? false;
    final String status = fields['status']?['stringValue'] ?? 'Active';
    final bool isActive = fields['isActive']?['booleanValue'] ?? (status == 'Active');
    final int subscribersCount = int.tryParse(fields['subscribersCount']?['integerValue']?.toString() ?? '0') ?? 0;
    final int sortOrder = int.tryParse(fields['sortOrder']?['integerValue']?.toString() ?? '1') ?? 1;

    final DateTime createdAt = fields['createdAt']?['timestampValue'] != null
        ? DateTime.tryParse(fields['createdAt']['timestampValue']) ?? DateTime.now()
        : DateTime.now();
    final DateTime updatedAt = fields['updatedAt']?['timestampValue'] != null
        ? DateTime.tryParse(fields['updatedAt']['timestampValue']) ?? DateTime.now()
        : DateTime.now();

    return SubscriptionPlanModel(
      planId: pId,
      id: docId,
      name: name,
      title: title,
      tagline: tagline,
      badge: badge,
      monthlyPrice: monthlyPrice,
      yearlyPrice: yearlyPrice,
      currency: currency,
      features: features,
      isPopular: isPopular,
      status: status,
      isActive: isActive,
      subscribersCount: subscribersCount,
      sortOrder: sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class PlansBackendService {
  static final PlansBackendService _instance = PlansBackendService._internal();
  factory PlansBackendService() => _instance;
  PlansBackendService._internal() {
    fetchPlansFromFirestore();
  }

  static const String firebaseProjectId = 'neurofit-52fe0';
  static const String firebaseApiKey = 'AIzaSyDcGovQH3Sd_0kdNeSISK6eNCdtjA_g9vg';

  final List<SubscriptionPlanModel> _plans = [];
  List<SubscriptionPlanModel> get plans => List.unmodifiable(_plans);

  /// Fetch all plans from Firestore with Redis acceleration
  Future<void> fetchPlansFromFirestore() async {
    try {
      

      final Uri uri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/subscription_plans?key=$firebaseApiKey',
      );

      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final documents = data['documents'] as List<dynamic>?;
        if (documents != null && documents.isNotEmpty) {
          final List<SubscriptionPlanModel> fetched = [];
          for (var doc in documents) {
            fetched.add(SubscriptionPlanModel.fromFirestoreDoc(doc));
          }

          if (fetched.isNotEmpty) {
            _plans.clear();
            _plans.addAll(fetched);

            final serializable = fetched.map((p) => {
              'planId': p.planId,
              'id': p.id,
              'name': p.name,
              'title': p.title,
              'tagline': p.tagline,
              'badge': p.badge,
              'monthlyPrice': p.monthlyPrice,
              'yearlyPrice': p.yearlyPrice,
              'currency': p.currency,
              'features': p.features,
              'isPopular': p.isPopular,
              'status': p.status,
              'isActive': p.isActive,
              'subscribersCount': p.subscribersCount,
              'sortOrder': p.sortOrder,
            }).toList();
            await RedisCacheService().set('cache:subscription_plans:all', jsonEncode(serializable), ttlSeconds: 3600);
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore fetch plans error: $e');
    }
  }

  /// Create new plan in Firestore
  Future<SubscriptionPlanModel?> createPlan({
    required String name,
    required String tagline,
    required String badge,
    required double monthlyPrice,
    required double yearlyPrice,
    required List<String> features,
    required bool isPopular,
  }) async {
    try {
      final pId = 'plan_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();

      final newPlan = SubscriptionPlanModel(
        planId: pId,
        id: pId,
        name: name,
        title: name,
        tagline: tagline,
        badge: badge,
        monthlyPrice: monthlyPrice,
        yearlyPrice: yearlyPrice,
        features: features,
        isPopular: isPopular,
        status: 'Active',
        isActive: true,
        subscribersCount: 0,
        sortOrder: _plans.length + 1,
        createdAt: now,
        updatedAt: now,
      );

      final Uri firestoreUri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/subscription_plans?key=$firebaseApiKey&documentId=$pId',
      );

      await http.post(
        firestoreUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fields': newPlan.toFirestoreFields()}),
      );

      _plans.add(newPlan);
      
      return newPlan;
    } catch (e) {
      debugPrint('Create plan error: $e');
      return null;
    }
  }

  /// Update plan in Firestore
  Future<void> updatePlan(SubscriptionPlanModel plan) async {
    final index = _plans.indexWhere((p) => p.planId == plan.planId || p.id == plan.planId);
    if (index != -1) {
      _plans[index] = plan;

      try {
        final Uri firestoreUri = Uri.parse(
          'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/subscription_plans/${plan.planId}?key=$firebaseApiKey',
        );

        await http.patch(
          firestoreUri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'fields': plan.toFirestoreFields()}),
        );

        
      } catch (e) {
        debugPrint('Update plan error: $e');
      }
    }
  }

  /// Delete plan from Firestore
  Future<void> deletePlan(String planId) async {
    _plans.removeWhere((p) => p.planId == planId || p.id == planId);

    try {
      final Uri firestoreUri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/subscription_plans/$planId?key=$firebaseApiKey',
      );
      await http.delete(firestoreUri);
      
    } catch (e) {
      debugPrint('Delete plan error: $e');
    }
  }
}
