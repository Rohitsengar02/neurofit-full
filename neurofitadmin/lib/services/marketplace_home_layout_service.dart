import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';

class LayoutSectionModel {
  String id;
  String sectionId;
  String title;
  String subtitle;
  bool showTitle;
  String type; // 'products', 'banners', 'categories', 'subcategories', 'custom_promo'
  String layoutMode; // 'carousel', 'grid', 'banner_strip', 'hero_carousel', 'two_column'
  String filterSource; // 'all', 'featured', 'trending', 'category', 'subcategory', 'selected_ids', 'custom'
  String filterId; // categoryId or subcategoryId if filtered
  String filterName; // category or subcategory name
  List<String> selectedItemIds; // specific banner or product IDs
  int itemLimit;
  int sortOrder;
  bool isActive;
  String customBannerImageUrl;
  String customBannerTargetType;
  String customBannerTargetId;
  String customBannerButtonText;
  String customBannerBadge;
  DateTime? createdAt;
  DateTime? updatedAt;

  LayoutSectionModel({
    required this.id,
    String? sectionId,
    required this.title,
    this.subtitle = '',
    this.showTitle = true,
    required this.type,
    this.layoutMode = 'carousel',
    this.filterSource = 'all',
    this.filterId = '',
    this.filterName = '',
    List<String>? selectedItemIds,
    this.itemLimit = 10,
    this.sortOrder = 1,
    this.isActive = true,
    this.customBannerImageUrl = '',
    this.customBannerTargetType = 'category',
    this.customBannerTargetId = '',
    this.customBannerButtonText = 'Shop Now',
    this.customBannerBadge = '',
    this.createdAt,
    this.updatedAt,
  })  : sectionId = sectionId ?? id,
        selectedItemIds = selectedItemIds ?? [];

