import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:neurofitadmin/constants/api_constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'category_backend_service.dart';

class BannerModel {
  final String bannerId;
  final String id;
  String title;
  String subtitle;
  String imageUrl;
  String imageKey;
  String mediaType; // 'image', 'gif', 'video'
  bool showTitle;
  bool showHeading;
  String targetType; // 'category', 'product', 'offer', 'brand'
  String targetId;
  String targetName;
  String buttonText;
  String badge;
  int sortOrder;
  String status;
  bool isActive;
  String discountCode;
  final DateTime createdAt;
  DateTime updatedAt;

  BannerModel({
    required this.bannerId,
    String? id,
    required this.title,
    this.subtitle = '',
    required this.imageUrl,
    String? imageKey,
    this.mediaType = 'image',
    this.showTitle = true,
    this.showHeading = true,
    this.targetType = 'category',
    this.targetId = '',
    this.targetName = '',
    this.buttonText = 'Shop Now',
    this.badge = 'FEATURED',
    this.sortOrder = 1,
    this.status = 'Active',
    this.isActive = true,
    this.discountCode = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? bannerId,
        imageKey = imageKey ?? (imageUrl.contains('r2.dev/') ? imageUrl.split('r2.dev/').last : imageUrl),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    final bId = json['bannerId'] ?? json['id'] ?? json['_id'] ?? '';
    final statusStr = json['status'] ?? 'Active';
    final bool active = json['isActive'] ?? (statusStr.toString().toLowerCase() == 'active');
    final img = json['imageUrl'] ?? '';
    final lower = img.toString().toLowerCase();

    String mType = json['mediaType'] ?? '';
    if (mType.isEmpty) {
      if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm')) {
        mType = 'video';
      } else if (lower.endsWith('.gif')) {
        mType = 'gif';
      } else {
        mType = 'image';
      }
    }

    return BannerModel(
      bannerId: bId,
      id: bId,
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: img,
      imageKey: json['imageKey'] ?? '',
      mediaType: mType,
      showTitle: json['showTitle'] ?? true,
      showHeading: json['showHeading'] ?? json['showTitle'] ?? true,
      targetType: json['targetType'] ?? 'category',
      targetId: json['targetId'] ?? '',
      targetName: json['targetName'] ?? '',
      buttonText: json['buttonText'] ?? 'Shop Now',
      badge: json['badge'] ?? json['badgeText'] ?? 'FEATURED',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? (json['displayOrder'] as num?)?.toInt() ?? 1,
      status: statusStr,
      isActive: active,
      discountCode: json['discountCode'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bannerId': bannerId,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'imageKey': imageKey,
      'mediaType': mediaType,
      'showTitle': showTitle,
      'showHeading': showHeading,
      'targetType': targetType,
      'targetId': targetId,
      'targetName': targetName,
      'buttonText': buttonText,
      'badge': badge,
      'sortOrder': sortOrder,
      'status': status,
      'isActive': isActive,
      'discountCode': discountCode,
    };
  }

  Map<String, dynamic> toFirestoreFields() {
    return {
      'bannerId': {'stringValue': bannerId},
      'title': {'stringValue': title},
      'subtitle': {'stringValue': subtitle},
      'imageUrl': {'stringValue': imageUrl},
      'imageKey': {'stringValue': imageKey},
      'targetType': {'stringValue': targetType},
      'targetId': {'stringValue': targetId},
      'targetName': {'stringValue': targetName},
      'buttonText': {'stringValue': buttonText},
      'badge': {'stringValue': badge},
      'sortOrder': {'integerValue': sortOrder.toString()},
      'status': {'stringValue': status},
      'isActive': {'booleanValue': isActive},
      'discountCode': {'stringValue': discountCode},
      'createdAt': {'timestampValue': createdAt.toUtc().toIso8601String()},
      'updatedAt': {'timestampValue': updatedAt.toUtc().toIso8601String()},
    };
  }

  factory BannerModel.fromFirestoreDoc(Map<String, dynamic> doc) {
    final String fullPath = doc['name'] ?? '';
    final String docId = fullPath.split('/').last;
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};

    final String bId = fields['bannerId']?['stringValue'] ?? fields['id']?['stringValue'] ?? docId;
    final String title = fields['title']?['stringValue'] ?? 'Special Offer';
    final String subtitle = fields['subtitle']?['stringValue'] ?? '';
    final String imageUrl = fields['imageUrl']?['stringValue'] ?? '';
    final String imageKey = fields['imageKey']?['stringValue'] ?? '';
    final String targetType = fields['targetType']?['stringValue'] ?? 'category';
    final String targetId = fields['targetId']?['stringValue'] ?? '';
    final String targetName = fields['targetName']?['stringValue'] ?? '';
    final String buttonText = fields['buttonText']?['stringValue'] ?? 'Shop Now';
    final String badge = fields['badge']?['stringValue'] ?? 'FEATURED';
    final int sortOrder = int.tryParse(fields['sortOrder']?['integerValue']?.toString() ?? '1') ?? 1;
    final String status = fields['status']?['stringValue'] ?? 'Active';
    final bool isActive = fields['isActive']?['booleanValue'] ?? (status == 'Active');
    final String discountCode = fields['discountCode']?['stringValue'] ?? '';

    final DateTime createdAt = fields['createdAt']?['timestampValue'] != null ? DateTime.tryParse(fields['createdAt']['timestampValue']) ?? DateTime.now() : DateTime.now();
    final DateTime updatedAt = fields['updatedAt']?['timestampValue'] != null ? DateTime.tryParse(fields['updatedAt']['timestampValue']) ?? DateTime.now() : DateTime.now();

    return BannerModel(
      bannerId: bId,
      id: docId,
      title: title,
      subtitle: subtitle,
      imageUrl: imageUrl,
      imageKey: imageKey,
      targetType: targetType,
      targetId: targetId,
      targetName: targetName,
      buttonText: buttonText,
      badge: badge,
      sortOrder: sortOrder,
      status: status,
      isActive: isActive,
      discountCode: discountCode,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class BannersBackendService extends ChangeNotifier {
  static final BannersBackendService _instance = BannersBackendService._internal();
  factory BannersBackendService() => _instance;

  IO.Socket? _socket;

  BannersBackendService._internal() {
    fetchBannersFromFirestore();
    _initSocket();
  }

  static const String firebaseProjectId = 'neurofit-52fe0';
  static const String firebaseApiKey = 'AIzaSyDcGovQH3Sd_0kdNeSISK6eNCdtjA_g9vg';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final List<BannerModel> _banners = [];
  List<BannerModel> get banners => List.unmodifiable(_banners);

  void _initSocket() {
    try {
      final socketUri = ApiConstants.socketUrl;
      _socket = IO.io(
        socketUri,
        IO.OptionBuilder().setTransports(['websocket', 'polling']).disableAutoConnect().build(),
      );

      _socket?.connect();

      _socket?.onConnect((_) {
        debugPrint('🔌 [ADMIN SOCKET] Connected to real-time banner updates server');
        _socket?.emit('join_admin_room');
      });

      _socket?.on('banner_created', (data) {
        debugPrint('📡 [ADMIN SOCKET] banner_created event: $data');
        if (data is Map<String, dynamic>) {
          final newBanner = BannerModel.fromJson(data);
          _banners.removeWhere((b) => b.bannerId == newBanner.bannerId || b.id == newBanner.id);
          _banners.add(newBanner);
          _banners.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          notifyListeners();
        }
      });

      _socket?.on('banner_updated', (data) {
        debugPrint('📡 [ADMIN SOCKET] banner_updated event: $data');
        if (data is Map<String, dynamic>) {
          final updated = BannerModel.fromJson(data);
          final index = _banners.indexWhere((b) => b.bannerId == updated.bannerId || b.id == updated.id);
          if (index != -1) {
            _banners[index] = updated;
          } else {
            _banners.add(updated);
          }
          _banners.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          notifyListeners();
        }
      });

      _socket?.on('banner_deleted', (data) {
        debugPrint('📡 [ADMIN SOCKET] banner_deleted event: $data');
        final delId = (data is Map) ? (data['id'] ?? data['bannerId']) : data.toString();
        _banners.removeWhere((b) => b.bannerId == delId || b.id == delId);
        notifyListeners();
      });

      _socket?.on('banners_updated', (data) {
        if (data is List) {
          final List<BannerModel> list = [];
          for (var item in data) {
            if (item is Map<String, dynamic>) list.add(BannerModel.fromJson(item));
          }
          list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          _banners.clear();
          _banners.addAll(list);
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('⚠️ [ADMIN SOCKET] Connection error: $e');
    }
  }

  Future<void> fetchBannersFromFirestore() async {
    _isLoading = true;
    notifyListeners();

    // 1. Fetch from MongoDB Atlas Backend REST API
    final backendUrls = [
      '${ApiConstants.apiBaseUrl}/banners',
      ...ApiConstants.candidateBaseUrls.map((b) => '$b/api/banners'),
    ];

    for (final url in backendUrls) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final items = data['data'] as List<dynamic>? ?? [];
          if (items.isNotEmpty) {
            final List<BannerModel> fetched = [];
            for (var item in items) {
              fetched.add(BannerModel.fromJson(item as Map<String, dynamic>));
            }
            fetched.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
            _banners.clear();
            _banners.addAll(fetched);
            _isLoading = false;
            notifyListeners();
            debugPrint('✅ [BANNERS LOADED FROM MONGODB ATLAS] ${_banners.length} live banners');
            return;
          }
        }
      } catch (_) {}
    }

    // 2. Fallback to Firestore
    try {
      final Uri uri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/banners?key=$firebaseApiKey&pageSize=100',
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final documents = data['documents'] as List<dynamic>?;
        if (documents != null) {
          final List<BannerModel> fetched = [];
          for (var doc in documents) {
            fetched.add(BannerModel.fromFirestoreDoc(doc));
          }
          fetched.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          _banners.clear();
          _banners.addAll(fetched);
        }
      }
    } catch (e) {
      debugPrint('Error fetching banners from Firestore: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBanner({
    required String title,
    required String subtitle,
    required String targetType,
    required String targetId,
    required String targetName,
    required String buttonText,
    String badge = 'FEATURED',
    String discountCode = '',
    required String imageFileName,
    required Uint8List imageBytes,
    int sortOrder = 1,
    String mediaType = 'image',
    bool showTitle = true,
    bool showHeading = true,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uploadedUrl = await CategoryBackendService().uploadRawImageToR2(
        fileName: imageFileName,
        imageBytes: imageBytes,
      );

      if (uploadedUrl == null) return false;

      return createBannerWithUrl(
        title: title,
        subtitle: subtitle,
        targetType: targetType,
        targetId: targetId,
        targetName: targetName,
        buttonText: buttonText,
        badge: badge,
        discountCode: discountCode,
        imageUrl: uploadedUrl,
        sortOrder: sortOrder,
        mediaType: mediaType,
        showTitle: showTitle,
        showHeading: showHeading,
      );
    } catch (e) {
      debugPrint('Error creating banner: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBannerWithUrl({
    required String title,
    required String subtitle,
    required String targetType,
    required String targetId,
    required String targetName,
    required String buttonText,
    String badge = 'FEATURED',
    String discountCode = '',
    required String imageUrl,
    int sortOrder = 1,
    String mediaType = 'image',
    bool showTitle = true,
    bool showHeading = true,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final String bannerId = 'banner_${DateTime.now().millisecondsSinceEpoch}';

      final lower = imageUrl.toLowerCase();
      final finalMediaType = mediaType.isNotEmpty
          ? mediaType
          : (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm')
              ? 'video'
              : (lower.endsWith('.gif') ? 'gif' : 'image'));

      final backendUrls = [
        '${ApiConstants.apiBaseUrl}/banners',
        ...ApiConstants.candidateBaseUrls.map((b) => '$b/api/banners'),
      ];

      for (final url in backendUrls) {
        try {
          final res = await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id': bannerId,
              'bannerId': bannerId,
              'title': title,
              'subtitle': subtitle,
              'imageUrl': imageUrl,
              'mediaType': finalMediaType,
              'showTitle': showTitle,
              'showHeading': showHeading,
              'targetType': targetType,
              'targetId': targetId,
              'targetName': targetName,
              'buttonText': buttonText,
              'badge': badge,
              'discountCode': discountCode,
              'sortOrder': sortOrder,
              'status': 'Active',
            }),
          ).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200 || res.statusCode == 201) {
            await fetchBannersFromFirestore();
            return true;
          }
        } catch (_) {}
      }

      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateBanner({
    required String bannerId,
    required String title,
    required String subtitle,
    required String targetType,
    required String targetId,
    required String targetName,
    required String buttonText,
    String badge = 'FEATURED',
    String discountCode = '',
    String status = 'Active',
    String? newImageUrl,
    Uint8List? newImageBytes,
    String? newImageFileName,
    int? sortOrder,
    String? mediaType,
    bool? showTitle,
    bool? showHeading,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final existing = _banners.firstWhere(
        (b) => b.bannerId == bannerId,
        orElse: () => BannerModel(bannerId: bannerId, title: title, imageUrl: ''),
      );

      String finalImageUrl = (newImageUrl != null && newImageUrl.isNotEmpty) ? newImageUrl : existing.imageUrl;
      if (newImageBytes != null && newImageFileName != null) {
        final uploadedUrl = await CategoryBackendService().uploadRawImageToR2(
          fileName: newImageFileName,
          imageBytes: newImageBytes,
        );
        if (uploadedUrl != null) finalImageUrl = uploadedUrl;
      }

      final lower = finalImageUrl.toLowerCase();
      final finalMediaType = mediaType ??
          (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm')
              ? 'video'
              : (lower.endsWith('.gif') ? 'gif' : existing.mediaType));

      final backendUrls = [
        '${ApiConstants.apiBaseUrl}/banners/$bannerId',
        ...ApiConstants.candidateBaseUrls.map((b) => '$b/api/banners/$bannerId'),
      ];

      for (final url in backendUrls) {
        try {
          final res = await http.put(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id': bannerId,
              'bannerId': bannerId,
              'title': title,
              'subtitle': subtitle,
              'imageUrl': finalImageUrl,
              'mediaType': finalMediaType,
              'showTitle': showTitle ?? existing.showTitle,
              'showHeading': showHeading ?? existing.showHeading,
              'targetType': targetType,
              'targetId': targetId,
              'targetName': targetName,
              'buttonText': buttonText,
              'badge': badge,
              'discountCode': discountCode,
              'sortOrder': sortOrder ?? existing.sortOrder,
              'status': status,
            }),
          ).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200) {
            await fetchBannersFromFirestore();
            return true;
          }
        } catch (_) {}
      }

      return false;
    } catch (e) {
      debugPrint('Error updating banner: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteBanner(String bannerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final backendUrls = [
        '${ApiConstants.apiBaseUrl}/banners/$bannerId',
        ...ApiConstants.candidateBaseUrls.map((b) => '$b/api/banners/$bannerId'),
      ];

      for (final url in backendUrls) {
        try {
          final res = await http.delete(Uri.parse(url)).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200) {
            _banners.removeWhere((b) => b.bannerId == bannerId || b.id == bannerId);
            notifyListeners();
            return true;
          }
        } catch (_) {}
      }

      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reorderBanners(List<Map<String, dynamic>> bannerOrders) async {
    try {
      final backendUrls = [
        '${ApiConstants.apiBaseUrl}/banners/reorder',
        ...ApiConstants.candidateBaseUrls.map((b) => '$b/api/banners/reorder'),
      ];

      for (final url in backendUrls) {
        try {
          final res = await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'bannerOrders': bannerOrders}),
          ).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200) {
            await fetchBannersFromFirestore();
            return true;
          }
        } catch (_) {}
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
