import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../widgets/upload_progress_overlay.dart';
import 'category_backend_service.dart';
import 'redis_cache_service.dart';

class FitnessCmsItemModel {
  final String itemId;
  final String id;
  String type; // 'banner' or 'spotlight'
  String title;
  String subtitle;
  String imageUrl;
  String imageKey;
  String targetType; // 'category', 'workout', 'program'
  String targetId;
  String targetName;
  String badge;
  String buttonText;
  int sortOrder;
  String status;
  bool isActive;
  final DateTime createdAt;
  DateTime updatedAt;

  FitnessCmsItemModel({
    required this.itemId,
    String? id,
    required this.type,
    required this.title,
    this.subtitle = '',
    required this.imageUrl,
    String? imageKey,
    this.targetType = 'category',
    this.targetId = '',
    this.targetName = '',
    this.badge = 'FEATURED',
    this.buttonText = 'Explore',
    this.sortOrder = 1,
    this.status = 'Active',
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? itemId,
        imageKey = imageKey ?? (imageUrl.contains('r2.dev/') ? imageUrl.split('r2.dev/').last : imageUrl),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toFirestoreFields() {
    return {
      'itemId': {'stringValue': itemId},
      'id': {'stringValue': id},
      'type': {'stringValue': type},
      'title': {'stringValue': title},
      'subtitle': {'stringValue': subtitle},
      'imageUrl': {'stringValue': imageUrl},
      'imageKey': {'stringValue': imageKey},
      'targetType': {'stringValue': targetType},
      'targetId': {'stringValue': targetId},
      'targetName': {'stringValue': targetName},
      'badge': {'stringValue': badge},
      'buttonText': {'stringValue': buttonText},
      'sortOrder': {'integerValue': sortOrder.toString()},
      'status': {'stringValue': status},
      'isActive': {'booleanValue': isActive},
      'createdAt': {'timestampValue': createdAt.toUtc().toIso8601String()},
      'updatedAt': {'timestampValue': updatedAt.toUtc().toIso8601String()},
    };
  }

  factory FitnessCmsItemModel.fromFirestoreDoc(Map<String, dynamic> doc) {
    final String fullPath = doc['name'] ?? '';
    final String docId = fullPath.split('/').last;
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};

    final String itId = fields['itemId']?['stringValue'] ?? fields['id']?['stringValue'] ?? docId;
    final String type = fields['type']?['stringValue'] ?? 'banner';
    final String title = fields['title']?['stringValue'] ?? 'Fitness CMS Item';
    final String subtitle = fields['subtitle']?['stringValue'] ?? '';
    final String imageUrl = fields['imageUrl']?['stringValue'] ?? '';
    final String imageKey = fields['imageKey']?['stringValue'] ?? '';
    final String targetType = fields['targetType']?['stringValue'] ?? 'category';
    final String targetId = fields['targetId']?['stringValue'] ?? '';
    final String targetName = fields['targetName']?['stringValue'] ?? '';
    final String badge = fields['badge']?['stringValue'] ?? 'FEATURED';
    final String buttonText = fields['buttonText']?['stringValue'] ?? 'Explore';
    final int sortOrder = int.tryParse(fields['sortOrder']?['integerValue']?.toString() ?? '1') ?? 1;
    final String status = fields['status']?['stringValue'] ?? 'Active';
    final bool isActive = fields['isActive']?['booleanValue'] ?? (status == 'Active');

    final DateTime createdAt = fields['createdAt']?['timestampValue'] != null
        ? DateTime.tryParse(fields['createdAt']['timestampValue']) ?? DateTime.now()
        : DateTime.now();
    final DateTime updatedAt = fields['updatedAt']?['timestampValue'] != null
        ? DateTime.tryParse(fields['updatedAt']['timestampValue']) ?? DateTime.now()
        : DateTime.now();

    return FitnessCmsItemModel(
      itemId: itId,
      id: docId,
      type: type,
      title: title,
      subtitle: subtitle,
      imageUrl: imageUrl,
      imageKey: imageKey,
      targetType: targetType,
      targetId: targetId,
      targetName: targetName,
      badge: badge,
      buttonText: buttonText,
      sortOrder: sortOrder,
      status: status,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class FitnessCmsBackendService extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  static final FitnessCmsBackendService _instance = FitnessCmsBackendService._internal();
  factory FitnessCmsBackendService() => _instance;
  FitnessCmsBackendService._internal() {
    fetchCmsItemsFromFirestore();
  }

  static const String firebaseProjectId = 'neurofit-52fe0';
  static const String firebaseApiKey = 'AIzaSyDcGovQH3Sd_0kdNeSISK6eNCdtjA_g9vg';

  final List<FitnessCmsItemModel> _items = [];

  List<FitnessCmsItemModel> get items => List.unmodifiable(_items);
  List<FitnessCmsItemModel> get banners => _items.where((i) => i.type == 'banner').toList();
  List<FitnessCmsItemModel> get spotlights => _items.where((i) => i.type == 'spotlight').toList();

  /// Fetch all fitness CMS documents with Redis acceleration
  Future<void> fetchBannersFromFirestore() => fetchCmsItemsFromFirestore();

  Future<void> fetchBanners() => fetchCmsItemsFromFirestore();

  Future<void> fetchCmsItemsFromFirestore() async {
    try {
      

      final Uri uri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/fitness_cms?key=$firebaseApiKey',
      );

      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final documents = data['documents'] as List<dynamic>?;
        if (documents != null && documents.isNotEmpty) {
          final List<FitnessCmsItemModel> fetched = [];
          for (var doc in documents) {
            fetched.add(FitnessCmsItemModel.fromFirestoreDoc(doc));
          }

          if (fetched.isNotEmpty) {
            _items.clear();
            _items.addAll(fetched); notifyListeners();

            final serializable = fetched.map((i) => {
              'itemId': i.itemId,
              'id': i.id,
              'type': i.type,
              'title': i.title,
              'subtitle': i.subtitle,
              'imageUrl': i.imageUrl,
              'targetType': i.targetType,
              'targetId': i.targetId,
              'targetName': i.targetName,
              'badge': i.badge,
              'buttonText': i.buttonText,
              'sortOrder': i.sortOrder,
              'status': i.status,
              'isActive': i.isActive,
            }).toList();
            await RedisCacheService().set('cache:fitness_cms:all', jsonEncode(serializable), ttlSeconds: 3600);
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore fetch fitness cms error: $e');
    }
  }

  /// Create new Banner or Spotlight item
  Future<FitnessCmsItemModel?> createCmsItem({
    required String type, // 'banner' or 'spotlight'
    required String title,
    required String subtitle,
    required String targetType,
    required String targetId,
    required String targetName,
    required String badge,
    required String buttonText,
    required int sortOrder,
    required String imageFileName,
    required Uint8List imageBytes,
  }) async {
    final notifier = UploadProgressNotifier();

    try {
      notifier.startUpload(imageFileName);

      final imageUrl = await CategoryBackendService().uploadRawImageToR2(
        fileName: imageFileName,
        imageBytes: imageBytes,
        onProgress: (p, s) => notifier.updateProgress(p, customStatus: s),
      );

      if (imageUrl == null) throw Exception('Failed to upload CMS image to Cloudflare R2');

      notifier.updateProgress(0.90, customStatus: 'Writing to Firestore fitness_cms collection...');

      final itId = 'fit_${type}_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();

      final newItem = FitnessCmsItemModel(
        itemId: itId,
        id: itId,
        type: type,
        title: title,
        subtitle: subtitle,
        imageUrl: imageUrl,
        targetType: targetType,
        targetId: targetId,
        targetName: targetName,
        badge: badge,
        buttonText: buttonText,
        sortOrder: sortOrder,
        status: 'Active',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final Uri firestoreUri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/fitness_cms?key=$firebaseApiKey&documentId=$itId',
      );

      await http.post(
        firestoreUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fields': newItem.toFirestoreFields()}),
      );

      _items.insert(0, newItem);

      notifier.completeUpload(imageUrl);
      return newItem;
    } catch (e) {
      notifier.failUpload(e.toString());
      return null;
    }
  }

  Future<FitnessCmsItemModel?> createCmsItemWithUrl({
    required String type,
    required String title,
    required String subtitle,
    required String targetType,
    required String targetId,
    required String targetName,
    required String badge,
    required String buttonText,
    required int sortOrder,
    required String imageUrl,
  }) async {
    try {
      final String itId = 'fit_cms_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();

      final newItem = FitnessCmsItemModel(
        itemId: itId,
        type: type,
        title: title,
        subtitle: subtitle,
        imageUrl: imageUrl,
        targetType: targetType,
        targetId: targetId,
        targetName: targetName,
        badge: badge,
        buttonText: buttonText,
        sortOrder: sortOrder,
        status: 'Active',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final Uri firestoreUri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/fitness_cms?key=$firebaseApiKey&documentId=$itId',
      );

      await http.post(
        firestoreUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fields': newItem.toFirestoreFields()}),
      );

      _items.insert(0, newItem);
      notifyListeners();
      return newItem;
    } catch (e) {
      return null;
    }
  }

  /// Update Fitness CMS item
  Future<void> updateCmsItem({
    required String itemId,
    required String title,
    required String subtitle,
    required String targetType,
    required String targetId,
    required String targetName,
    required String badge,
    required String buttonText,
    String? newImageUrl,
    required String status,
  }) async {
    final index = _items.indexWhere((i) => i.itemId == itemId || i.id == itemId);
    if (index != -1) {
      final it = _items[index];
      it.title = title;
      it.subtitle = subtitle;
      it.targetType = targetType;
      it.targetId = targetId;
      it.targetName = targetName;
      it.badge = badge;
      it.buttonText = buttonText;
      if (newImageUrl != null && newImageUrl.isNotEmpty) {
        it.imageUrl = newImageUrl;
      }
      it.status = status;
      it.isActive = (status == 'Active');
      it.updatedAt = DateTime.now();

      try {
        final Uri firestoreUri = Uri.parse(
          'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/fitness_cms/$itemId?key=$firebaseApiKey',
        );

        await http.patch(
          firestoreUri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'fields': it.toFirestoreFields()}),
        );

        
      } catch (e) {
        debugPrint('Update fitness cms error: $e');
      }
    }
  }

  /// Delete Fitness CMS item
  Future<void> deleteCmsItem(String itemId) async {
    _items.removeWhere((i) => i.itemId == itemId || i.id == itemId);

    try {
      final Uri firestoreUri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/fitness_cms/$itemId?key=$firebaseApiKey',
      );
      await http.delete(firestoreUri);
      
    } catch (e) {
      debugPrint('Delete fitness cms error: $e');
    }
  }
}