  factory LayoutSectionModel.fromJson(Map<String, dynamic> json) {
    final secId = json['id'] ?? json['sectionId'] ?? json['_id'] ?? 'sec_${DateTime.now().millisecondsSinceEpoch}';

    List<String> ids = [];
    if (json['selectedItemIds'] != null && json['selectedItemIds'] is List) {
      ids = (json['selectedItemIds'] as List).map((e) => e.toString()).toList();
    }

    return LayoutSectionModel(
      id: secId,
      sectionId: json['sectionId'] ?? secId,
      title: json['title'] ?? 'Section',
      subtitle: json['subtitle'] ?? '',
      showTitle: json['showTitle'] ?? json['showHeading'] ?? true,
      type: json['type'] ?? 'products',
      layoutMode: json['layoutMode'] ?? 'carousel',
      filterSource: json['filterSource'] ?? 'all',
      filterId: json['filterId'] ?? '',
      filterName: json['filterName'] ?? '',
      selectedItemIds: ids,
      itemLimit: (json['itemLimit'] as num?)?.toInt() ?? 10,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? (json['displayOrder'] as num?)?.toInt() ?? 1,
      isActive: json['isActive'] ?? true,
      customBannerImageUrl: json['customBannerImageUrl'] ?? '',
      customBannerTargetType: json['customBannerTargetType'] ?? 'category',
      customBannerTargetId: json['customBannerTargetId'] ?? '',
      customBannerButtonText: json['customBannerButtonText'] ?? 'Shop Now',
      customBannerBadge: json['customBannerBadge'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sectionId': sectionId,
      'title': title,
      'subtitle': subtitle,
      'showTitle': showTitle,
      'showHeading': showTitle,
      'type': type,
      'layoutMode': layoutMode,
      'filterSource': filterSource,
      'filterId': filterId,
      'filterName': filterName,
      'selectedItemIds': selectedItemIds,
      'itemLimit': itemLimit,
      'sortOrder': sortOrder,
      'displayOrder': sortOrder,
      'isActive': isActive,
      'customBannerImageUrl': customBannerImageUrl,
      'customBannerTargetType': customBannerTargetType,
      'customBannerTargetId': customBannerTargetId,
      'customBannerButtonText': customBannerButtonText,
      'customBannerBadge': customBannerBadge,
    };
  }

  Map<String, dynamic> toFirestoreFields() {
    return {
      'id': {'stringValue': id},
      'title': {'stringValue': title},
      'subtitle': {'stringValue': subtitle},
      'showTitle': {'booleanValue': showTitle},
      'type': {'stringValue': type},
      'layoutMode': {'stringValue': layoutMode},
      'filterSource': {'stringValue': filterSource},
      'filterId': {'stringValue': filterId},
      'filterName': {'stringValue': filterName},
      'selectedItemIds': {
        'arrayValue': {
          'values': selectedItemIds.map((item) => {'stringValue': item}).toList()
        }
      },
      'itemLimit': {'integerValue': itemLimit.toString()},
      'sortOrder': {'integerValue': sortOrder.toString()},
      'isActive': {'booleanValue': isActive},
      'customBannerImageUrl': {'stringValue': customBannerImageUrl},
      'createdAt': {'timestampValue': (createdAt ?? DateTime.now()).toUtc().toIso8601String()},
      'updatedAt': {'timestampValue': (updatedAt ?? DateTime.now()).toUtc().toIso8601String()},
    };
  }

  factory LayoutSectionModel.fromFirestoreDoc(Map<String, dynamic> doc) {
    final String fullPath = doc['name'] ?? '';
    final String docId = fullPath.split('/').last;
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};

    final String secId = fields['id']?['stringValue'] ?? docId;
    final String title = fields['title']?['stringValue'] ?? 'Section';
    final String subtitle = fields['subtitle']?['stringValue'] ?? '';
    final bool showTitle = fields['showTitle']?['booleanValue'] ?? (fields['showHeading']?['booleanValue'] ?? true);
    final String type = fields['type']?['stringValue'] ?? 'products';
    final String layoutMode = fields['layoutMode']?['stringValue'] ?? 'carousel';
    final String filterSource = fields['filterSource']?['stringValue'] ?? 'all';
    final String filterId = fields['filterId']?['stringValue'] ?? '';
    final String filterName = fields['filterName']?['stringValue'] ?? '';

    final selectedIds = (fields['selectedItemIds']?['arrayValue']?['values'] as List<dynamic>?)
            ?.map((v) => v['stringValue']?.toString() ?? '')
            .where((v) => v.isNotEmpty)
            .toList() ??
        [];

    final int itemLimit = int.tryParse(fields['itemLimit']?['integerValue']?.toString() ?? '10') ?? 10;
    final int sortOrder = int.tryParse(fields['sortOrder']?['integerValue']?.toString() ?? '1') ?? 1;
    final bool isActive = fields['isActive']?['booleanValue'] ?? true;
    final String customBannerImageUrl = fields['customBannerImageUrl']?['stringValue'] ?? '';

    final DateTime createdAt = fields['createdAt']?['timestampValue'] != null
        ? DateTime.tryParse(fields['createdAt']['timestampValue']) ?? DateTime.now()
        : DateTime.now();
    final DateTime updatedAt = fields['updatedAt']?['timestampValue'] != null
        ? DateTime.tryParse(fields['updatedAt']['timestampValue']) ?? DateTime.now()
        : DateTime.now();

    return LayoutSectionModel(
      id: secId,
      title: title,
      subtitle: subtitle,
      showTitle: showTitle,
      type: type,
      layoutMode: layoutMode,
      filterSource: filterSource,
      filterId: filterId,
      filterName: filterName,
      selectedItemIds: selectedIds,
      itemLimit: itemLimit,
      sortOrder: sortOrder,
      isActive: isActive,
      customBannerImageUrl: customBannerImageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class MarketplaceHomeLayoutService extends ChangeNotifier {
  static final MarketplaceHomeLayoutService _instance = MarketplaceHomeLayoutService._internal();
  factory MarketplaceHomeLayoutService() => _instance;

  IO.Socket? _socket;

  MarketplaceHomeLayoutService._internal() {
    fetchLayoutSectionsFromFirestore();
    _initSocket();
  }

  static const String firebaseProjectId = 'neurofit-52fe0';
  static const String firebaseApiKey = 'AIzaSyDcGovQH3Sd_0kdNeSISK6eNCdtjA_g9vg';
  static const String firestoreBase = "https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents";

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final List<LayoutSectionModel> _sections = [];
  List<LayoutSectionModel> get sections => List.unmodifiable(_sections);
  List<LayoutSectionModel> get activeSections => _sections.where((s) => s.isActive).toList();

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

      _socket?.onConnect((_) {
        debugPrint('🔌 [ADMIN SOCKET] Connected to Layout Sections real-time updates');
      });

      _socket?.on('layout_section_created', (data) {
        debugPrint('📡 [ADMIN SOCKET] layout_section_created: $data');
        if (data is Map<String, dynamic>) {
          final newSec = LayoutSectionModel.fromJson(data);
          _sections.removeWhere((s) => s.id == newSec.id || s.sectionId == newSec.sectionId);
          _sections.add(newSec);
          _sections.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          notifyListeners();
        }
      });

      _socket?.on('layout_section_updated', (data) {
        debugPrint('📡 [ADMIN SOCKET] layout_section_updated: $data');
        if (data is Map<String, dynamic>) {
          final updated = LayoutSectionModel.fromJson(data);
          final index = _sections.indexWhere((s) => s.id == updated.id || s.sectionId == updated.sectionId);
          if (index != -1) {
            _sections[index] = updated;
          } else {
            _sections.add(updated);
          }
          _sections.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          notifyListeners();
        }
      });

      _socket?.on('layout_section_deleted', (data) {
        debugPrint('📡 [ADMIN SOCKET] layout_section_deleted: $data');
        final delId = (data is Map) ? (data['id'] ?? data['sectionId']) : data.toString();
        _sections.removeWhere((s) => s.id == delId || s.sectionId == delId);
        notifyListeners();
      });

      _socket?.on('layout_sections_updated', (data) {
        if (data is List) {
          final List<LayoutSectionModel> list = [];
          for (var item in data) {
            if (item is Map<String, dynamic>) list.add(LayoutSectionModel.fromJson(item));
          }
          list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          _sections.clear();
          _sections.addAll(list);
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('⚠️ [ADMIN SOCKET] Layout sections socket error: $e');
    }
  }

  Future<void> fetchLayoutSectionsFromFirestore() async {
    _isLoading = true;
    notifyListeners();

    // 1. Fetch from MongoDB Atlas Backend REST API
    final backendUrls = [
      '${ApiConstants.apiBaseUrl}/layout',
      ...ApiConstants.candidateBaseUrls.map((b) => '$b/api/layout'),
    ];

    for (final url in backendUrls) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final items = data['data'] as List<dynamic>? ?? [];
          if (items.isNotEmpty) {
            final List<LayoutSectionModel> fetched = [];
            for (var item in items) {
              fetched.add(LayoutSectionModel.fromJson(item as Map<String, dynamic>));
            }
            fetched.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
            _sections.clear();
            _sections.addAll(fetched);
            _isLoading = false;
            notifyListeners();
            debugPrint('✅ [HOME LAYOUT LOADED FROM MONGODB ATLAS] ${_sections.length} layout sections');
            return;
          }
        }
      } catch (_) {}
    }

    // 2. Fallback to Firestore
    try {
      final Uri uri = Uri.parse('$firestoreBase/marketplace_home_layout?key=$firebaseApiKey&pageSize=100');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final documents = data['documents'] as List<dynamic>? ?? [];

        final List<LayoutSectionModel> fetched = [];
        for (var doc in documents) {
          fetched.add(LayoutSectionModel.fromFirestoreDoc(doc));
        }

        fetched.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        _sections.clear();
        _sections.addAll(fetched);
      }
    } catch (e) {
      debugPrint('Error loading home layout sections: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveSection(LayoutSectionModel section) async {
    _isLoading = true;
    notifyListeners();

    try {
      final backendUrls = [
        '${ApiConstants.apiBaseUrl}/layout/${section.id}',
        ...ApiConstants.candidateBaseUrls.map((b) => '$b/api/layout/${section.id}'),
      ];

      for (final url in backendUrls) {
        try {
          final res = await http.put(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(section.toJson()),
          ).timeout(const Duration(seconds: 4));

          if (res.statusCode == 200 || res.statusCode == 201) {
            await fetchLayoutSectionsFromFirestore();
            return true;
          }
        } catch (_) {}
      }

      return false;
    } catch (e) {
      debugPrint('Error saving layout section: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleSectionStatus(String sectionId, bool isActive) async {
    try {
      final backendUrls = [
        '${ApiConstants.apiBaseUrl}/layout/$sectionId/status',
        ...ApiConstants.candidateBaseUrls.map((b) => '$b/api/layout/$sectionId/status'),
      ];

      for (final url in backendUrls) {
        try {
          final res = await http.patch(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'isActive': isActive}),
          ).timeout(const Duration(seconds: 3));

          if (res.statusCode == 200) {
            await fetchLayoutSectionsFromFirestore();
            return true;
          }
        } catch (_) {}
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteSection(String sectionId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final backendUrls = [
        '${ApiConstants.apiBaseUrl}/layout/$sectionId',
        ...ApiConstants.candidateBaseUrls.map((b) => '$b/api/layout/$sectionId'),
      ];

      for (final url in backendUrls) {
        try {
          final res = await http.delete(Uri.parse(url)).timeout(const Duration(seconds: 3));
          if (res.statusCode == 200) {
            _sections.removeWhere((s) => s.id == sectionId || s.sectionId == sectionId);
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

  Future<void> reorderSections(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _sections.removeAt(oldIndex);
    _sections.insert(newIndex, item);

    final List<Map<String, dynamic>> orders = [];
    for (int i = 0; i < _sections.length; i++) {
      _sections[i].sortOrder = i + 1;
      orders.add({'id': _sections[i].id, 'sortOrder': i + 1});
    }
    notifyListeners();

    try {
      final backendUrls = [
        '${ApiConstants.apiBaseUrl}/layout/reorder',
        ...ApiConstants.candidateBaseUrls.map((b) => '$b/api/layout/reorder'),
      ];

      for (final url in backendUrls) {
        try {
          await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'sectionOrders': orders}),
          ).timeout(const Duration(seconds: 3));
          break;
        } catch (_) {}
      }
    } catch (_) {}
  }
}
